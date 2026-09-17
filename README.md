# HydroFlow 💧

A polished, native **iOS 17 SwiftUI hydration tracker** — built from the HydroFlow design system (`stitch_ui/`) and the product plan (`iOS Hydration Reminder App Plan.txt`).

## Screens

| Screen | Highlights |
|---|---|
| **Onboarding** | Name, weight (lbs/kg stepper), biological sex, pregnancy/breastfeeding pills, 2×2 activity grid, climate picker, live goal-baseline pill |
| **Today** | Animated liquid-glass hydration orb (waves + bubbles + specular sheen), gradient progress ring, hydration-rhythm pill, quick stats, one-tap vessel logging, recent sips |
| **Log Hydration** | Volume stepper with mini liquid gauge, 6 preset chips, 12-beverage list with hydration indexes |
| **Analytics** | Weekly summary (days met, avg, WoW %), animated bar chart with goal line + "Today" marker, day-breakdown timeline, monthly consistency heat-map |
| **History** | All entries grouped by day with per-day totals, swipe-to-delete |
| **Settings** | Smart reminders (interval, active hours, bedtime mode), dynamic weather, sounds & haptics, goal editor, profile editor, HealthKit connect, history reset |

## Features (mapped to the plan)

- ✅ One-tap logging (vessel chips + repeat-last-sip)
- ✅ Smart reminders via `UNUserNotificationCenter` — interval, active hours, bedtime mode
- ✅ Personalized goal: sex baseline blended with weight heuristic, + pregnancy/breastfeeding/activity/climate modifiers
- ✅ Streaks, weekly/monthly stats, calendar heat-map
- ✅ Multi-beverage hydration factors (coffee 80%, electrolytes 110%, …)
- ✅ HealthKit sync (`dietaryWater`) with de-duplication metadata
- ✅ Dynamic weather bonus on hot days (offline seasonal model, pluggable provider)
- ✅ Confetti + haptics on goal completion
- ✅ Dark mode, Dynamic Type–friendly system text styles, 60 fps TimelineView animations

## Project layout

```
HydroFlow/
├── Sources/
│   ├── App/            # App entry, root, tabs
│   ├── Models/         # UserProfile, WaterEntry, BeverageType, ReminderSettings
│   ├── Services/       # GoalCalculator, StatsEngine, Notifications, HealthKit, Weather, Haptics
│   ├── Store/          # HydrationStore (JSON persistence, debounced background saves)
│   └── Views/
│       ├── Components/ # Theme, shared components, orb, confetti
│       ├── Onboarding/ Today/ Log/ Analytics/ Settings/
├── Tests/HydroFlowTests/
├── Resources/          # Info.plist, Assets (app icon)
└── Project/            # XcodeGen spec (project.yml)
```

## Building

The Xcode project is generated from [`XcodeGen`](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd HydroFlow/Project
xcodegen generate
open HydroFlow.xcodeproj
```

Then select the **HydroFlow** scheme and an iPhone simulator, and hit ⌘R.

> The `.xcodeproj` is gitignored — always regenerate it from `project.yml`.

### Tests

```bash
cd HydroFlow/Project
xcodebuild test -scheme HydroFlow \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO
```

Covers: goal calculation (sex/weight/modifiers/clamps), streak logic (today-in-progress vs. yesterday-broken), Monday-first weeks, week-over-week deltas, heat-map ratios, notification planning (active window/bedtime mode), unit round-trips, and persistence round-trip.

## CI

GitHub Actions (`.github/workflows/ci.yml`) does two things on macOS 14:
1. **test** — generates the project with XcodeGen and runs the full unit-test suite.
2. **ipa** — archives an **unsigned IPA** and uploads it as the `HydroFlow-unsigned-ipa` artifact (retained 30 days).

## Installing on your iPhone (no Mac required)

### 1. Grab the unsigned IPA
Go to the repo's **Actions** tab → latest run → download the **HydroFlow-unsigned-ipa** artifact and unzip it. (Run the **ipa** workflow manually via *Run workflow* if you just pushed.)

### 2. Sign + install with Sideloadly (free, Windows)
1. Download [Sideloadly](https://sideloadly.io) and install iTunes/Apple Drivers if prompted.
2. Connect your iPhone via USB (trust the computer if asked).
3. Drag `HydroFlow-unsigned.ipa` into Sideloadly.
4. Enter your **Apple ID** (a free account works) — Sideloadly signs the app with your personal certificate.
5. Click **Start**. When it finishes, on the iPhone go to *Settings → General → VPN & Device Management* and **trust** your developer certificate.

> **Note:** free Apple ID certificates expire after **7 days** — re-sign with Sideloadly when the app stops opening. A paid Apple Developer account ($99/yr) gives 1-year certificates and TestFlight distribution.

### Alternative: any Mac with Xcode
```bash
brew install xcodegen
cd HydroFlow/Project && xcodegen generate
open HydroFlow.xcodeproj   # set your Team in Signing & Capabilities, plug in iPhone, ⌘R
```

## Web preview (instant, no Apple ID)

`webapp/` is a faithful, interactive phone-shaped preview of all five screens — logging, orb, charts, heat-map, settings, confetti — running entirely in the browser:

```bash
cd webapp
python -m http.server 8080
```

Then open `http://<your-computer-LAN-IP>:8080` in Safari on your iPhone (same Wi-Fi), or `http://localhost:8080` on the PC. It is a **demo of the UI**, not the native app — HealthKit/notifications only exist in the SwiftUI build.

## Design system

Colors, typography, radii, and elevation tiers come from [`stitch_ui/stitch_hydration_tracker_app_ui/hydroflow/DESIGN.md`](stitch_ui/stitch_hydration_tracker_app_ui/hydroflow/DESIGN.md) — implemented in `Sources/Views/Components/Theme.swift`.
