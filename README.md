# Daily Workout - iOS App

[![iOS Build](https://github.com/USERNAME/REPO/actions/workflows/ios-build.yml/badge.svg)](https://github.com/USERNAME/REPO/actions/workflows/ios-build.yml)

Workout scheduling & tracking app — SwiftUI + SwiftData, iOS 17+.

## Project Structure

```
├── DailyWorkoutApp.swift         # @main entry point
├── Package.swift                 # SPM (buat CI)
├── Models/
│   ├── WorkoutType.swift         # Exercise library (@Model)
│   ├── ScheduleRule.swift        # Day-of-week schedule (@Model)
│   └── WorkoutLog.swift          # Daily tracking log (@Model)
├── Views/
│   ├── ContentView.swift         # Tab navigation
│   ├── TodayView.swift           # Dashboard + checklist
│   ├── SchedulePlannerView.swift # Weekly routine
│   └── CustomizationHubView.swift# Workout CRUD library
└── Helpers/
    ├── DataSeeder.swift          # 15 default workouts
    └── DateExtensions.swift      # Date utilities
```

## Open in Xcode (Mac Only)

1. Drag all `.swift` files into a new Xcode iOS project
2. Select SwiftUI + SwiftData template
3. Build & Run (⌘R)

## CI/CD (GitHub Actions)

Setiap push ke `main` otomatis di-compile di cloud Mac.
Cek tab **Actions** di GitHub repo buat liat hasilnya.
