# AGENTS.md — Working on Open Sky Finance

This file is the entry point for anyone (human or AI coding agent) writing code in this
repository. Read it fully before making changes.

## What we are building

An offline-only personal finance app for Android and iOS (desktop is a nice-to-have).
The functional reference is a classic "ledger-style" finance app: assets accounts,
categories, transactions, transfers, reminders, budgets, balance sheet, net income,
labels, calendar, trash and a configurable home page with charts.

## Non-negotiable rules

1. **No network.** Do not add HTTP clients, analytics, crash reporting, ads, remote config,
   cloud sync SDKs or any package that phones home. Do not request the INTERNET permission
   in the release Android manifest.
2. **No authentication, no user profile.** There are no user accounts, logins, emails,
   avatars or user IDs.
3. **No server.** All data lives in the local Drift database. Backups are files the user
   explicitly exports.
4. **No limits, no ads.** Never add caps on the number of assets accounts, categories,
   labels, transactions or budgets, and never add paywalls, "premium" flags or ads. The
   project is funded only by donations; donation links never unlock anything and never nag
   (no pop-ups, banners, badges or launch reminders).
5. **Money is an integer.** Amounts are `int` micro-units (1 unit = 1,000,000). Never use
   `double` for stored or summed money.
6. **Never log financial data.** No amounts, assets account names, notes or titles in logs,
   exception messages sent anywhere, or debug prints left in release code.
7. **Never commit real user data.** No real backups (`.fydb`, `.json`), databases or
   screenshots with real figures. Test fixtures must be synthetic; keep personal files in
   the git-ignored `local_samples/`.
8. **Imports and restores are atomic.** They run inside a single database transaction and a
   safety backup is created first.
9. **Everything is localized** in English (`en`), Spanish (`es`) and French (`fr`):
   UI text, plurals, numbers, currency amounts and dates. No hard-coded user-facing strings
   or formats.

## Naming: `AssetsAccount`

A financial account the user tracks (bank, cash, credit card, loan…) is called
**`AssetsAccount`** everywhere in code, database, backups and routes. Never use a bare
`Account` identifier.

| Context                | Name |
| ---------------------- | ---- |
| Domain class           | `AssetsAccount` (`data/models/`) |
| Drift row class        | `AssetsAccountTableRow` (`toDomain()` / `fromDomain()`) |
| Type enum              | `AssetsAccountType` |
| Drift table            | `assets_accounts` (Dart: `AssetsAccountsTable`) |
| Foreign keys           | `assets_account_id`, `to_assets_account_id` |
| JSON / Dart fields     | `assetsAccountId`, `toAssetsAccountId`, `assetsAccounts` |
| Repository             | `AssetsAccountsRepository` (Drift accessor) |
| Providers              | `assetsAccounts…Provider` |
| Feature folder         | `features/assets_accounts/` |
| Routes                 | `/assets-accounts`, `:assetsAccountId` |
| ARB keys               | `assetsAccount…` prefix |

`AssetsAccount` also covers liability types (credit cards, loans, mortgages); the
asset/liability split comes from `AssetsAccountType`. User-facing text keeps natural words
through ARB files: English UI text says **"assets account"** (e.g. "Assets accounts",
"Favorite assets accounts", "New assets account"); Spanish and French use "cuenta" and
"compte".

Exception: Bluecoins source tables and columns (`ACCOUNTSTABLE`, `accountID`, …) keep their
original names because they belong to an external format.

## Stack and tooling

- Flutter via **FVM**. Always run commands through `fvm`. The version is pinned in `.fvmrc`
  (commit it; do not commit `.fvm/`).
- **Riverpod** with code generation (`riverpod_annotation`, `riverpod_generator`).
- **go_router** for navigation (typed routes are optional; route paths are defined in one
  file).
- **Drift** (`drift`, `drift_flutter`, `drift_dev`) on SQLite.
- **sqlite3** (already a Drift dependency) to read Bluecoins backups directly.
- **file_picker** for choosing import files and saving exports.
- **gen-l10n** (`flutter_localizations` + `intl`) with ARB files: `en` is the template and
  fallback, `es` and `fr` are required translations.
- **fl_chart** for charts.
- **uuid** for primary keys.
- Lints: `flutter_lints`, configured in [analysis_options.yaml](analysis_options.yaml).

Always check pub.dev for current stable versions when adding a dependency, and prefer
packages that are actively maintained and have no network behaviour.

