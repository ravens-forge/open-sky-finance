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
- Local database (Drift `schemaVersion` 1): assets accounts, category groups, categories, transactions, labels, reminders and settings. A transaction points at a category and a category at a group; a budget is kept on the group or category it caps. First launch creates a cash assets account and the default category groups, each with one category, in the device language.
- Main navigation: top bar with menu, search and calendar; Home, Transactions, Reminders, Balance sheet, Budget, Net income and Labels as tabs you can tap or swipe; a drawer with the other pages; an "Add" button for new transactions; full-screen editors; a friendly "Nothing here" page for deleted items or stale links; onboarding on first launch.
- Onboarding in three short, skippable steps: what the app is (with a link to restore a backup or import from Bluecoins), language, theme and first day of week, and the first assets account, whose currency (suggested from the device region) becomes the main currency. Closing the app midway resumes where you left off; after an update, existing users only see new steps, under "What's new".
- Language, theme and first day of week are saved on the device.
- Assets accounts page: your accounts grouped into assets and liabilities by type, with subtotals in your main currency, a favorite star for the Home charts, hidden accounts on request, and reordering by dragging. Each account opens a detail with its balance, a six-month balance chart, credit card usage and the month's transactions with daily balances. The editor sets name, type, currency, opening balance, notes and options; deleting says exactly what is removed for good and offers hiding instead.
- Categories page: your groups for income and for expenses, the categories inside them, and reordering by dragging or moving a row up and down. A group shows in the colour of its type, green for income and red for expense, and has nothing else to choose; a category has a name, a group, an icon and a colour, and can be hidden from the pickers. Deleting a category asks where its transactions and reminders go — to another category or nowhere — and a group has to be emptied first. Pickers search without worrying about accents.
- Income comes before expenses everywhere, and every type is chosen with the same rounded selector.
- Transactions page: pick a month, see its income, expenses and net in your main currency, search titles and notes, and filter by type, assets account, category or label. Future-dated transactions come first under “Scheduled”, then the rest by day with each day's net. Swipe a row to move it to the Trash, with Undo.
- Transaction editor: income, expense or transfer; the amount is typed positive in the assets account's currency, with a refund toggle for expenses. Titles autocomplete from earlier ones and bring back their category and assets account. Transfers have From and To with a swap button and, between currencies, the amount received or the rate (either one fills the other). Date and time, labels (created on the spot) and notes. Save, “Save and add another” and Delete, with messages that say exactly what is missing.
- Labels page: each label with its number of transactions and total for the month, in your main currency; labels without transactions that month are muted. Tap one to see its transactions. Create, rename and delete labels (long press a row); deleting a label keeps its transactions.
- Trash page: deleted transactions grouped by the day they were deleted, each with Restore and Delete permanently (after confirming); “Empty” deletes them all after confirming. The drawer shows how many items the Trash holds.
- Home page: favorite assets accounts, net worth and this month's net income, cash flow, budget summary, net income and net worth charts for the last 6 or 12 months, and upcoming reminders (hidden by default). Charts use your favorite assets accounts (or all visible ones), are read aloud as lists of figures, and tapping a month opens its transactions. Drag a section by its handle or long press its title to move it, with a dashed slot showing where it lands; "Arrange Home" moves, hides and shows sections and resets the default order.

[Unreleased]: https://github.com/ravens-forge/open-sky-finance/commits/main
