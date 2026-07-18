package main

import (
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

type usersGetter func(context.Context, Config) ([]userRecord, error)

func runServe(args []string) error {
	fs := flag.NewFlagSet("serve", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)

	listen := fs.String("listen", ":8080", "HTTP listen address")
	apiKey := fs.String("apikey", "", "API key for Bearer authentication")
	server := fs.String("server", "", "vCenter/PSC host running vmdir (required)")
	port := fs.Int("port", 636, "LDAPS port")
	domain := fs.String("domain", "vsphere.local", "SSO domain name")
	bindUser := fs.String("user", "administrator@vsphere.local", "SSO admin bind user (UPN)")
	password := fs.String("password", "", "bind password (prefer env SSO_BIND_PASSWORD or interactive prompt)")
	insecure := fs.Bool("insecure", false, "skip TLS certificate verification (self-signed vCenter certs)")

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return nil
		}
		return err
	}

	if *apiKey == "" {
		return fmt.Errorf("-apikey is required")
	}
	if *server == "" {
		return fmt.Errorf("-server is required")
	}

	pw, err := resolvePassword(*password)
	if err != nil {
		return err
	}

	cfg := Config{
		Server:   *server,
		Port:     *port,
		Domain:   *domain,
		BindUser: *bindUser,
		Password: pw,
		Insecure: *insecure,
	}

	srv := &http.Server{
		Addr:    *listen,
		Handler: newAPIHandler(cfg, *apiKey, GetUsers),
	}

	log.Printf("starting server listen=%s", *listen)
	if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		return err
	}
	return nil
}

func newAPIHandler(cfg Config, apiKey string, getUsers usersGetter) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}
		if err := writeJSON(w, http.StatusOK, map[string]string{"status": "ok"}, false); err != nil {
			log.Printf("write health response failed: %v", err)
		}
	})

	mux.HandleFunc("/api/v1/users", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}
		if !authorized(r, apiKey) {
			http.Error(w, http.StatusText(http.StatusUnauthorized), http.StatusUnauthorized)
			return
		}

		records, err := getUsers(r.Context(), cfg)
		if err != nil {
			log.Printf("read users failed: %v", err)
			http.Error(w, http.StatusText(http.StatusInternalServerError), http.StatusInternalServerError)
			return
		}

		if err := writeJSON(w, http.StatusOK, records, true); err != nil {
			log.Printf("write users response failed: %v", err)
		}
	})

	return loggingMiddleware(mux)
}

func authorized(r *http.Request, apiKey string) bool {
	const prefix = "Bearer "
	auth := r.Header.Get("Authorization")
	if !strings.HasPrefix(auth, prefix) {
		return false
	}
	return strings.TrimPrefix(auth, prefix) == apiKey
}

func writeJSON(w http.ResponseWriter, status int, v any, indent bool) error {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	enc := json.NewEncoder(w)
	if indent {
		enc.SetIndent("", "  ")
	}
	return enc.Encode(v)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		log.Printf("request started method=%s path=%s remote=%s", r.Method, r.URL.Path, r.RemoteAddr)

		rec := &statusRecorder{ResponseWriter: w}
		next.ServeHTTP(rec, r)

		status := rec.status
		if status == 0 {
			status = http.StatusOK
		}
		log.Printf("request completed method=%s path=%s remote=%s status=%d duration=%s", r.Method, r.URL.Path, r.RemoteAddr, status, time.Since(start))
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(status int) {
	if r.status != 0 {
		return
	}
	r.status = status
	r.ResponseWriter.WriteHeader(status)
}

func (r *statusRecorder) Write(b []byte) (int, error) {
	if r.status == 0 {
		r.status = http.StatusOK
	}
	return r.ResponseWriter.Write(b)
}
