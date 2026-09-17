<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/branding/logo-dark.svg">
    <img src="assets/branding/logo-light.svg" alt="Open Sky Finance logo" width="128">
  </picture>
</p>

# Open Sky Finance

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![CI](https://github.com/ravens-forge/open-sky-finance/actions/workflows/ci.yml/badge.svg)](https://github.com/ravens-forge/open-sky-finance/actions/workflows/ci.yml)

Open Sky Finance is a free and open-source personal finance app built with Flutter. It tracks assets accounts, income, expenses, transfers, budgets and net worth, with **no limits**: no premium tier, no caps on assets accounts or categories, no ads.

Everything stays on your device. There is no server, no sign-up, no user profile, no analytics and no network access.

> **Status:** pre-alpha. The app is being built; the documentation is written first.
> There is no release yet.

## Key features

- Unlimited assets accounts (bank, cash, credit cards, loans, investments, crypto, property…)
- Income, expense and transfer tracking with categories, subcategories and labels
- Configurable home page: favorite assets accounts, reorderable sections, cash flow, budget, net income and net worth charts
- Balance sheet, net income statement, label totals and a calendar view
- Monthly budgets per category
- Reminders for recurring bills and income, plus scheduled (future-dated) transactions
- Trash to restore deleted transactions
- Local backups in an open, documented JSON format
- Import from Bluecoins backup files (`.fydb`)
- Fully localized: English, Spanish and French

## Privacy

- No network access and no `INTERNET` permission in release builds
- No accounts, logins, emails, profiles or user identifiers
- No analytics, telemetry, crash reporting or advertising SDKs
- Data lives in the app's private storage and leaves the device only when _you_ export a backup file

How to report a problem with any of these: [SECURITY.md](SECURITY.md).

## Tech stack

| Concern          | Choice                            |
| ---------------- | --------------------------------- |
| Framework        | Flutter (version pinned with FVM) |
| State management | Riverpod (with code generation)   |
| Navigation       | go_router                         |
| Local database   | Drift (SQLite)                    |
| Charts           | fl_chart                          |
| Localization     | gen-l10n + ARB files (en, es, fr) |

## Getting started

Requirements: [FVM](https://fvm.app).

```bash
fvm install            # installs the Flutter version pinned in .fvmrc
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run
```

## The logo

A pine-green arc rising above two ink ruled lines:

- **The arc** is the open sky — a sun rising over the horizon: calm and forward-looking.
- **The two lines** are the ruled lines of a paper ledger, the metaphor behind the whole design. They double as the horizon, so the sky rises out of the ledger.
- **Paper, ink and pine colours** come straight from the app's palette; square line ends follow the rule that only buttons and chips are rounded.
- **No coins, currency symbols or charts:** the app is about keeping your finances in order with a clear mind, not about trading.

## Documentation

| Document                           | Contents                                                    |
| ---------------------------------- | ----------------------------------------------------------- |
| [AGENTS.md](AGENTS.md)             | Rules and conventions for contributors and AI coding agents |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to set up, build, test and submit changes               |
| [SECURITY.md](SECURITY.md)         | Privacy guarantees and how to report a vulnerability        |
| [CHANGELOG.md](CHANGELOG.md)       | What changed in each release                                |

## Contributing

Bug reports, translations and pull requests are welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) and [AGENTS.md](AGENTS.md); everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Please **never attach real financial data** (backups, databases, screenshots with real figures) to issues or PRs.

Security vulnerabilities go to [SECURITY.md](SECURITY.md), never to a public issue.

## Support the project

Open Sky Finance is free, has no ads and never will have a premium tier. It is funded only by voluntary donations, and donating unlocks nothing — the app cannot even know you did.

- [GitHub Sponsors](https://github.com/sponsors/fabbo-repo)
- [Liberapay](https://liberapay.com/fabbo-master])
- [Ko-fi](https://ko-fi.com/fabbomaster)

You can also help by starring the repository, translating or reporting bugs.

## Disclaimer

Open Sky Finance is an independent project. It is not affiliated with, endorsed by or connected to Bluecoins or its developers. "Bluecoins" is mentioned only to describe import compatibility. This app does not provide financial advice.

## License

[GNU General Public License v3.0](LICENSE) © Open Sky Finance contributors.
