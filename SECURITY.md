# Security Policy

Open Sky Finance handles sensitive financial data. Reports about anything that could expose that data are taken seriously, even when the impact looks small.

## Supported versions

The project is pre-release: only the latest commit on `main` is supported. Once releases start, the newest release is the only supported one.

## Reporting a vulnerability

**Do not open a public issue.** Use one of these private channels:

1. [GitHub private vulnerability reporting](https://github.com/ravens-forge/open-sky-finance/security/advisories/new) (preferred — Security → Report a vulnerability).
2. Email `fabianscherle99@gmail.com` if you cannot use GitHub.

Please include:

- What the issue is and why it matters (what an attacker gains).
- Steps to reproduce, or a proof of concept.
- Affected version/commit, platform and OS version.
- **No real financial data.** Reproduce with synthetic data; describe file structure and counts instead of attaching your own backups or database.

You will get an acknowledgement within 7 days and an assessment within 30 days. Fixes are released as soon as they are ready; reporters are credited in the release notes and the advisory unless they prefer to stay anonymous. Please give us reasonable time to publish a fix before disclosing publicly.

## In scope

- Financial data leaving the device (any outbound request, unexpected file writes, data in URLs opened in the browser, logs or clipboard content containing amounts or names).
- Data loss or corruption: failed migrations, non-atomic imports and restores, backup files that cannot be restored.
- Parsing of untrusted input: Bluecoins `.fydb` files and JSON backups (crashes, SQL taken from the file, path traversal, unbounded memory use).
- Local data exposure: a database or safety backup written outside the app's private storage, Android auto-backup or iCloud backup including financial data, sensitive content visible in the app switcher once screen protection ships.
- Weaknesses in app lock or database encryption once those features ship.

## Out of scope

- Attacks requiring a rooted/jailbroken device or physical access with an unlocked screen.
- The user's own exported backup files: v1 backups are plain JSON and unencrypted by design, and the app says so before exporting.
- Missing hardening that is already announced as planned (database encryption, app lock and screen protection are not implemented yet).

## Design guarantees

These properties are part of the product, not an accident. A change that breaks one is a security bug:

- No network access and no `INTERNET` permission in release builds.
- No accounts, logins, profiles or user identifiers.
- No analytics, telemetry, crash reporting or advertising SDKs.
- Financial data is never written to logs.
- Data lives in the app's private storage and leaves the device only through an explicit user action.

The rules that keep these true are listed in [AGENTS.md](AGENTS.md).
