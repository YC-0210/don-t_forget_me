import XCTest

final class JourneyTests: XCTestCase {
    @MainActor func testFullJourney() throws { try runJourney(chinese: false) }
    @MainActor func testTraditionalChineseJourney() throws { try runJourney(chinese: true) }
    @MainActor private func runJourney(chinese: Bool) throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        let language = ["-AppleLanguages", chinese ? "(zh-Hant)" : "(en)", "-AppleLocale", chinese ? "zh_TW" : "en_US"]
        let things = chinese ? "我的物品" : "My things"
        let settings = chinese ? "設定" : "Settings"
        let refresh = chinese ? "更新通知狀態" : "Refresh notification status"
        app.launchArguments = ["--ui-testing", "--reset"] + language
        app.launch()
        XCTAssertTrue(app.buttons["getStarted"].waitForExistence(timeout: 10))
        capture(app, (chinese ? "zh-Hant-" : "en-") + "01-Welcome")
        app.buttons["getStarted"].tap()
        XCTAssertTrue(app.tabBars.buttons[things].waitForExistence(timeout: 5))
        if app.buttons["enableNotifications"].exists {
            app.buttons["enableNotifications"].tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: 4) { allow.tap() }
        }
        capture(app, (chinese ? "zh-Hant-" : "en-") + "02-Today")
        app.tabBars.buttons[things].tap()
        if chinese {
            XCTAssertTrue(app.switches["學生證"].exists)
            XCTAssertTrue(app.switches["水壺"].exists)
            XCTAssertTrue(app.switches["鑰匙"].exists)
        }
        app.buttons["addThing"].tap()
        app.textFields["itemName"].tap()
        app.textFields["itemName"].typeText("Headphones")
        app.buttons["saveThing"].tap()
        XCTAssertTrue(app.switches["Headphones"].waitForExistence(timeout: 3))
        capture(app, (chinese ? "zh-Hant-" : "en-") + "03-My-things")
        app.terminate()
        app.launchArguments = ["--ui-testing"] + language
        app.launch()
        app.tabBars.buttons[things].tap()
        XCTAssertTrue(app.switches["Headphones"].exists)
        app.tabBars.buttons[settings].tap()
        for _ in 0..<5 where !app.buttons["simulateDeparture"].isHittable { app.swipeUp() }
        app.buttons["simulateDeparture"].tap()
        XCTAssertTrue(app.buttons["check-Student ID"].waitForExistence(timeout: 5))
        capture(app, (chinese ? "zh-Hant-" : "en-") + "04-Departure-checklist")
        XCTAssertTrue(app.staticTexts[chinese ? "重複間隔：60 秒" : "Repeat interval: 60s"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        let interval = expectation(description: "Actual repeating notification fires in background")
        DispatchQueue.global().asyncAfter(deadline: .now() + 65) { interval.fulfill() }
        wait(for: [interval], timeout: 70)
        app.activate()
        XCTAssertTrue(app.staticTexts[chinese ? "已送達的重複提醒：1" : "Delivered repeats: 1"].waitForExistence(timeout: 5))
        if chinese {
            XCTAssertTrue(app.staticTexts["notificationPreview"].label.contains("學生證、水壺、鑰匙、Headphones"))
        }
        app.buttons["check-Student ID"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["check-Student ID"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["check-Student ID"].value as? String, chinese ? "已帶齊" : "Packed")
        app.buttons["check-Water bottle"].tap()
        app.swipeUp()
        app.buttons["check-Keys"].tap()
        app.buttons["check-Headphones"].tap()
        capture(app, (chinese ? "zh-Hant-" : "en-") + "05-Packed")
        app.buttons["stopReminders"].tap()
        XCTAssertTrue(app.tabBars.buttons[settings].waitForExistence(timeout: 5))
        app.tabBars.buttons[settings].tap()
        for _ in 0..<5 where !app.buttons[refresh].isHittable { app.swipeUp() }
        app.buttons[refresh].tap()
        XCTAssertTrue(app.staticTexts[chinese ? "待送出的提醒：0" : "Pending reminders: 0"].waitForExistence(timeout: 5))
        capture(app, (chinese ? "zh-Hant-" : "en-") + "06-Canceled-notifications")
        app.terminate()
        app.launch()
        XCTAssertFalse(app.buttons["stopReminders"].exists)
    }
    @MainActor func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
