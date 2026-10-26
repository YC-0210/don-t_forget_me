import XCTest
import CoreLocation
import UserNotifications
@testable import DontForgetMe

final class StayDetectorTests: XCTestCase {
    let start = Date()
    func fix(_ seconds: Double, latitude: Double = 25, accuracy: Double = 10) -> CLLocation {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: 121), altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: 10, timestamp: start.addingTimeInterval(seconds))
    }
    func testTwentyMinuteDepartureAndNoDuplicate() {
        var detector = StayDetector()
        XCTAssertFalse(detector.ingest(fix(0), now: start))
        XCTAssertFalse(detector.ingest(fix(1199), now: start.addingTimeInterval(1199)))
        XCTAssertTrue(detector.ingest(fix(1200, latitude: 25.004), now: start.addingTimeInterval(1200)))
        XCTAssertFalse(detector.ingest(fix(1205, latitude: 25.004), now: start.addingTimeInterval(1205)))
    }
    func testShortStayDoesNotAlertAndResetsAnchor() {
        var detector = StayDetector()
        _ = detector.ingest(fix(0), now: start)
        XCTAssertFalse(detector.ingest(fix(1199, latitude: 25.004), now: start.addingTimeInterval(1199)))
        XCTAssertEqual(detector.stay?.arrived, start.addingTimeInterval(1199))
    }
    func testNoiseAndStaleFixesDoNotCreateDepartures() {
        var detector = StayDetector()
        _ = detector.ingest(fix(0), now: start)
        XCTAssertFalse(detector.ingest(fix(1300, latitude: 26, accuracy: 100), now: start.addingTimeInterval(1300)))
        XCTAssertFalse(detector.ingest(fix(1300, latitude: 26), now: start.addingTimeInterval(1500)))
        XCTAssertFalse(detector.ingest(fix(1300, latitude: 25.001), now: start.addingTimeInterval(1300)))
        XCTAssertEqual(detector.stay?.latitude, 25)
    }
    func testRegionExitAndPersistedAnchor() throws {
        var detector = StayDetector()
        _ = detector.ingest(fix(0), now: start)
        let data = try JSONEncoder().encode(detector.stay)
        var restored = StayDetector(stay: try JSONDecoder().decode(Stay.self, from: data))
        XCTAssertTrue(restored.exit(now: start.addingTimeInterval(1201)))
        XCTAssertFalse(restored.exit(now: start.addingTimeInterval(1202)))
    }
    @MainActor func testChecklistPersistsAndStopsWithoutAwardingIncompleteCheck() async throws {
        let defaults = UserDefaults(suiteName: "test-\(UUID())")!
        let model = AppModel(defaults: defaults)
        model.state.items[2].enabled = false
        model.state.reminder = Reminder(items: model.state.items.filter(\.enabled))
        model.save()
        XCTAssertEqual(model.state.reminder?.items.count, 2)
        let id = try XCTUnwrap(model.state.reminder?.items.first?.id)
        model.toggleCheck(id)
        let restored = AppModel(defaults: defaults)
        XCTAssertTrue(restored.state.reminder?.checked.contains(id) == true)
        model.stopReminder()
        await model.refreshPending()
        XCTAssertEqual(model.pendingCount, 0)
        XCTAssertNil(model.state.reminder)
        XCTAssertEqual(model.state.successfulChecks, 0)
    }
    func testOutOfOrderAndInvalidAccuracyIgnored() {
        var detector = StayDetector()
        _ = detector.ingest(fix(10), now: start.addingTimeInterval(10))
        XCTAssertFalse(detector.ingest(fix(5, latitude: 26), now: start.addingTimeInterval(10)))
        XCTAssertFalse(detector.ingest(fix(1300, latitude: 26, accuracy: -1), now: start.addingTimeInterval(1300)))
        XCTAssertEqual(detector.stay?.arrived, start.addingTimeInterval(10))
    }
    @MainActor func testCompletedChecklistEarnsOneStarAndStopIsIdempotent() {
        let model = AppModel(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        model.state.reminder = Reminder(items: model.state.items, checked: Set(model.state.items.map(\.id)))
        model.stopReminder()
        model.stopReminder()
        XCTAssertEqual(model.state.successfulChecks, 1)
    }
    @MainActor func testEmptyListDoesNotCreateReminder() {
        let model = AppModel(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        model.state.items = []
        model.beginReminder()
        XCTAssertNil(model.state.reminder)
    }
}
