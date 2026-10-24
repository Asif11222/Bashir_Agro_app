# Bashir Agro — Owner/Admin Work Card Icon Fix (2026-10-24)

## Scope
Flutter application only. The Laravel backend/API is unchanged because it already returns the task name and category in `task`.

## What changed
- Owner task-planning list: task illustration replaces the first submitted evidence photo as the large square card thumbnail.
- Owner farmer-activity list: the same replacement.
- A centralized `TaskThumbnailResolver` selects fish, cow, fertilizer or vegetable illustrations, using the same work information used by the farmer screens.
- Farmer task-card icon selection now uses the same centralized resolver. No visual change on the farmer side.
- Real submitted evidence URLs, photo counts and work photo detail views remain unchanged.
- Added a focused Flutter regression test for category detection and evidence preservation.

## Installation (patch archive)
From your Flutter app directory:

```sh
unzip -o ~/Downloads/Bashir_Agro_Work_Icon_Patch_20261024.zip -d .
flutter pub get
flutter test test/owner_work_thumbnail_test.dart
flutter analyze
flutter run
```

Make a local Git commit or backup before applying the patch. Do not extract the patch into the Laravel backend directory.

## Manual checks
1. Open the admin/owner work-planning screen. Fish work should display the blue fish thumbnail, vegetable work the sprout illustration, and so on.
2. Open an admin/owner farmer activity screen and confirm that its work cards have the same illustrated thumbnails.
3. Open a completed work item to confirm evidence photos are still accessible inside the details page.
4. Open the farmer task list and check that its icons remain unchanged.

## Verification status
Source-level/static checks were completed in the packaging environment. `flutter test`, `flutter analyze`, and on-device QA were not run there because the Flutter SDK is unavailable.
