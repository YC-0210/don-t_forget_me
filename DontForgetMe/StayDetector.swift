import Foundation
import CoreLocation

struct Stay: Codable, Equatable {
    var latitude: Double
    var longitude: Double
    var arrived: Date
    var lastSeen: Date
}

/// A single local anchor, not a location history. Poor/stale fixes never change it.
struct StayDetector {
    static let dwell: TimeInterval = 20 * 60
    static let radius: CLLocationDistance = 150
    var stay: Stay?

    mutating func ingest(_ location: CLLocation, now: Date = Date()) -> Bool {
        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 65,
              abs(location.timestamp.timeIntervalSince(now)) < 90 else { return false }
        guard let old = stay else { seed(location); return false }
        guard location.timestamp >= old.lastSeen else { return false }
        let distance = location.distance(from: CLLocation(latitude: old.latitude, longitude: old.longitude))
        if distance > Self.radius + location.horizontalAccuracy {
            let qualifies = location.timestamp.timeIntervalSince(old.arrived) >= Self.dwell
            seed(location)
            return qualifies
        }
        // Uncertain boundary fixes do not move the anchor.
        stay?.lastSeen = location.timestamp
        return false
    }

    mutating func exit(now: Date) -> Bool {
        guard let old = stay else { return false }
        stay = nil
        return now.timeIntervalSince(old.arrived) >= Self.dwell
    }

    private mutating func seed(_ location: CLLocation) {
        stay = Stay(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
                    arrived: location.timestamp, lastSeen: location.timestamp)
    }
}

struct Belonging: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var symbol: String
    var enabled = true
    var localizationKey: String? = nil
    var displayName: String { localizationKey.map { L10n.text($0) } ?? name }
    static let defaults = [Belonging(name: "Student ID", symbol: "person.text.rectangle.fill", localizationKey: "item.studentID"),
                           Belonging(name: "Water bottle", symbol: "waterbottle.fill", localizationKey: "item.waterBottle"),
                           Belonging(name: "Keys", symbol: "key.fill", localizationKey: "item.keys")]
}

struct Reminder: Codable {
    var items: [Belonging]
    var checked: Set<UUID> = []
    var started = Date()
}

struct SavedState: Codable {
    var onboarded = false
    var monitoring = false
    var items = Belonging.defaults
    var stay: Stay?
    var reminder: Reminder?
    var successfulChecks = 0

    mutating func migrateLegacyDefaultNames() {
        let templates = Belonging.defaults
        guard items.count >= templates.count,
              zip(items.prefix(3), templates).allSatisfy({ $0.name == $1.name && $0.symbol == $1.symbol }) else { return }
        for index in 0..<3 {
            let id = items[index].id
            items[index].localizationKey = templates[index].localizationKey
            if let reminderIndex = reminder?.items.firstIndex(where: { $0.id == id }) {
                reminder?.items[reminderIndex].localizationKey = templates[index].localizationKey
            }
        }
    }
}
