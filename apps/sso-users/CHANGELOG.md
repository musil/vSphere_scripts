# Changelog

All notable changes to `sso-users` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses semantic versioning.

## [Unreleased]

## [0.3.2] - 2026-07-19

### Fixed - 0.3.2

- Windows release archive is created by a dedicated `go run` helper (`scripts/zipfile.go`) because `go run /dev/stdin` fails in Go module mode on CI runners.

## [0.3.1] - 2026-07-19

### Fixed - 0.3.1

- Release workflow no longer depends on `apt-get`, a system `zip` package, or a Docker-only `release-cli` image, so it works on shell runners such as Rocky Linux.

## [0.3.0] - 2026-07-19

### Added - 0.3.0

- GitLab CI release workflow for prebuilt `darwin/arm64`, `linux/amd64`, and `windows/amd64` binaries.
- Release build script and `make release` target producing archives and SHA256 checksums.

## [0.2.0] - 2026-07-18

### Added - 0.2.0

- Version guard workflow to make code changes require both `VERSION` and `CHANGELOG.md` updates.
- HTTP server mode through `sso-users serve`.
- Unauthenticated `GET /health` endpoint for monitoring.
- Authenticated `GET /api/v1/users` endpoint returning the same JSON shape as CLI `-json` output.
- Shared `GetUsers` business logic used by both CLI and HTTP API modes.

## [0.1.0] - 2026-07-18

### Added - 0.1.0

- Initial Go CLI for listing vCenter SSO users from vmdir over LDAPS.
- Password expiry calculation from `pwdLastSet`, `vmwPasswordNeverExpires`, and `vmwPasswordLifetimeDays`.
- Table, CSV, and JSON output modes.
- Secure password handling through interactive prompt or `SSO_BIND_PASSWORD`.
- UPN bind with fallback to derived vmdir DN.
- `-version` flag backed by the app-local `VERSION` file.
