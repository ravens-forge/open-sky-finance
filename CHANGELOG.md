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
- Main navigation: top bar with menu, search and calendar; Home, Transactions, Reminders, Balance sheet, Budget, Net income and Labels as tabs you can tap or swipe; a drawer with the other pages; an "Add" button for new transactions; full-screen editors; a friendly "Nothing here" page for deleted items or stale links; onboarding on first launch.
- Onboarding in three short, skippable steps: what the app is (with a link to restore a backup or import from Bluecoins), language, theme and first day of week, and the first assets account, whose currency (suggested from the device region) becomes the main currency. Closing the app midway resumes where you left off; after an update, existing users only see new steps, under "What's new".
- Language, theme and first day of week are saved on the device.

[Unreleased]: https://github.com/ravens-forge/open-sky-finance/commits/main
