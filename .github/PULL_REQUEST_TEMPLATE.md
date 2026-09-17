## What and why

<!-- What does this change, and which problem does it solve? Link the issue: Closes #123 -->

## How to test

<!-- Steps a reviewer can follow, with synthetic data only. -->

## Checklist

- [ ] `fvm flutter analyze` reports no issues
- [ ] `fvm dart format .` leaves no diff
- [ ] `fvm flutter test` passes
- [ ] New logic is covered by tests
- [ ] Schema change? Drift migration **and** migration test included
- [ ] Backup format change? `schemaVersion` bumped and the change noted in `CHANGELOG.md`
- [ ] New strings added to `app_en.arb`, `app_es.arb` **and** `app_fr.arb`, screen checked
      in the three locales
- [ ] No new dependency with network access, telemetry or ads
- [ ] No real financial data in the diff, the screenshots or the tests
- [ ] `CHANGELOG.md` updated under "Unreleased" (user-visible changes)

## Screenshots

<!-- Optional. Synthetic data only, light and dark if the UI changed. -->
