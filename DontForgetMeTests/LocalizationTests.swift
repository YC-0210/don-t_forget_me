import XCTest
@testable import DontForgetMe

final class LocalizationTests: XCTestCase {
    func testTraditionalChineseResourcesAndPermissions() throws {
        let app = Bundle(for: AppModel.self)
        let folder = try XCTUnwrap(app.path(forResource: "zh-Hant", ofType: "lproj"))
        let chinese = try XCTUnwrap(Bundle(path: folder))
        XCTAssertEqual(L10n.text("item.studentID", bundle: chinese), "學生證")
        XCTAssertEqual(L10n.text("STOP REMINDERS", bundle: chinese), "停止提醒")
        XCTAssertEqual(chinese.localizedString(forKey: "CFBundleDisplayName", value: nil, table: "InfoPlist"), "別忘了帶我走")
        XCTAssertTrue(chinese.localizedString(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription", value: nil, table: "InfoPlist").contains("鎖定"))
        let enPath = try XCTUnwrap(app.path(forResource: "Localizable", ofType: "strings", inDirectory: "en.lproj"))
        let zhPath = try XCTUnwrap(app.path(forResource: "Localizable", ofType: "strings", inDirectory: "zh-Hant.lproj"))
        let english = try XCTUnwrap(NSDictionary(contentsOfFile: enPath) as? [String: String])
        let translated = try XCTUnwrap(NSDictionary(contentsOfFile: zhPath) as? [String: String])
        XCTAssertEqual(Set(english.keys), Set(translated.keys))
        for (key, value) in translated { XCTAssertFalse(value.isEmpty, key) }
    }
    func testLegacyDefaultsMigrateWithoutChangingUserItemsOrIDs() throws {
        var state = SavedState()
        state.items = Belonging.defaults.map { var item = $0; item.localizationKey = nil; return item }
        state.items.append(Belonging(name: "我的雨傘 ☔️", symbol: "umbrella.fill"))
        let ids = state.items.map(\.id)
        state.reminder = Reminder(items: state.items, checked: [ids[0]])
        let oldData = try JSONEncoder().encode(state)
        var restored = try JSONDecoder().decode(SavedState.self, from: oldData)
        restored.migrateLegacyDefaultNames()
        XCTAssertEqual(restored.items.map(\.id), ids)
        XCTAssertEqual(restored.items[0].localizationKey, "item.studentID")
        XCTAssertEqual(restored.items[3].displayName, "我的雨傘 ☔️")
        XCTAssertNil(restored.items[3].localizationKey)
        XCTAssertEqual(restored.reminder?.items[0].localizationKey, "item.studentID")
        XCTAssertTrue(restored.reminder?.checked.contains(ids[0]) == true)
    }
    func testNewCustomNamesAreNotTranslated() {
        XCTAssertEqual(Belonging(name: "Student ID", symbol: "bag.fill").displayName, "Student ID")
        XCTAssertEqual(Belonging(name: "隨身杯", symbol: "waterbottle.fill").displayName, "隨身杯")
    }
}
