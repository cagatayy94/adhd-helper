# Mindful Days — ADHD Helper Calendar

A modern, highly interactive, and beautiful SwiftUI calendar application designed to help individuals with ADHD track their habits, medication, and focus levels dynamically.

---

## 🚀 Features

- **Month-by-Month Calendar Grid**: Locale-aware monthly view grid displaying active month days and faded adjacent month days, with smooth animations during transitions.
- **Native Date Picker**: Quick-select header DatePicker defaulting to today's date, synchronizing instantly with the visible monthly grid.
- **Dynamic Habit Checklist**: Custom daily checklists showing progress and completion.
- **Habit Customization (+)**: Add personalized habits by title, description, icon (preset emojis), custom hex color, daily goal counts, repeat intervals (once, daily, weekly, monthly), and estimated duration.
- **Interactive Tapping & Incremental Progress**: Tap a habit row to increment progress (e.g., `0/4` ➔ `1/4` ➔ `Completed`). Items automatically cycle back to 0 on maximum completion for easy corrections.
- **Context-Menu Actions**: Long-press habit items to delete them securely using native iOS context menus.
- **Dynamic Calendar Indicators**: Calendar days display small colored dots indicating the custom colors of habits completed on those dates.
- **Robust Persistence & Thread Safety**: Habits lists and daily completion records are saved asynchronously to `UserDefaults` using Swift Concurrency to prevent UI blocking.
- **Tactile UX**: Light haptic feedbacks (`UIImpactFeedbackGenerator`) integrated with interactions.

---

## 🛠 Tech Stack & Architecture

- **UI Framework**: SwiftUI
- **Reactive Stream**: Combine
- **Concurrency**: Swift Concurrency (`async/await`, `@MainActor`, `Task.detached`)
- **Persistence**: `UserDefaults` + `JSONEncoder`/`JSONDecoder`
- **Architectural Pattern**: **MVVM (Model-View-ViewModel)**

### Code Structure
- [ContentView.swift](file:///Users/cyilmaz/Projects/adhd-helper/adhd%20helper/adhd%20helper/ContentView.swift): Core file containing models, extensions, `CalendarViewModel` state manager, and modular views (`HeaderView`, `CalendarCardView`, `CalendarDayButton`, `TrackerCardView`, `FocusRatingView`, `CheckinRow`, `AddHabitSheet`).
- [adhd_helperApp.swift](file:///Users/cyilmaz/Projects/adhd-helper/adhd%20helper/adhd%20helper/adhd_helperApp.swift): App entry point.
- [adhd_helperTests.swift](file:///Users/cyilmaz/Projects/adhd-helper/adhd%20helper/adhd%20helperTests/adhd_helperTests.swift): Test suite checking month offsets and day count allocations.

---

## 🔨 How to Build and Run

### 1. Xcode (Recommended)
1. Double-click [adhd helper.xcodeproj](file:///Users/cyilmaz/Projects/adhd-helper/adhd%20helper/adhd%20helper.xcodeproj) to open in Xcode.
2. Select your target simulator (e.g., `iPhone 17 Pro`).
3. Press `CMD + R` to compile and run.
4. Press `CMD + U` to execute unit tests.

### 2. Command Line Interface (CLI)
Build the app using standard Xcode build tools:
```bash
# Build the project
xcodebuild -project "adhd helper/adhd helper.xcodeproj" -scheme "adhd helper" -destination "generic/platform=iOS Simulator" build

# Run unit and UI tests
xcodebuild -project "adhd helper/adhd helper.xcodeproj" -scheme "adhd helper" -destination "platform=iOS Simulator,name=iPhone 17 Pro" test
```

---

## 📝 Developer Guidelines

- **Main Actor Isolation**: Keep all UI state transformations inside `CalendarViewModel` isolated to `@MainActor`.
- **ARC Safety**: Do not pass direct references to class properties inside background asynchronous detached tasks. Copy-capture local value types (structs) to prevent retain cycles.
- **Strict Safety**: Do not use force unwraps (`!`) or force casts (`as!`). Implement safe bindings (`guard let`, `if let`).
