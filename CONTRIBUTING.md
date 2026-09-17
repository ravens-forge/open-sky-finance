# Contributing to Open Sky Finance

Thanks for your interest in the project. Bug reports, translations, documentation fixes and pull requests are all welcome.

Before writing code, read [AGENTS.md](AGENTS.md) — it holds the rules and conventions that every change must follow. Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## The golden rule: never share real financial data

This is a personal finance app. In issues, pull requests, logs and test fixtures:

- **Never** attach real backups (`.json`), Bluecoins files (`.fydb`), databases or screenshots showing real amounts, assets account names or notes.
- Describe problems with structure and counts instead ("a transfer between two accounts in different currencies, ~4000 transactions").
- Keep files you need for local investigation in `local_samples/` — it is git-ignored.

Maintainers delete accidentally shared personal files and will ask you to consider their contents exposed.

## Setting up

Requirements: [FVM](https://fvm.app) and the usual Flutter platform tooling (Android SDK, Xcode on macOS).

```bash
git clone https://github.com/ravens-forge/open-sky-finance.git
cd open-sky-finance
fvm install                                                    # Flutter version from .fvmrc
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # required: generated code is not committed
fvm flutter run
```

## Everyday commands

```bash
fvm dart run build_runner watch --delete-conflicting-outputs   # keep codegen running
fvm flutter gen-l10n                                           # regenerate localizations
fvm flutter analyze
fvm flutter test
fvm dart format .
```

## Before opening a pull request

- [ ] `fvm flutter analyze` reports no issues
- [ ] `fvm dart format .` leaves no diff
- [ ] `fvm flutter test` passes
- [ ] New logic has unit tests; schema changes have a migration **and** a migration test
- [ ] New user-facing strings exist in `app_en.arb`, `app_es.arb` **and** `app_fr.arb`
- [ ] No new dependency with network access, telemetry or ads
- [ ] No real financial data anywhere in the diff

## Commits and branches

- Branch off `main`: `feat/…`, `fix/…`, `docs/…`, `chore/…`.
- Write commit subjects in English, in the imperative, following
  [Conventional Commits](https://www.conventionalcommits.org/) — e.g.
  `feat(transactions): add transfer editor`.
- Keep pull requests focused: one feature or fix per PR. Split large changes.
- Rebase on `main` rather than merging it back into your branch.

## Translations

The app ships in English, Spanish and French. English (`lib/l10n/app_en.arb`) is the template and the fallback; every key added there must be added to `app_es.arb` and `app_fr.arb` in the same pull request.

- Keep ICU placeholders and `plural`/`select` structures identical across files.
- Keep terminology consistent with the existing translations (an "assets account" is *cuenta* in Spanish and *compte* in French).
- Check the screen in all three locales; French and Spanish text is usually longer.

Adding a **new language** is welcome: open an issue first so we can agree on the locale code and check that you can keep it up to date.

## Reporting bugs and proposing features

Use the [issue forms](https://github.com/ravens-forge/open-sky-finance/issues/new/choose). The app can pre-fill the technical fields for you (Settings → Report a bug): app version and build, platform and OS version, app language and database schema version.

Security vulnerabilities are **not** reported in public issues — see [SECURITY.md](SECURITY.md).

## Scope: what will not be merged

The project's identity depends on a few refusals. Pull requests adding any of the following will be closed:

- Network access of any kind: HTTP clients, cloud sync, remote config, update checks
- Analytics, telemetry, crash reporting or advertising SDKs
- User accounts, logins or profiles
- Paywalls, "premium" features, unlockables tied to donations, or any limit on the number of assets accounts, categories, labels, transactions or budgets
- Donation pop-ups, banners, badges or reminders

If you are unsure whether an idea fits, open an issue before writing code.

## Licensing of contributions

By contributing you agree that your work is licensed under the [GNU General Public License v3.0](LICENSE), like the rest of the project. There is no CLA.
