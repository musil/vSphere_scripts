package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestHealth(t *testing.T) {
	handler := newAPIHandler(Config{}, "secret", func(context.Context, Config) ([]userRecord, error) {
		t.Fatal("GetUsers must not be called for /health")
		return nil, nil
	})

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	if got := rr.Header().Get("Content-Type"); got != "application/json" {
		t.Fatalf("Content-Type = %q, want application/json", got)
	}
	if got := strings.TrimSpace(rr.Body.String()); got != `{"status":"ok"}` {
		t.Fatalf("body = %q, want health JSON", got)
	}
}

func TestUsersRequiresBearerToken(t *testing.T) {
	tests := []struct {
		name string
		auth string
	}{
		{name: "missing"},
		{name: "wrong scheme", auth: "Basic secret"},
		{name: "wrong token", auth: "Bearer wrong"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			called := false
			handler := newAPIHandler(Config{}, "secret", func(context.Context, Config) ([]userRecord, error) {
				called = true
				return nil, nil
			})

			req := httptest.NewRequest(http.MethodGet, "/api/v1/users", nil)
			if tc.auth != "" {
				req.Header.Set("Authorization", tc.auth)
			}
			rr := httptest.NewRecorder()
			handler.ServeHTTP(rr, req)

			if rr.Code != http.StatusUnauthorized {
				t.Fatalf("status = %d, want %d", rr.Code, http.StatusUnauthorized)
			}
			if called {
				t.Fatal("GetUsers was called for unauthorized request")
			}
		})
	}
}

func TestUsersReturnsSameJSONShapeAsCLI(t *testing.T) {
	lastSet := time.Date(2026, 7, 18, 10, 0, 0, 0, time.UTC)
	expiry := time.Date(2026, 8, 17, 10, 0, 0, 0, time.UTC)
	remaining := int64(30)
	records := []userRecord{
		{
			User:                 "administrator",
			UPN:                  "administrator@vsphere.local",
			Disabled:             false,
			Locked:               true,
			PasswordNeverExpires: false,
			PasswordLastSet:      &lastSet,
			PasswordExpiry:       &expiry,
			RemainingDays:        &remaining,
			Expired:              false,
		},
	}
	cfg := Config{
		Server:   "vcsa.example.local",
		Port:     636,
		Domain:   "vsphere.local",
		BindUser: "administrator@vsphere.local",
		Password: "password",
		Insecure: true,
	}

	called := false
	handler := newAPIHandler(cfg, "secret", func(ctx context.Context, got Config) ([]userRecord, error) {
		called = true
		if ctx == nil {
			t.Fatal("context is nil")
		}
		if got != cfg {
			t.Fatalf("cfg = %#v, want %#v", got, cfg)
		}
		return records, nil
	})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/users", nil)
	req.Header.Set("Authorization", "Bearer secret")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusOK)
	}
	if !called {
		t.Fatal("GetUsers was not called")
	}
	if got := rr.Header().Get("Content-Type"); got != "application/json" {
		t.Fatalf("Content-Type = %q, want application/json", got)
	}

	want, err := json.MarshalIndent(records, "", "  ")
	if err != nil {
		t.Fatalf("marshal expected records: %v", err)
	}
	want = append(want, '\n')
	if rr.Body.String() != string(want) {
		t.Fatalf("body = %q, want %q", rr.Body.String(), string(want))
	}
}

func TestUsersLDAPErrorReturnsInternalServerError(t *testing.T) {
	handler := newAPIHandler(Config{}, "secret", func(context.Context, Config) ([]userRecord, error) {
		return nil, errors.New("ldap unavailable")
	})

	req := httptest.NewRequest(http.MethodGet, "/api/v1/users", nil)
	req.Header.Set("Authorization", "Bearer secret")
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusInternalServerError)
	}
}

func TestNotFound(t *testing.T) {
	handler := newAPIHandler(Config{}, "secret", func(context.Context, Config) ([]userRecord, error) {
		t.Fatal("GetUsers must not be called for unknown path")
		return nil, nil
	})

	req := httptest.NewRequest(http.MethodGet, "/missing", nil)
	rr := httptest.NewRecorder()
	handler.ServeHTTP(rr, req)

	if rr.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", rr.Code, http.StatusNotFound)
	}
}
