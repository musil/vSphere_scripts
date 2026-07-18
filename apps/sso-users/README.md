# sso-users

`sso-users` is a small Go CLI that lists vCenter SSO users and their password expiry information from VMware Directory Service (`vmdir`) over LDAPS.

It is intended for VCF 9 / vCenter SSO environments where you want the data without depending on PowerCLI or the `VMware.vSphere.SsoAdmin` PowerShell module.

## What It Reads

The tool connects to `ldaps://<vcenter>:636`, binds as an SSO administrator, and reads local SSO users from:

```text
cn=users,<domain DN>
```

Password expiry is computed from vmdir attributes:

| Attribute | Meaning |
| --- | --- |
| `pwdLastSet` | Password last-set timestamp, in seconds since Unix epoch |
| `vmwPasswordNeverExpires` | Per-user password never expires flag |
| `vmwPasswordLifetimeDays` | Domain password lifetime policy, read from `cn=password and lockout policy,<domain DN>` |
| `userAccountControl` | Account state flags used for disabled/locked status |

The expiry calculation is:

```text
PasswordExpiry = pwdLastSet + vmwPasswordLifetimeDays
```

If `vmwPasswordNeverExpires` is `TRUE`, or if `vmwPasswordLifetimeDays` is `0` or missing, the password is treated as never expiring.

## Requirements

- Go 1.22 or newer
- Network access to vCenter / PSC LDAPS port `636`
- SSO administrator credentials, for example `administrator@vsphere.local`
- Trusted vCenter certificate, or `-insecure` for internal self-signed certificates

## Build

From this directory:

```bash
go mod tidy
go build -o sso-users .
```

Or use the app-local Makefile:

```bash
make build
```

The generated binary `apps/sso-users/sso-users` is ignored by Git.

Show the application version:

```bash
./sso-users -version
```

## Usage

Prompt for the password interactively:

```bash
./sso-users -server vcsa.example.local -user administrator@vsphere.local
```

For vCenters with a self-signed or otherwise untrusted certificate:

```bash
./sso-users -server vcsa.example.local -user administrator@vsphere.local -insecure
```

Use a non-default SSO domain:

```bash
./sso-users -server vcsa.example.local -domain dc5.local -user administrator@dc5.local -insecure
```

Export CSV:

```bash
./sso-users -server vcsa.example.local -insecure -csv sso-users.csv
```

Output JSON:

```bash
./sso-users -server vcsa.example.local -insecure -json
```

## Password Handling

Password sources are evaluated in this order:

1. `-password` flag
2. `SSO_BIND_PASSWORD` environment variable
3. Interactive no-echo prompt

Prefer the interactive prompt or `SSO_BIND_PASSWORD`. Avoid `-password` in normal use because command-line arguments can be visible in process lists and shell history.

Example with environment variable:

```bash
export SSO_BIND_PASSWORD='your-temporary-password'
./sso-users -server vcsa.example.local -user administrator@vsphere.local -insecure
unset SSO_BIND_PASSWORD
```

## Flags

| Flag | Default | Description |
| --- | --- | --- |
| `-server` | required | vCenter / PSC host running vmdir |
| `-port` | `636` | LDAPS port |
| `-domain` | `vsphere.local` | SSO domain name |
| `-user` | `administrator@vsphere.local` | SSO admin bind user |
| `-password` | empty | Bind password; prefer prompt or `SSO_BIND_PASSWORD` |
| `-insecure` | `false` | Skip TLS certificate verification |
| `-csv` | empty | Export results to CSV |
| `-json` | `false` | Print JSON instead of a table |
| `-version` | `false` | Print version and exit |

## Output

Default table columns:

| Column | Description |
| --- | --- |
| `USER` | Local SSO account name |
| `UPN` | User principal name |
| `DISABLED` | Account disabled flag from `userAccountControl` |
| `LOCKED` | Account lockout flag from `userAccountControl` |
| `NEVER_EXP` | Password never expires flag |
| `PWD_LAST_SET` | Password last-set timestamp |
| `PWD_EXPIRY` | Computed password expiry timestamp |
| `DAYS_LEFT` | Remaining days, or `never` |
| `EXPIRED` | Whether the password is already expired |

## Bind Behavior

The tool first tries to bind with the supplied `-user` value. If the value looks like a UPN and vmdir returns invalid credentials, it retries with a derived DN:

```text
cn=<local-part>,cn=users,<domain DN>
```

For example:

```text
administrator@vsphere.local -> cn=administrator,cn=users,dc=vsphere,dc=local
```

If both attempts fail with LDAP result code `49`, verify the password, account lockout state, and the SSO domain.

## Troubleshooting

### LDAP Result Code 49: Invalid Credentials

Common causes:

- Wrong password
- Wrong SSO domain in `-domain`
- Account is locked or disabled
- The account is not in `cn=users,<domain DN>` and the derived DN fallback does not match

Try a full DN explicitly:

```bash
./sso-users -server vcsa.example.local -user 'cn=Administrator,cn=users,dc=vsphere,dc=local' -insecure
```

### TLS Certificate Error

Use `-insecure` for internal tests, or add the vCenter certificate/CA to the system trust store.

```bash
./sso-users -server vcsa.example.local -insecure
```

### No Users Returned

Verify the SSO domain and base DN. For `vsphere.local`, the base DN is:

```text
dc=vsphere,dc=local
```

The current implementation searches one level under:

```text
cn=users,dc=vsphere,dc=local
```

If your environment stores local users elsewhere, adjust the search base in `readUsers`.

## Security Notes

- Do not commit `.env` files or credentials. The repository ignores `.env` files.
- Prefer short-lived or temporary credentials for testing.
- Rotate any password that was pasted into chat, terminal history, or logs.
- `-insecure` disables TLS certificate validation; use it only for trusted internal environments.

## Versioning

The single source of truth for the app version is `VERSION`. The binary embeds this file and prints it with:

```bash
./sso-users -version
```

When changing app behavior or build logic:

1. Bump `VERSION`.
2. Update `CHANGELOG.md`.
3. Run `make check`.
4. Build with `make build`.
5. Verify `./sso-users -version`.

`make check-version` uses the Git working tree to catch code/build changes under `apps/sso-users/` when `VERSION` or `CHANGELOG.md` were not updated. README-only changes do not require a version bump.
