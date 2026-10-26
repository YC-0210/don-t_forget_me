# Verification report

Completed 2026-10-27 (Asia/Taipei).

## Results

- **9 tests passed, 0 failed, 0 skipped:** eight XCTest logic tests and one XCUITest end-to-end journey.
- Simulator: **iPhone 17 Pro, iOS 26.3.1**, arm64. Xcode 26.2.
- End-to-end journey: **113.9 seconds**, including an actual 65-second wait with the app backgrounded.
- **Release build for generic physical iOS device succeeded**, signing disabled. Privacy manifest and icon included; developer simulation controls excluded.
- Reviewed exported onboarding, home, item management, departure checklist, completed checklist, and cancellation screenshots. Checklist stop button remains pinned while content scrolls.

## Verified end to end

1. Fresh onboarding and system notification permission grant.
2. Add Headphones; verify the item survives terminating and relaunching the app.
3. Inject a 21-minute stay and departure through the production location detector and reminder pipeline.
4. Confirm the system has a **repeating 60-second notification trigger**.
5. Background the app for 65 seconds; confirm the OS delivered the repeating request.
6. Check Student ID, terminate, relaunch; confirm the same checklist and checked state return.
7. Check remaining items and stop reminders in-app.
8. Confirm **zero pending reminder notifications** and no active checklist after another relaunch.

Logic tests also cover the exact 20-minute boundary, short stays, inaccurate/stale/out-of-order fixes, restored stay anchors, deduplicated region departures, empty lists, incomplete completion, and awarding exactly one star for a completed checklist.

## Evidence

- `test-summary.json`: exported machine-readable Xcode test summary.
- `FinalRun.xcresult`: full local test bundle (excluded from Git because of size).
- `final-run.log` and `release-build.log`: local build/test logs (excluded from Git).
- `final-screenshots/`: six exported screenshots and attachment manifest.

Initial runs caught an unauthorized-notification test setup and an onboarding-transition race in automation. The final run includes their fixes and passes the actual delivery assertion; no tests were skipped.

## Coverage boundary

The location timeline is injected to avoid waiting 21 minutes. Notification scheduling, background delivery, UI interaction, persistence, and cancellation use actual iOS simulator services. **A real locked-phone walk has not been tested.** A signed iPhone installation and the procedure in `DEVICE-CHECKLIST.md` are necessary to evaluate GPS/geofence latency, permission upgrades, indoor drift, power consumption, and system suspension. Device/App Store signing is not configured.
