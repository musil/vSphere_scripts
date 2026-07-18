// Command sso-users lists vCenter SSO users and their password expiry by
// querying the VMware Directory Service (vmdir) over LDAPS, without any
// dependency on PowerCLI / the SsoAdmin module.
//
// It mirrors what "dir-cli user find-by-name --level 2" reports, computing
// expiry from the vmdir attributes:
//   - pwdLastSet              (per user, seconds since Unix epoch)
//   - vmwPasswordNeverExpires (per user, TRUE/FALSE)
//   - vmwPasswordLifetimeDays (domain "password and lockout policy")
//
// Bind as an SSO admin, e.g. administrator@vsphere.local.
package main

import (
	"crypto/tls"
	_ "embed"
	"encoding/csv"
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"strconv"
	"strings"
	"text/tabwriter"
	"time"

	"github.com/go-ldap/ldap/v3"
	"golang.org/x/term"
)

// vmdir userAccountControl flags (see vmdir.h).
const (
	uacDisabled = 0x00000002
	uacLockout  = 0x00000010
)

const appName = "sso-users"

//go:embed VERSION
var versionFile string

type userRecord struct {
	User                 string     `json:"user"`
	UPN                  string     `json:"upn"`
	Disabled             bool       `json:"disabled"`
	Locked               bool       `json:"locked"`
	PasswordNeverExpires bool       `json:"passwordNeverExpires"`
	PasswordLastSet      *time.Time `json:"passwordLastSet,omitempty"`
	PasswordExpiry       *time.Time `json:"passwordExpiry,omitempty"`
	RemainingDays        *int64     `json:"remainingDays,omitempty"`
	Expired              bool       `json:"expired"`
}

func main() {
	var (
		server   = flag.String("server", "", "vCenter/PSC host running vmdir (required)")
		port     = flag.Int("port", 636, "LDAPS port")
		domain   = flag.String("domain", "vsphere.local", "SSO domain name")
		bindUser = flag.String("user", "administrator@vsphere.local", "SSO admin bind user (UPN)")
		password = flag.String("password", "", "bind password (prefer env SSO_BIND_PASSWORD or interactive prompt)")
		insecure = flag.Bool("insecure", false, "skip TLS certificate verification (self-signed vCenter certs)")
		csvPath  = flag.String("csv", "", "optional path to export results as CSV")
		asJSON   = flag.Bool("json", false, "output JSON instead of a table")
		version  = flag.Bool("version", false, "print version and exit")
	)
	flag.Parse()

	if *version {
		fmt.Printf("%s %s\n", appName, appVersion())
		return
	}

	if *server == "" {
		fmt.Fprintln(os.Stderr, "error: -server is required")
		flag.Usage()
		os.Exit(2)
	}

	pw, err := resolvePassword(*password)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
		os.Exit(1)
	}

	baseDN := domainToDN(*domain)

	conn, err := dial(*server, *port, *insecure)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: connect: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	if err := bindSSO(conn, *bindUser, pw, baseDN); err != nil {
		fmt.Fprintf(os.Stderr, "error: bind as %q failed: %v\n", *bindUser, err)
		os.Exit(1)
	}

	lifetimeDays, err := readPasswordLifetimeDays(conn, baseDN)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: read password policy: %v\n", err)
		os.Exit(1)
	}

	records, err := readUsers(conn, baseDN, lifetimeDays)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: read users: %v\n", err)
		os.Exit(1)
	}

	if *csvPath != "" {
		if err := writeCSV(*csvPath, records); err != nil {
			fmt.Fprintf(os.Stderr, "error: write csv: %v\n", err)
			os.Exit(1)
		}
		fmt.Fprintf(os.Stderr, "exported %d user(s) to %s\n", len(records), *csvPath)
	}

	if *asJSON {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "  ")
		if err := enc.Encode(records); err != nil {
			fmt.Fprintf(os.Stderr, "error: encode json: %v\n", err)
			os.Exit(1)
		}
		return
	}

	printTable(records)
}

func appVersion() string {
	version := strings.TrimSpace(versionFile)
	if version == "" {
		return "unknown"
	}
	return version
}

