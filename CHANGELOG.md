# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Two other version numbers exist and are **not** the app version: the Drift database `schemaVersion` and the backup format `schemaVersion`. Note changes to either one here.

## [Unreleased]

### Added

- Repository scaffolding: contributor documentation, issue and pull request templates, CI workflow.
- App icon and launch screen based on the logo, in light and dark mode.
- App language selectable from Android system settings (Android 13+).
- "Ledger" look in light and dark mode, with the Newsreader and Public Sans fonts bundled in the app (no downloads).
- Screen readers say amounts with the currency name ("12.50 euros") in English, Spanish and French.
- Store listing in English, Spanish and French.
- Local database (Drift `schemaVersion` 1): assets accounts, categories, transactions, labels, budgets, reminders and settings. First launch creates a cash assets account and default category groups in the device language.

[Unreleased]: https://github.com/ravens-forge/open-sky-finance/commits/main
