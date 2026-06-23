# ADHD Helper Project Rules & Guidelines

This document details workspace-scoped rules and style guides for all developers and AI coding agents working on the ADHD Helper (Mindful Days) repository.

---

## 🏗 Architecture & Code Quality

- **MVVM Pattern**: Always decouple business logic, state storage, and calendar mathematics from SwiftUI layouts. Implement updates inside a `@MainActor`-isolated View Model.
- **Strict SwiftUI Modularization**: Avoid massive monolithic layout files. Split subviews (like rows, cards, custom selectors) into dedicated SwiftUI structs to prevent broad view invalidation and excessive redrawing.
- **Safety**: Do not use force unwraps (`!`) or force type-casts (`as!`). Implement defensive bindings (`guard let`, `if let`, `nil-coalescing`) and throw errors gracefully.
- **Value Semantics**: Favor value types (`struct`, `enum`) for model data to ensure thread-safe cross-concurrency data sharing.

---

## ⚡ Concurrency & Performance

- **Main Actor Thread Safety**: Explicitly isolate the view model class and view layouts to `@MainActor` to prevent compiler warnings and thread-safety exceptions.
- **Offloaded I/O Tasks**: Always run disk reads, writes, and JSON encoding/decoding inside detached background tasks (`Task.detached(priority: .background)`) to guarantee the main interface remains highly responsive.
- **ARC Safety**: Do not directly reference `self` in detached closures. Perform a copy-capture of value types to prevent retention cycles or memory leaks.

---

## 🧪 Testing Requirements

- Whenever view models, grid math, or persistence formats are updated, verify compiling correctness via terminal tests before pushing code changes:
  ```bash
  xcodebuild -project "adhd helper/adhd helper.xcodeproj" -scheme "adhd helper" -destination "platform=iOS Simulator,name=iPhone 17 Pro" test
  ```
- Keep unit tests updated in `adhd_helperTests.swift` for any calendar boundary adjustments.
