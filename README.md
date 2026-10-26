# Don’t Forget Me 🎒

A native iOS app for that “did I leave something behind?” moment. Pip, an original backpack buddy, turns a departure reminder into a friendly packing checklist. SwiftUI, Core Location, and local notifications; no dependencies, account, or backend.

## Run

Open `DontForgetMe.xcodeproj` in Xcode 26.2 or newer, select the **DontForgetMe** scheme and an iPhone simulator, then Run. Supports iOS 17+. To install on your iPhone, select your Apple development team in Signing & Capabilities and choose the connected device. No signing team is hardcoded.

`project.yml` is the project source; regenerate with `xcodegen generate` after changing targets or files. The generated Xcode project is included, so XcodeGen is not necessary just to run.

## Everyday flow

1. Tap **Let’s pack**, enable notifications, allow location, then upgrade to **Always** location. Keep Precise Location and Background App Refresh enabled.
2. Add your essentials in **My things**. Student ID, water bottle, and keys are included. Toggle items or remove them; changes apply to the next checklist.
3. Tap **Start lookout**. A good location fix creates a local stay anchor and an exit region.
4. Leaving roughly 150 meters from that anchor after at least 20 minutes opens a checklist and schedules an immediate local notification plus a notification repeating every 60 seconds.
5. Opening the app or tapping a notification does **not** stop the repeat. Tap **Stop reminders** or **All packed. Let’s go!** inside the checklist. Checking every item is optional. Completed checklists earn a star.

The checklist, item selection, current anchor, and monitoring preference survive app restarts. There is only one active checklist. Pausing lookout stops location services but does not cancel an already active reminder.

## What iOS can and cannot guarantee

This app tracks the phone’s departure, not the actual belongings. Location events and local notifications are delivered by iOS, not on a guaranteed real-time schedule. A 150-meter area is intentional: GPS cannot reliably identify the instant you cross a classroom or café doorway. Poor fixes (accuracy worse than 65 meters), stale fixes, and out-of-order fixes are ignored. Standard location updates use an additional accuracy margin for departure; region exits are validated against the current anchor and dwell time.

Always location, precise location, notification permission, and Background App Refresh matter. Focus, notification settings, force-quitting, power management, and unavailable GPS can delay or prevent reminders. The app cannot bypass these controls or play an unstoppable alarm. The repeating local notification stays scheduled until explicitly stopped in-app (or disabled by the user/system). Continuous background location uses additional battery; pause lookout when unnecessary.

References: [Apple background location](https://developer.apple.com/documentation/corelocation/handling-location-updates-in-the-background), [location authorization](https://developer.apple.com/documentation/corelocation/requesting-authorization-to-use-location-services), [time interval notification triggers](https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger).

## Architecture

- `StayDetector.swift`: deterministic dwell/departure state machine and Codable models.
- `AppModel.swift`: persisted app state, Core Location delegate, region monitoring, notifications, and explicit cancellation.
- `DontForgetMeApp.swift`: onboarding, home, item editor, checklist, settings, original vector mascot.
- `scripts/make-icon.swift`: reproducible AppKit icon artwork.

No location data leaves the device. Only the current anchor is retained, not a route history. Persistence uses the app’s local UserDefaults container; deleting the app deletes its data.

## Verification

```sh
xcodebuild test -project DontForgetMe.xcodeproj -scheme DontForgetMe \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build -resultBundlePath verification/Run.xcresult \
  CODE_SIGNING_ALLOWED=NO
```

Unit tests cover the 20-minute boundary, short stays, location noise/staleness, region exits, restored state, optional checklist completion, and empty item lists. The UI journey adds an item, restarts the app, injects a 21-minute stay and departure through the production detector, verifies a real OS repeating notification after 65 seconds in the background, restores the unfinished checklist, and explicitly cancels pending notifications.

Debug builds include a **Simulate 21-minute stay & leave** action in Settings. This injects coordinates and time; it does not require waiting 21 minutes or walking. Release builds exclude this developer UI. `--ui-testing --reset` gives UI automation an isolated starting state and disables real GPS callbacks during the scenario.

See `verification/REPORT.md` for actual results and physical-device acceptance steps. Simulator tests do not prove locked-phone GPS behavior on a real walk.
