# Bashir Agro - App header, branding and profile photos

## Source archives

- Laravel backend: Archive(5).zip
- Flutter app: Archive 2(1).zip

The projects are separate. Deploy the backend first, then build the mobile app.

## Laravel server (backup your current deployment/database first)

Merge the updated project into your Laravel codebase while preserving the existing .env and real storage files. Do NOT overwrite the live .env, user uploads, or database with this source archive.

```bash
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan storage:link
php artisan optimize:clear
```

Use the appropriate PHP binary for your server environment. Make sure `APP_URL` points to the correct accessible HTTPS origin (the absolute image URLs in the API use it), and that the web server can serve `public/storage` and write `storage/app/public`.

In web admin > Settings:

1. Mobile App Headers: expand the target admin screen or farmer dashboard, select a JPG/PNG/WebP banner, edit the title/subtitle and safe style controls, then save that screen.
2. Branding: enter farm name, tagline, logo and favicon in the existing branding/general settings, and save settings.
3. Admin profile photo: choose your photo in Settings and save. Individual farmer photos continue to be uploaded through Farmers > Edit Farmer.

The API route `GET /api/v1/app-appearance` is read-only and requires a valid Sanctum app token. Test with an authenticated user. The screen data is in `data.headers`; brand details are in `data.branding`.

Backend feature tests (when vendor dependencies and DB are available):

```bash
php artisan test --filter=AppAppearanceTest
php artisan test --filter=SettingsAuditTest
```

## Flutter application

Flutter reads the remote configuration once per app session, refreshes when the app resumes, and refreshes on the dashboard's pull-to-refresh. Image URLs are uniquely named after uploads, so changed photos are reloaded rather than reusing stale cache keys. If the API/image fails, the original illustrated header/avatar remains visible.

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test test/app_appearance_test.dart
flutter test test/owner_screens_test.dart
flutter run --dart-define=API_BASE_URL=https://YOUR_HOST/api/v1
```

Replace YOUR_HOST with your existing accessible server host. The Flutter source archive uses the project's original host unless `API_BASE_URL` is overridden.

**One-time mobile release required:** Older builds contain fixed headers and cannot fetch this new configuration. After shipping this updated app build, ordinary banner/title/style/photo changes are published through Laravel without rebuilding the app. Structural changes still require a new app build.

This archive does not contain Composer's `vendor` or Flutter's downloaded SDK dependencies. The environment used to prepare this package had PHP available but not Flutter/Dart or Laravel vendor dependencies; syntax-checked PHP files only. Run the tests above in your development environment and verify on a real Android device before rollout.
