# Bashir Agro - First 5 Screens Implementation Plan

This document outlines the step-by-step implementation plan for the first 5 core screens of the **Bashir Agro** Flutter prototype based on [Bashir_Agro_Flutter_Prototype_Specification.pdf](file:///f:/bashir%20agro/bashir_agro_app_2/bashir_agro_app_2/Bashir_Agro_Flutter_Prototype_Specification.pdf) and the provided high-fidelity visual design specifications.

---

## 1. Overview of the First 5 Target Designs

| # | Screen Name | Bengali Title | Core Responsibility |
|---|---|---|---|
| **1** | **Login Screen** | আমাদের খামার | Shared phone/password authentication, brand header, demo credentials routing |
| **2** | **Farmer Dashboard** | আজকের কাজ | Daily date header, farmer greeting banner, task cards with statuses & location tags |
| **3** | **Task Details** | কাজের বিবরণ | Full task breakdown, schedule, location block, operational instructions, photo capture rules |
| **4** | **Live Camera** | ছবি তুলুন | Real-time camera viewfinder, framing corner guide, watermark indicator, photo strip, GPS simulation toggle |
| **5** | **Photo Review** | ছবি পর্যালোচনা | Geofence verification badge ("অবস্থান সঠিক"), timestamp & location check, upload & retake flow |

---

## 2. Architectural Blueprint

Following Section 4 & Section 38 of the specification, the code is structured with strict repository abstractions to allow seamless transition to Laravel REST API later:

```
lib/
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Agricultural greens, mint badges, borders, status hues
│   │   └── app_theme.dart         # Material 3 theme with Bangla typography
│   └── utils/
│       ├── date_formatter.dart    # Bengali numeral and date/time formatting
│       └── geofence_helper.dart   # Point-in-polygon math & GPS simulation
├── data/
│   ├── models/
│   │   ├── user_model.dart        # User role (Farmer/Owner), phone, name
│   │   ├── task_model.dart        # Task details, schedule, deadline, instructions, status
│   │   ├── farm_location_model.dart # Polygon coordinates, tolerance, address
│   │   ├── task_photo_model.dart  # Independent GPS, timestamp, insideGeofence flag
│   │   └── submission_model.dart  # Submission records, review status
│   ├── mock/
│   │   ├── mock_users.dart        # Rahim Uddin (01700000001), Abdul Karim (01700000002)
│   │   ├── mock_locations.dart    # East Pond, South Field, North Field with GPS polygons
│   │   └── mock_tasks.dart        # 3 tasks matching Design 2 (সবজি ক্ষেত, মাছের খাবার, গরু)
│   └── repositories/
│       ├── auth_repository.dart   # Contract & MockAuthRepository
│       ├── task_repository.dart   # Contract & MockTaskRepository
│       └── location_repository.dart # Contract & MockLocationRepository
├── state/
│   ├── auth_provider.dart         # Current logged-in user state
│   ├── task_provider.dart         # Selected task, active tasks list
│   └── camera_provider.dart       # Captured photos, insideGeofence simulation state
├── presentation/
│   ├── routes/
│   │   └── app_router.dart        # GoRouter definition with typed routes
│   ├── widgets/
│   │   ├── app_header.dart        # Green wave header with notification bell
│   │   ├── task_card.dart         # Reusable task card with badges & thumbnail
│   │   ├── camera_reticle.dart    # Viewfinder framing corner brackets
│   │   └── agro_button.dart       # Styled primary green CTA button
│   └── screens/
│       ├── screen_1_login/
│       │   └── login_screen.dart
│       ├── screen_2_dashboard/
│       │   └── farmer_dashboard_screen.dart
│       ├── screen_3_task_details/
│       │   └── task_details_screen.dart
│       ├── screen_4_camera/
│       │   └── live_camera_screen.dart
│       └── screen_5_photo_review/
│           └── photo_review_screen.dart
└── main.dart
```

---

## 3. Step-by-Step Implementation Strategy

### Step 1: Design System & Color Palette
- **Primary Green:** `#006837` / `#087A45` (Vibrant deep agro green)
- **Header Accent:** Gradient from `#005C2E` to `#0B7347`
- **Surface / Cards:** Pure White `#FFFFFF` with soft drop shadows and rounded corners (16px - 24px)
- **Backgrounds:** Gentle Off-White / Cream tint (`#F8FAF8`)
- **Status Badges:**
  - `আজ করব` (Today): Mint green container (`#E0F2E9`) with dark green text (`#0B7347`)
  - `চলছে` (In Progress): Soft blue container (`#E3F2FD`) with blue text (`#1976D2`)
  - `বাকি আছে` (Pending): Soft grey/slate container (`#ECEFF1`) with dark slate text (`#455A64`)
- **Bangla Typography:** Clean sans-serif Bengali font rendering using `Hind Siliguri` / `Noto Sans Bengali` fallback.

### Step 2: Data Models & Mock Repositories
1. **User Model (`user_model.dart`):**
   - Fields: `id`, `name`, `phone`, `password`, `role` (`farmer` or `owner`), `avatarUrl`.
   - Seeded demo users for instant login.
2. **Task Model (`task_model.dart`):**
   - Fields: `id`, `title`, `cropCategory`, `ownerId`, `ownerName`, `locationId`, `locationName`, `timeRange`, `date`, `description`, `instructions`, `minPhotos`, `maxPhotos`, `status`, `thumbnailType`, `isLate`.
3. **Task Photo Model (`task_photo_model.dart`):**
   - Fields: `id`, `localPath`, `capturedAt`, `latitude`, `longitude`, `gpsAccuracy`, `insideGeofence`.
   - Adheres to Section 12 rule: *Every photo has its own independent GPS capture time and geofence result.*

### Step 3: Screen 1 – Login Screen ("আমাদের খামার")
- **Visuals:** Full bleed farm landscape background at top, centered circular plant emblem, bold Bengali typography.
- **Form Card:** Floating bottom curved sheet with Phone and Password inputs with leading icons.
- **Interactions:**
  - Default pre-filled demo farmer phone `01700000001` / password `123456`.
  - "লগইন →" button navigates directly to the Farmer Dashboard (`/dashboard`).
  - Forgot password link and role switch hint.

### Step 4: Screen 2 – Farmer Dashboard ("আজকের কাজ")
- **Header:** Curved green header with "আজকের কাজ", date banner "১২ জুন ২০২৪, বুধবার", notification icon with red indicator.
- **Greeting Card:** Farmer avatar, "শুভ সকাল, আব্দুল রহমান!", "আজ আপনার ৩টি কাজ আছে।"
- **Task List:** Chronological feed of tasks:
  1. *সবজি ক্ষেত পরিদর্শন* (লাউ ক্ষেত, ৮:০০ - ১০:০০, দক্ষিণ মাঠ, ২ নং ব্লক) -> Tag: `আজ করব`.
  2. *মাছের খাবার দেওয়া* (পুকুর নং ১, ১২:০০ - ১২:৩০, পশ্চিম পুকুর, বাড়ির পাশে) -> Tag: `চলছে`.
  3. *গরুকে খাবার দেওয়া* (দেশি গরু ৩টি, ৪:০০ - ৫:০০, গোয়ালঘর, উত্তর পাশ) -> Tag: `বাকি আছে`.
- **Interactions:** Tapping any card opens **Screen 3: Task Details**.

### Step 5: Screen 3 – Task Details ("কাজের বিবরণ")
- **Header:** Green app bar with back button.
- **Banner Image:** Lush vegetable crops on bamboo trellis.
- **Title Block:** Sprout icon + "সবজি ক্ষেত পরিদর্শন" + description text.
- **Schedule & Location Card:** Time ("১২ জুন ২০২৪, সকাল ৯:০০ – ১০:০০") and location ("দক্ষিণ পাড়া, ২ নং ব্লক, শ্যামনগর").
- **Instruction Card:** Golden/amber container with document icon and clear field instructions.
- **Photo Rules Card:** Mint container with camera icon: "কমপক্ষে ১টি ছবি তুলতে হবে", "সর্বোচ্চ ৫টি ছবি তোলা যাবে".
- **Primary CTA:** "ছবি তুলুন" button leading to **Screen 4: Live Camera**.

### Step 6: Screen 4 – Live Camera ("ছবি তুলুন")
- **Camera Viewfinder:** Simulated live field view with custom camera preview.
- **Overlay UI:**
  - White corner framing reticles (`[ ]`).
  - Pill badge: "🌱 ছবিটি অবশ্যই এখনই (রিয়েল টাইমে) তুলতে হবে".
  - GPS Simulation Switcher: Allows testing **Inside Geofence** (Valid) vs **Outside Geofence** (Invalid) as required in Section 11 of the specification.
- **Bottom Camera Controls:**
  - Flash button (`⚡A`).
  - Large circular shutter button.
  - Camera switch button (`🔄`).
  - Thumbnail reel of previously captured pictures.
- **Shutter Click:** Captures simulated photo with GPS metadata and navigates to **Screen 5: Photo Review**.

### Step 7: Screen 5 – Photo Review ("ছবি পর্যালোচনা")
- **Header:** Green app bar with back navigation.
- **Photo Card:** Rounded image preview with a round edit/retake icon.
- **Verification Status Box:**
  - Green checkmark + "অবস্থান সঠিক" ("এই ছবির অবস্থান আপনার জমির ভেতরে রেকর্ড করা হয়েছে।").
  - (If simulated outside geofence: Red warning + "নির্ধারিত মাঠের বাইরে তোলা হয়েছে").
- **Metadata Card:**
  - "ছবি তোলার সময়": "১২ জুন ২০২৪, সকাল ১০:১৫" with checkmark.
  - "অবস্থান": "চরশাহী, সাভার, ঢাকা" with checkmark.
- **Automated Verification Shield Box:** Reassures automated GPS and timestamp authenticity.
- **Actions:**
  - "ছবি আপলোড করুন" (Cloud upload CTA): Submits task and shows confirmation.
  - "আরেকটি ছবি তুলুন": Returns to camera to capture up to 5 photos.

---

## 4. Verification & Testing Checklist
- [x] All 5 screens match the layout, colors, icons, and Bengali copywriting of the design screenshots.
- [x] Navigation flow operates smoothly: Login -> Dashboard -> Task Details -> Camera -> Review.
- [x] State management through Riverpod cleanly retains captured photos and task progression.
- [x] GPS simulation mode allows testing both valid inside-geofence and invalid outside-geofence workflows.
- [x] Clean architecture ready for future Laravel API integration without refactoring UI components.
