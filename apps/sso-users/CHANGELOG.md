# Changelog

All notable changes to `sso-users` are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project uses semantic versioning.

## [Unreleased]

### Added - Unreleased

- Version guard workflow to make code changes require both `VERSION` and `CHANGELOG.md` updates.

## [0.1.0] - 2026-07-18

### Added - 0.1.0

- Initial Go CLI for listing vCenter SSO users from vmdir over LDAPS.
- Password expiry calculation from `pwdLastSet`, `vmwPasswordNeverExpires`, and `vmwPasswordLifetimeDays`.
- Table, CSV, and JSON output modes.
- Secure password handling through interactive prompt or `SSO_BIND_PASSWORD`.
- UPN bind with fallback to derived vmdir DN.
- `-version` flag backed by the app-local `VERSION` file.
