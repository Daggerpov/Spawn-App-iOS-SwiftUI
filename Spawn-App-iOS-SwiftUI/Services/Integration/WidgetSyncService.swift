import Foundation
import WidgetKit

@MainActor
enum WidgetSyncService {
    static func update(_ activities: [FullFeedActivityDTO], userId: UUID) {
        let auth = UserAuthViewModel.shared
        guard auth.isLoggedIn, auth.spawnUser?.id == userId else { return }
        let now = Date()
        let items = activities.filter { $0.isExpired != true }.map { activity in
            var calendar = Calendar.current
            calendar.timeZone = activity.clientTimezone.flatMap(TimeZone.init(identifier:)) ?? .current
            let start = activity.startTime ?? activity.createdAt ?? now
            let midnight = calendar.date(byAdding: .day, value: 1,
                                         to: calendar.startOfDay(for: activity.createdAt ?? start)) ?? start
            let title = activity.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return WidgetActivity(
                id: activity.id,
                title: title.isEmpty ? "Activity" : title,
                icon: activity.icon ?? "✨",
                location: activity.location?.name ?? "Location to come",
                start: start,
                expires: activity.endTime ?? midnight,
                people: Set((activity.participantUsers ?? []).map(\.id) + [activity.creatorUser.id]).count
            )
        }.filter { $0.expires > now }.sorted { $0.start < $1.start }
        let snapshot = WidgetSnapshot(updatedAt: now, isSignedIn: true, activities: Array(items.prefix(20)))
        let previous = WidgetSnapshotStore.read()
        guard previous.activities != snapshot.activities || !previous.isSignedIn ||
                now.timeIntervalSince(previous.updatedAt) > 3600 else { return }
        if WidgetSnapshotStore.write(snapshot) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotStore.kind)
        }
    }

    static func clear() {
        if WidgetSnapshotStore.write(.signedOut) {
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshotStore.kind)
        }
    }
}
