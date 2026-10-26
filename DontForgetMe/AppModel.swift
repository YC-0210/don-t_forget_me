import SwiftUI
import CoreLocation
import UserNotifications

@MainActor
final class AppModel: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    @Published var state: SavedState
    @Published var locationStatus: CLAuthorizationStatus = .notDetermined
    @Published var notificationAllowed = false
    @Published var precise = true
    @Published var issue: String?
    @Published var pendingCount = 0
    @Published var deliveredRepeatCount = 0
    @Published var repeatInterval = 0
    @Published var deliveredReminderBody = ""
    let manager = CLLocationManager()
    let center = UNUserNotificationCenter.current()
    let defaults: UserDefaults
    private var detector = StayDetector()
    private var notificationRevision = 0
    private var regionID: String?
    static let notificationIDs = ["belongings-now", "belongings-repeat"]
    var isUITest: Bool { ProcessInfo.processInfo.arguments.contains("--ui-testing") }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if ProcessInfo.processInfo.arguments.contains("--reset") { defaults.removeObject(forKey: "state") }
        state = (defaults.data(forKey: "state").flatMap { try? JSONDecoder().decode(SavedState.self, from: $0) }) ?? SavedState()
        super.init()
        state.migrateLegacyDefaultNames()
        save()
        detector.stay = state.stay
        manager.delegate = self
        center.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        manager.distanceFilter = 25
        manager.pausesLocationUpdatesAutomatically = false
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        locationStatus = manager.authorizationStatus
        refreshPermissions()
        if state.monitoring { startServices() }
    }

    func save() { defaults.set(try? JSONEncoder().encode(state), forKey: "state") }
    func finishOnboarding() { state.onboarded = true; save() }
    func requestNotifications() async {
        if await center.notificationSettings().authorizationStatus == .denied { openSettings(); return }
        do { notificationAllowed = try await center.requestAuthorization(options: [.alert, .sound, .badge]) }
        catch { issue = L10n.text("Notifications couldn't be enabled. Try again in Settings.") }
        if state.reminder != nil { await scheduleReminder() }
    }
    func requestLocation() {
        if locationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        else if locationStatus == .authorizedWhenInUse { manager.requestAlwaysAuthorization() }
        else if locationStatus == .denied || locationStatus == .restricted { openSettings() }
    }
    func openSettings() { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
    func refreshPermissions() {
        locationStatus = manager.authorizationStatus
        precise = manager.accuracyAuthorization == .fullAccuracy
        Task {
            let settings = await center.notificationSettings()
            notificationAllowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            await refreshPending()
            if notificationAllowed && state.reminder != nil && repeatInterval == 0 { await scheduleReminder() }
        }
    }
    var canLocate: Bool { locationStatus == .authorizedAlways || locationStatus == .authorizedWhenInUse }
    func setMonitoring(_ enabled: Bool) {
        if enabled && !canLocate { requestLocation(); return }
        state.monitoring = enabled
        if enabled { startServices() }
        else {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            for region in manager.monitoredRegions { manager.stopMonitoring(for: region) }
            regionID = nil
            detector.stay = nil
            state.stay = nil
        }
        save()
    }
    private func startServices() {
        guard canLocate else { return }
        manager.startUpdatingLocation()
        manager.startMonitoringSignificantLocationChanges()
        syncRegion()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationStatus = manager.authorizationStatus
        precise = manager.accuracyAuthorization == .fullAccuracy
        if state.monitoring && canLocate { startServices() }
        if !canLocate {
            manager.stopUpdatingLocation()
            manager.stopMonitoringSignificantLocationChanges()
            for region in manager.monitoredRegions { manager.stopMonitoring(for: region) }
            regionID = nil
            detector.stay = nil
            state.stay = nil
            save()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard state.monitoring, !isUITest else { return }
        for location in locations { process(location) }
    }
    func process(_ location: CLLocation, now: Date = Date()) {
        let left = detector.ingest(location, now: now)
        state.stay = detector.stay
        save()
        syncRegion()
        if left { beginReminder() }
    }
    private func syncRegion() {
        guard let stay = detector.stay, CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self), !isUITest else { return }
        let id = "stay-\(stay.arrived.timeIntervalSince1970)"
        guard id != regionID else { return }
        for region in manager.monitoredRegions { manager.stopMonitoring(for: region) }
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: stay.latitude, longitude: stay.longitude), radius: StayDetector.radius, identifier: id)
        region.notifyOnEntry = false
        region.notifyOnExit = true
        regionID = id
        manager.startMonitoring(for: region)
    }
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard state.monitoring, region.identifier == regionID else { return }
        let left = detector.exit(now: Date())
        manager.stopMonitoring(for: region)
        regionID = nil
        state.stay = nil
        save()
        if left { beginReminder() }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as? CLError)?.code != .locationUnknown { issue = L10n.text("Location is unavailable. Check your location permissions and try again.") }
    }
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        issue = L10n.text("Place monitoring is unavailable. Location updates will still be used while available.")
        regionID = nil
    }
    func beginReminder() {
        guard state.reminder == nil else { return }
        let items = state.items.filter(\.enabled)
        guard !items.isEmpty else { return }
        state.reminder = Reminder(items: items)
        save()
        Task { await scheduleReminder() }
    }
    func scheduleReminder() async {
        guard let reminder = state.reminder else { return }
        notificationRevision += 1
        let revision = notificationRevision
        let content = UNMutableNotificationContent()
        content.title = L10n.text("Wait! Got your things? 🎒")
        content.body = L10n.format("%@. Open your checklist to stop reminders.", reminder.items.map(\.displayName).joined(separator: L10n.text(", ")))
        content.sound = .default
        content.badge = 1
        content.threadIdentifier = "belongings"
        do {
            for (id, interval, repeats) in [(Self.notificationIDs[0], 1.0, false), (Self.notificationIDs[1], 60.0, true)] {
                guard revision == notificationRevision, state.reminder != nil else { return }
                try await center.add(UNNotificationRequest(identifier: id, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: repeats)))
                if state.reminder == nil { center.removePendingNotificationRequests(withIdentifiers: Self.notificationIDs); return }
            }
        } catch { issue = L10n.text("Your checklist is ready, but notifications couldn't be scheduled. Enable them in Settings.") }
        await refreshPending()
    }
    func toggleCheck(_ id: UUID) {
        if state.reminder?.checked.contains(id) == true { state.reminder?.checked.remove(id) }
        else { state.reminder?.checked.insert(id) }
        save()
    }
    func stopReminder() {
        if let reminder = state.reminder, reminder.checked.count == reminder.items.count { state.successfulChecks += 1 }
        state.reminder = nil
        notificationRevision += 1
        save()
        center.removePendingNotificationRequests(withIdentifiers: Self.notificationIDs)
        center.removeDeliveredNotifications(withIdentifiers: Self.notificationIDs)
        Task { try? await center.setBadgeCount(0); await refreshPending() }
    }
    func refreshPending() async {
        let requests = await center.pendingNotificationRequests().filter { Self.notificationIDs.contains($0.identifier) }
        pendingCount = requests.count
        let trigger = requests.first { $0.identifier == "belongings-repeat" }?.trigger as? UNTimeIntervalNotificationTrigger
        repeatInterval = trigger?.repeats == true ? Int(trigger!.timeInterval) : 0
        let delivered = await center.deliveredNotifications().filter { $0.request.identifier == "belongings-repeat" }
        deliveredRepeatCount = delivered.count
        deliveredReminderBody = delivered.first?.request.content.body ?? ""
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions { [.banner, .sound, .badge] }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async { }

    /// Debug-only UI drives the same detector and notification pipeline, with an injected clock.
    func simulateStayAndDeparture() {
        #if DEBUG
        detector.stay = nil
        let start = Date().addingTimeInterval(-21 * 60)
        let arrival = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 25.033, longitude: 121.5654), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: start)
        process(arrival, now: start)
        let departure = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 25.037, longitude: 121.5654), altitude: 0, horizontalAccuracy: 10, verticalAccuracy: 10, timestamp: Date())
        process(departure)
        #endif
    }
}
