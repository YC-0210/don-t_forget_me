# Traditional Chinese verification / 繁體中文版測試

Verified 2026-10-27, Xcode 26.2, iPhone 17 Pro simulator running iOS 26.3.1.

**13 tests passed, 0 failed, 0 skipped.** Release build for generic iOS device also succeeded with signing disabled.

- 8 existing stay-detection and checklist logic tests passed.
- 3 localization tests verify translation-key coverage, Chinese app name and location explanations, migration of the original saved default trio without changing item IDs/checkmarks, and preservation of custom names including Chinese text.
- 2 complete UI journeys ran in English (`en_US`) and Traditional Chinese (`zh_TW`). Each verifies onboarding, custom item persistence, simulated 21-minute stay/departure, actual repeating OS notification delivery after 65 seconds in the background, checklist restoration, explicit stop, and zero pending reminders.
- The Chinese journey additionally asserts 學生證／水壺／鑰匙 and checks the actual delivered notification body contains `學生證、水壺、鑰匙、Headphones`. The custom item remains verbatim.
- Reviewed Chinese onboarding, home, and departure screenshots: Chinese text renders properly, the layout accommodates translated copy, and the stop button stays visible.
- Checked the compiled Release app includes `zh-Hant.lproj/InfoPlist.strings` with translated app name and both location permission explanations.

Evidence: `localization-test-summary.json`, `localized-screenshots/` (English and Chinese, six screenshots each). Full local result: `TraditionalChineseValidated.xcresult`; logs: `traditional-chinese-validated.log` and `traditional-chinese-release.log` (large/generated files excluded from Git).

Language follows the iPhone/app language preference. Existing custom item names remain unchanged. The original saved default trio is recognized conservatively by name, symbol, and original order; other legacy names are retained rather than guessed. Already-scheduled notifications retain the language used when they were created; subsequent reminder sessions use the selected app language.

The same coverage boundary applies: stay time/coordinates are injected, while notification scheduling and delivery use simulator services. Physical locked-phone GPS behavior, battery use, and device signing remain outside this simulator verification.