// resolvePassword returns the bind password from the flag, the
// SSO_BIND_PASSWORD environment variable, or an interactive no-echo prompt.
func resolvePassword(flagValue string) (string, error) {
	if flagValue != "" {
		return flagValue, nil
	}
	if env := os.Getenv("SSO_BIND_PASSWORD"); env != "" {
		return env, nil
	}
	if !term.IsTerminal(int(os.Stdin.Fd())) {
		return "", fmt.Errorf("no password provided (set -password, SSO_BIND_PASSWORD, or run interactively)")
	}
	fmt.Fprint(os.Stderr, "Bind password: ")
	b, err := term.ReadPassword(int(os.Stdin.Fd()))
	fmt.Fprintln(os.Stderr)
	if err != nil {
		return "", fmt.Errorf("read password: %w", err)
	}
	return string(b), nil
}

func dial(host string, port int, insecure bool) (*ldap.Conn, error) {
	url := fmt.Sprintf("ldaps://%s:%d", host, port)
	return ldap.DialURL(url, ldap.DialWithTLSConfig(&tls.Config{
		InsecureSkipVerify: insecure,
		ServerName:         host,
	}))
}

// bindSSO performs a simple bind. vmdir simple bind expects a full DN rather
// than a UPN, so when a UPN like "administrator@vsphere.local" fails with an
// invalid-credentials result, retry with the derived DN
// "cn=<local>,cn=users,<baseDN>" (cn matching is case-insensitive).
func bindSSO(conn *ldap.Conn, bindUser, password, baseDN string) error {
	err := conn.Bind(bindUser, password)
	if err == nil {
		return nil
	}

	local, isUPN := "", false
	if i := strings.Index(bindUser, "@"); i > 0 {
		local, isUPN = bindUser[:i], true
	}
	if !isUPN || !ldap.IsErrorWithCode(err, ldap.LDAPResultInvalidCredentials) {
		return err
	}

	bindDN := fmt.Sprintf("cn=%s,cn=users,%s", local, baseDN)
	if dnErr := conn.Bind(bindDN, password); dnErr != nil {
		// Surface the original UPN error for context.
		return fmt.Errorf("UPN bind failed (%v); DN bind as %q also failed: %w", err, bindDN, dnErr)
	}
	return nil
}

// domainToDN converts "vsphere.local" into "dc=vsphere,dc=local".
func domainToDN(domain string) string {
	parts := strings.Split(domain, ".")
	for i, p := range parts {
		parts[i] = "dc=" + p
	}
	return strings.Join(parts, ",")
}

// readPasswordLifetimeDays reads vmwPasswordLifetimeDays from the domain
// "password and lockout policy" entry. 0 (or missing) means passwords never
// expire domain-wide.
func readPasswordLifetimeDays(conn *ldap.Conn, baseDN string) (int64, error) {
	policyDN := "cn=password and lockout policy," + baseDN
	req := ldap.NewSearchRequest(
		policyDN,
		ldap.ScopeBaseObject, ldap.NeverDerefAliases, 0, 0, false,
		"(objectClass=*)",
		[]string{"vmwPasswordLifetimeDays"},
		nil,
	)
	res, err := conn.Search(req)
	if err != nil {
		// Missing policy entry -> treat as "never expires".
		if lerr, ok := err.(*ldap.Error); ok && lerr.ResultCode == ldap.LDAPResultNoSuchObject {
			return 0, nil
		}
		return 0, err
	}
	if len(res.Entries) == 0 {
		return 0, nil
	}
	v := res.Entries[0].GetAttributeValue("vmwPasswordLifetimeDays")
	if v == "" {
		return 0, nil
	}
	days, err := strconv.ParseInt(v, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("parse vmwPasswordLifetimeDays %q: %w", v, err)
	}
	return days, nil
}

