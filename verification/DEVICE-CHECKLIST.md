# Physical iPhone acceptance check (not yet performed)

Use a signed build on an iPhone. Simulator clock/coordinate injection tests the app pipeline, not the radio, GPS environment, or iOS background wake decisions.

1. Fresh installation: complete onboarding, allow notifications and While Using location, upgrade to Always, enable Precise Location and Background App Refresh, and start lookout.
2. Remain in the same place for at least 21 minutes with the app backgrounded and phone locked. Walk at least 200–250 meters away. Record when the first alert appears; GPS/region delivery can be delayed.
3. Leave the alert alone for two minutes. Confirm subsequent notifications arrive. Open the app without pressing Stop, background it, and confirm another reminder arrives.
4. Open the checklist, check items, then press All packed. Confirm no further alerts arrive over two minutes and the badge clears.
5. Repeat a stay shorter than 20 minutes. Depart; no reminder should appear.
6. Deny notifications and location separately. Confirm settings show the missing permission. Restore permissions and confirm normal behavior resumes.
7. Pause lookout. Confirm no new location-driven reminder is created. If a checklist was already active, confirm it remains active until explicitly stopped.
8. Test in a dense indoor area and outdoors; record false or late departures, battery usage, and accuracy. Tune the 150-meter radius only after collecting real device observations.
9. Repeat on the oldest supported iOS release available, with large Dynamic Type and VoiceOver enabled. The current simulator evidence covers iOS 26.3 only.

Force-quitting, Focus, disabled location services, disabled Background App Refresh, and system battery controls are known delivery constraints; this app cannot override them.
