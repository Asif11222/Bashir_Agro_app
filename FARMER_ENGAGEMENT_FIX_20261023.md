# Bashir Agro Flutter: farmer employment-status display fix (23 October 2026)

- `FarmerItemModel.fromJson` now uses the API's `is_assigned` boolean. If the flag is missing, it can fall back ONLY to the `active_tasks` count; farm locations and historical task totals can no longer imply engagement.
- The farmer activity screen's pull-to-refresh reloads both farmer identity/status and activity history.
- A model regression test is added to `test/owner_work_status_sync_test.dart`.

The Laravel API update in the corresponding backend package is required for correct status responses. The screen design, labels, and navigation are unchanged.

## Local verification

```
flutter pub get
flutter analyze
flutter test test/owner_work_status_sync_test.dart
flutter run --dart-define=API_BASE_URL=https://129-212-239-216.sslip.io/api/v1
```

Use your production API URL when deploying; no Android localhost/ADB reverse is needed for the HTTPS API.
