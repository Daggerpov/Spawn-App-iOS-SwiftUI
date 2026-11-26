import Foundation

/// The widget receives display data only. Authentication stays in the containing app.
struct WidgetActivity: Codable, Equatable, Identifiable {
    let id: UUID
    let title: String
    let icon: String
    let location: String
    let start: Date
    let expires: Date
    let people: Int

    var url: URL { URL(string: "spawn://widget-activity/\(id.uuidString)")! }
}

struct WidgetSnapshot: Codable, Equatable {
    let updatedAt: Date
    let isSignedIn: Bool
    let activities: [WidgetActivity]

    static let signedOut = WidgetSnapshot(updatedAt: .distantPast, isSignedIn: false, activities: [])

    func visibleActivities(at date: Date) -> [WidgetActivity] {
        guard isSignedIn, date.timeIntervalSince(updatedAt) < 86_400 else { return [] }
        return activities.filter { $0.expires > date }.sorted { $0.start < $1.start }
    }
}

enum WidgetSnapshotStore {
    static let group = "group.danielagapov.Spawn-App-iOS-SwiftUI"
    static let kind = "SpawnPlansWidget"
    static let createURL = URL(string: "spawn://create")!
    static let homeURL = URL(string: "spawn://home")!

    private static var fileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?
            .appendingPathComponent("widget-snapshot.json")
    }

    static func read() -> WidgetSnapshot {
        guard let url = fileURL, let data = try? Data(contentsOf: url),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .signedOut
        }
        return snapshot
    }

    @discardableResult
    static func write(_ snapshot: WidgetSnapshot) -> Bool {
        guard let url = fileURL, let data = try? JSONEncoder().encode(snapshot) else { return false }
        do {
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            return true
        } catch {
            return false
        }
    }
}
