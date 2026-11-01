# Little Focus — native iPhone app

SwiftUI iOS app, targeting iOS 17 or later. Uses native views and local UserDefaults persistence; no website, WebView, server, account, or third-party dependencies.

## Included

- Focus and rest timer with start, pause, resume, and reset.
- Configurable focus (1–90 minutes) and rest (1–30 minutes).
- Add, complete, and delete tasks.
- Daily totals and dated session history.
- Timestamp-based timer recovery after backgrounding or relaunching; each completed focus session counts once, against its actual completion date.
- VoiceOver labels, native controls, scrolling layouts, and Dynamic Type for body text.

## Open and run on a Mac

1. Open `LittleFocus.xcodeproj` in Xcode 16 or later.
2. Select the **LittleFocus** scheme and an iPhone simulator, then Run (⌘R).
3. For a physical iPhone, select the LittleFocus target → Signing & Capabilities → choose your Apple development team. Change `com.dandy.littlefocus` to a unique bundle identifier if necessary.
4. Connect the iPhone, select it as the run destination, enable Developer Mode if prompted by iOS, and Run.

No development team or signing credentials are included in this project.

## Verification on a Mac

Run `bash verify-mac.sh` from this directory. It selects an available iPhone simulator and runs the included XCTest suite. Tests cover pause/resume, background completion without duplicate credit, rest sessions, reset/mode switch, and persistence round-trip.

The manually triggered GitHub Actions workflow in `.github/workflows/ios-build.yml` runs these checks on a cloud Mac, launches the app in the simulator, captures a screenshot, and builds `LittleFocus-unsigned.ipa` for later signing. An unsigned IPA cannot be installed directly; it must be signed with your Apple account through a suitable installation route. The workflow does not run on push.

Manual device checks: add and complete a task; relaunch and check it persists; set focus to one minute; start, background the app, return after completion, and confirm one history entry. Confirm changing tabs, large text sizes, and landscape layout remain usable.

## Current verification limits

Created on Windows without Swift, Xcode, an iOS simulator, or a connected iPhone. Source/project reference checks were performed. Swift compilation, XCTest execution, code signing, and physical-device installation have **not** been performed. This is a native Xcode source project, not a compiled IPA or an App Store release.

No background alerts are implemented. The elapsed timer reconciles when the app returns to the foreground. Deleting the app removes local data. An App Store release additionally needs app icons, signing, store metadata, and device validation.