## Common commands

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs   # Drift + Riverpod codegen
fvm dart run build_runner watch --delete-conflicting-outputs   # during development
fvm dart run drift_dev make-migrations                          # after bumping schemaVersion
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm dart format .
```

## Project layout

```
lib/
  main.dart                 # ProviderScope + App
  app/                      # App widget, router, theme
  core/                     # money, dates, ids, result/error types, shared widgets
  data/
    database/
      tables/               # one `…Table` per file + its `…TableRow` class
    models/                 # domain objects, value objects, drafts, query results
    repositories/           # one Drift accessor per file: queries, rules, mapping
  services/
    backup/                 # JSON export / restore
    bluecoins/              # .fydb reader and mapper
  features/                 # one folder per feature: presentation + providers
  l10n/                     # app_en.arb (template), app_es.arb, app_fr.arb
assets/
  branding/                 # logo
  fonts/                    # bundled fonts (+ their OFL licenses)
test/
  fixtures/                 # synthetic data only
```

Layers depend downwards only:
presentation → providers → services/repositories → Drift.

## Conventions

- Feature-first folders. Widgets never talk to Drift directly: widget → provider →
  repository. Repositories are the only data-access type: each is a Drift accessor
  (`@DriftAccessor`) holding its queries, writes, invariants and row ↔ domain mapping.
- Providers that read data expose Drift `Stream`s (`@riverpod Stream<...>`) so the UI
  updates automatically after writes.
- Mutations live in `AsyncNotifier` classes or repository methods called from them.
- Aggregations (balances, totals) are computed in SQL inside repositories, not by loading all rows
  into Dart.
- Writes touching more than one table run inside `db.transaction(...)`;
  `PRAGMA foreign_keys = ON`.
- All user-facing strings go through `context.l10n` (`AppLocalizations`). No hard-coded UI
  text. Use ICU `plural`/`select` instead of concatenation.
- Services return error codes, never user-facing text; the UI maps codes to ARB messages.
- Format money only with `core/money` helpers; parse user input only with `parseMoney`.
  Both take the active locale.
- Dates are formatted only with `DateFormat` skeletons and the active locale.
- Dates of transactions are **local wall-clock times** (no time zone).
- Route parameters carry only IDs and enum values — never names, amounts or notes.
- Colours, income/expense/transfer semantics and chart series come from the theme
  (`FinanceColors` theme extension), never hard-coded in widgets, and meaning is never
  conveyed by colour alone.
- Fonts are bundled assets; never fetch them at runtime (`google_fonts` is not allowed —
  the app has no network access).
- Heavy work (large file parsing, JSON encoding/decoding) runs in a background isolate.
- Drift tables are `…Table` classes (`TransactionsTable`, SQL name set with `tableName`);
  their rows are `…TableRow` classes (`TransactionTableRow`) and never leave `data/database`:
  repositories map them to domain objects (`Transaction`) with `toDomain()`, and
  `…TableRow.fromDomain(…)` maps back. Domain objects group related columns into value objects (`Money`,
  `TransferDestination`, `ReminderSchedule`, `Timestamps`); rows stay flat. Aggregations sum money **per currency**; convert
  totals with `CurrencyConverter` (`core/money/`).
- Schema history lives in `drift_schemas/`; `make-migrations` also regenerates
  `test/drift/` (committed, since CI only runs `build_runner`).
- **Generated files are not committed.** `*.g.dart`, `*.drift.dart` and generated
  localizations are ignored; run `build_runner` after cloning and after pulling changes to
  annotated files. CI regenerates them before analysing.
- Keep widgets small; extract anything longer than ~150 lines.
- Use `sealed` classes for results/errors of import and restore operations.
- Prefer classes over `typedef` (no record or type aliases for data); one public class per
  file in `data/models/` (domain objects, drafts, query results).

## Definition of done for a change

- `fvm flutter analyze` has no warnings and `fvm dart format .` leaves no diff.
- New logic has unit tests (repositories, money helpers, importers, backup codec).
- Schema changes include a Drift migration and a migration test.
- Backup format changes bump the backup `schemaVersion` and are noted in
  [CHANGELOG.md](CHANGELOG.md).
- UI strings exist in `app_en.arb`, `app_es.arb` and `app_fr.arb` (no untranslated
  messages), and the screen was checked in all three locales and with long French text.
- No new dependency with network access, telemetry or ads.

## Testing

| Layer         | Test type     | Notes |
| ------------- | ------------- | ----- |
| core/money    | unit          | Parsing edge cases, rounding, negatives, in en/es/fr |
| l10n          | unit          | Same keys and placeholders in all ARB files |
| Repositories  | unit          | In-memory Drift database |
| Migrations    | unit          | Drift schema verifier |
| Backup codec  | unit          | Round-trip: snapshot → JSON → snapshot is identical |
| Bluecoins     | unit          | Synthetic `.fydb` built at test time from a committed SQL script |
| Screens       | widget/golden | Key flows, goldens in en/es/fr, light and dark |

See also: [CONTRIBUTING.md](CONTRIBUTING.md) for setup and pull request rules, and
[SECURITY.md](SECURITY.md) for the privacy guarantees the code must keep true.
