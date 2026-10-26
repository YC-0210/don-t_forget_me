import XCTest

final class JourneyTests: XCTestCase {
    @MainActor func testFullJourney() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--reset"]
        app.launch()
        XCTAssertTrue(app.buttons["getStarted"].waitForExistence(timeout: 10))
        capture(app, "01-Welcome")
        app.buttons["getStarted"].tap()
        XCTAssertTrue(app.tabBars.buttons["My things"].waitForExistence(timeout: 5))
        if app.buttons["enableNotifications"].exists {
            app.buttons["enableNotifications"].tap()
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let allow = springboard.buttons["Allow"]
            if allow.waitForExistence(timeout: 4) { allow.tap() }
        }
        capture(app, "02-Today")
        app.tabBars.buttons["My things"].tap()
        app.buttons["addThing"].tap()
        app.textFields["itemName"].tap()
        app.textFields["itemName"].typeText("Headphones")
        app.buttons["saveThing"].tap()
        XCTAssertTrue(app.switches["Headphones"].waitForExistence(timeout: 3))
        capture(app, "03-My-things")
        app.terminate()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        app.tabBars.buttons["My things"].tap()
        XCTAssertTrue(app.switches["Headphones"].exists)
        app.tabBars.buttons["Settings"].tap()
        for _ in 0..<5 where !app.buttons["simulateDeparture"].isHittable { app.swipeUp() }
        app.buttons["simulateDeparture"].tap()
        XCTAssertTrue(app.buttons["check-Student ID"].waitForExistence(timeout: 5))
        capture(app, "04-Departure-checklist")
        XCTAssertTrue(app.staticTexts["Repeat interval: 60s"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        let interval = expectation(description: "Actual repeating notification fires in background")
        DispatchQueue.global().asyncAfter(deadline: .now() + 65) { interval.fulfill() }
        wait(for: [interval], timeout: 70)
        app.activate()
        XCTAssertTrue(app.staticTexts["Delivered repeats: 1"].waitForExistence(timeout: 5))
        app.buttons["check-Student ID"].tap()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["check-Student ID"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["check-Student ID"].value as? String, "Packed")
        app.buttons["check-Water bottle"].tap()
        app.swipeUp()
        app.buttons["check-Keys"].tap()
        app.buttons["check-Headphones"].tap()
        capture(app, "05-Packed")
        app.buttons["stopReminders"].tap()
        XCTAssertTrue(app.tabBars.buttons["Settings"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Settings"].tap()
        for _ in 0..<5 where !app.buttons["Refresh notification status"].isHittable { app.swipeUp() }
        app.buttons["Refresh notification status"].tap()
        XCTAssertTrue(app.staticTexts["Pending reminders: 0"].waitForExistence(timeout: 5))
        capture(app, "06-Canceled-notifications")
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
