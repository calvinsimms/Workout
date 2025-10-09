# Workout App (Work in Progress)

A SwiftUI-based **Workout Tracker** app using **SwiftData** for managing workouts, exercises, and calendar events. Designed for iOS 17+ with modern SwiftUI features and UIKit integration for calendar functionality.

**Status:** Work in progress. Some features are fully implemented, others are stubbed or experimental.

## Current Features

**Navigation & Layout**

* Tab-based navigation: Workouts, Calendar, Statistics, Settings
* Custom bottom navigation bar with haptic feedback
* Light/dark color scheme (custom colors in `Assets.xcassets`)

**Workouts**

* Add, delete, edit, and reorder workouts
* Seed default exercises automatically if none exist
* View workout details
  * Currently only shows exercise title and stopwatch for set timing
* Add exercises to workouts and add exercises to the exercise list

**Calendar**

* Calendar view using `UICalendarView` via UIKit integration
* Display sample events on calendar
* Select dates and view associated events

**Settings**

* Navigate to “Manage Exercises” (stubbed view)
* Basic layout and navigation ready

**Misc**

* SwiftData integration (`@Query`, `@Environment(\.modelContext)`)
* In-memory previews for testing

## In Progress Features

* Adding workouts to the calendar and allowing the user to decide whether to save the workout for future re-use or keep just for the scehduled day
* Developing workout page to include set / rep / time / distance fields where applicable
* Persistent storage of events and workouts (currently only in-memory)
* Statistics calculations (total volume, workout count, progress tracking)
* Dynamic linking of workouts with calendar events

## Planned Features

* Sync workouts and events across devices (iCloud / CoreData persistent storage)
* Export and import workouts
* Notifications for scheduled workouts
* Enhanced UI/UX for statistics and progress visualization

## Tech Stack

* **Frontend:** SwiftUI, UIKit (for calendar integration)
* **Data Management:** SwiftData
* **Platform:** iOS 17+
* **Previews & Testing:** SwiftUI `#Preview` with in-memory data

## Usage

1. Open the project in **Xcode 17+**.
2. Build and run on a simulator or device.
3. Navigate between tabs using the custom bottom bar.
4. Use **Workouts** tab to add, delete, or reorder workouts.
5. Use **Calendar** to view sample events. Adding new exercises from the calendar is in progress.
6. Explore **Settings → Manage Exercises** (view is stubbed).

> Some features will not persist data across app restarts until persistent storage is implemented.

## File Structure (Key Views)

```
ContentView.swift         # Main tabbed view and seed logic
ButtonNavBar.swift        # Custom bottom navigation bar
WorkoutListView.swift     # List and management of workouts
CalendarView.swift        # Calendar display using UIKit
SettingsView.swift        # Settings page with navigation to exercises
StatsView.swift           # Statistics page (currently stubbed)
```

## Notes for Developers

* Default exercises are seeded only if the exercise list is empty.
* UI uses custom colors: `Button`, `Background`, `Grayout` in `Assets.xcassets`.
* Calendar events are currently **static samples**, not tied to real workouts.
* The `Workout` and `Exercise` models use `SwiftData` with order properties for sorting.
* Preview data uses in-memory storage; configure persistent storage for production.


# View-Only License (Non-Commercial / Reference Use Only)

**Copyright (c) 2025 Calvin Simms**

All rights reserved.

You are permitted to:

* **View, read, and clone** this repository for personal or educational reference.
* Use this repository as a learning tool or for private study.

You are **not permitted** to:

* Use this code or any part of it for **commercial purposes**.
* Redistribute, publish, or sell the code.
* Create derivative works or incorporate it into other projects without **explicit written permission** from the author.

> By accessing this repository, you agree to use it **only for reference and learning**. Any other use is strictly prohibited.