// readUsers enumerates person users under cn=users and computes expiry.
func readUsers(conn *ldap.Conn, baseDN string, lifetimeDays int64) ([]userRecord, error) {
	usersDN := "cn=users," + baseDN
	req := ldap.NewSearchRequest(
		usersDN,
		ldap.ScopeSingleLevel, ldap.NeverDerefAliases, 0, 0, false,
		"(&(objectClass=user)(!(objectClass=computer)))",
		[]string{
			"sAMAccountName", "cn", "userPrincipalName",
			"pwdLastSet", "vmwPasswordNeverExpires", "userAccountControl",
		},
		nil,
	)
	res, err := conn.SearchWithPaging(req, 500)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	lifetime := time.Duration(lifetimeDays) * 24 * time.Hour

	records := make([]userRecord, 0, len(res.Entries))
	for _, e := range res.Entries {
		name := e.GetAttributeValue("sAMAccountName")
		if name == "" {
			name = e.GetAttributeValue("cn")
		}

		rec := userRecord{
			User:                 name,
			UPN:                  e.GetAttributeValue("userPrincipalName"),
			PasswordNeverExpires: strings.EqualFold(e.GetAttributeValue("vmwPasswordNeverExpires"), "TRUE"),
		}

		if uac, err := strconv.ParseInt(e.GetAttributeValue("userAccountControl"), 10, 64); err == nil {
			rec.Disabled = uac&uacDisabled != 0
			rec.Locked = uac&uacLockout != 0
		}

		if v := e.GetAttributeValue("pwdLastSet"); v != "" {
			if sec, err := strconv.ParseInt(v, 10, 64); err == nil && sec > 0 {
				last := time.Unix(sec, 0)
				rec.PasswordLastSet = &last

				if !rec.PasswordNeverExpires && lifetimeDays > 0 {
					expiry := last.Add(lifetime)
					rec.PasswordExpiry = &expiry
					remaining := int64(expiry.Sub(now).Hours() / 24)
					rec.RemainingDays = &remaining
					rec.Expired = now.After(expiry)
				}
			}
		}

		records = append(records, rec)
	}
	return records, nil
}

func printTable(records []userRecord) {
	w := tabwriter.NewWriter(os.Stdout, 0, 2, 2, ' ', 0)
	fmt.Fprintln(w, "USER\tUPN\tDISABLED\tLOCKED\tNEVER_EXP\tPWD_LAST_SET\tPWD_EXPIRY\tDAYS_LEFT\tEXPIRED")
	for _, r := range records {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			r.User,
			dash(r.UPN),
			yesNo(r.Disabled),
			yesNo(r.Locked),
			yesNo(r.PasswordNeverExpires),
			fmtTime(r.PasswordLastSet),
			fmtTime(r.PasswordExpiry),
			fmtDays(r.RemainingDays, r.PasswordNeverExpires),
			yesNo(r.Expired),
		)
	}
	_ = w.Flush()
}

func writeCSV(path string, records []userRecord) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()

	cw := csv.NewWriter(f)
	defer cw.Flush()

	header := []string{"User", "UPN", "Disabled", "Locked", "PasswordNeverExpires",
		"PasswordLastSet", "PasswordExpiry", "RemainingDays", "Expired"}
	if err := cw.Write(header); err != nil {
		return err
	}
	for _, r := range records {
		row := []string{
			r.User,
			r.UPN,
			strconv.FormatBool(r.Disabled),
			strconv.FormatBool(r.Locked),
			strconv.FormatBool(r.PasswordNeverExpires),
			fmtTime(r.PasswordLastSet),
			fmtTime(r.PasswordExpiry),
			fmtDays(r.RemainingDays, r.PasswordNeverExpires),
			strconv.FormatBool(r.Expired),
		}
		if err := cw.Write(row); err != nil {
			return err
		}
	}
	return cw.Error()
}

func fmtTime(t *time.Time) string {
	if t == nil {
		return ""
	}
	return t.Format("2006-01-02 15:04:05")
}

func fmtDays(d *int64, neverExpires bool) string {
	if neverExpires || d == nil {
		return "never"
	}
	return strconv.FormatInt(*d, 10)
}

func yesNo(b bool) string {
	if b {
		return "yes"
	}
	return "no"
}

func dash(s string) string {
	if s == "" {
		return "-"
	}
	return s
}
