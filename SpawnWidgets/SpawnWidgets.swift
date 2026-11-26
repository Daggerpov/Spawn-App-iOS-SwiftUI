import SwiftUI
import WidgetKit

struct PlansEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct PlansProvider: TimelineProvider {
    func placeholder(in context: Context) -> PlansEntry { sample }

    func getSnapshot(in context: Context, completion: @escaping (PlansEntry) -> Void) {
        completion(context.isPreview ? sample : PlansEntry(date: Date(), snapshot: WidgetSnapshotStore.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PlansEntry>) -> Void) {
        let now = Date()
        let snapshot = WidgetSnapshotStore.read()
        let refresh = now.addingTimeInterval(900)
        // Schedule exact start/end transitions even while the app is closed.
        let transitions = snapshot.activities.flatMap { [$0.start, $0.expires] } +
            [snapshot.updatedAt.addingTimeInterval(86_400)]
        let dates = Set(transitions.filter { $0 > now && $0 < refresh }).sorted()
        let entries = ([now] + dates).map { PlansEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private var sample: PlansEntry {
        let now = Date()
        let items = [
            WidgetActivity(id: UUID(), title: "Coffee & a catch-up", icon: "☕️", location: "The neighbourhood café",
                           start: now.addingTimeInterval(1800), expires: now.addingTimeInterval(5400), people: 4),
            WidgetActivity(id: UUID(), title: "Sunset walk", icon: "🌅", location: "By the waterfront",
                           start: now.addingTimeInterval(7200), expires: now.addingTimeInterval(10800), people: 3),
            WidgetActivity(id: UUID(), title: "Dinner with the crew", icon: "🍜", location: "Your favourite spot",
                           start: now.addingTimeInterval(14400), expires: now.addingTimeInterval(18000), people: 6)
        ]
        return PlansEntry(date: now, snapshot: WidgetSnapshot(updatedAt: now, isSignedIn: true, activities: items))
    }
}

struct SpawnPlansView: View {
    let entry: PlansEntry
    @Environment(\.widgetFamily) private var family
    private let ink = Color(red: 0.17, green: 0.13, blue: 0.25)
    private let accent = Color(red: 0.36, green: 0.40, blue: 0.93)
    private var activities: [WidgetActivity] { entry.snapshot.visibleActivities(at: entry.date) }
    private var isSmall: Bool { family == .systemSmall }
    private var isStale: Bool { entry.date.timeIntervalSince(entry.snapshot.updatedAt) >= 86_400 }
    private var destination: URL {
        if let activity = activities.first { return activity.url }
        return entry.snapshot.isSignedIn && !isStale ? WidgetSnapshotStore.createURL : WidgetSnapshotStore.homeURL
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 10 : 14) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles").foregroundStyle(accent)
                    Text("spawn").font(.system(.headline, design: .rounded, weight: .heavy))
                }
                Spacer(minLength: 2)
                if !isSmall {
                    Text(entry.date, format: .dateTime.weekday(.abbreviated).day())
                        .font(.caption.weight(.medium)).foregroundStyle(ink.opacity(0.65))
                }
            }
            if !entry.snapshot.isSignedIn {
                message("Your people. Your plans.", detail: "Open Spawn to sign in", symbol: "person.2.fill")
            } else if isStale {
                message("Catch up on plans", detail: "Open Spawn to refresh", symbol: "arrow.clockwise")
            } else if let first = activities.first {
                if isSmall {
                    smallActivity(first)
                } else {
                    ForEach(Array(activities.prefix(family == .systemLarge ? 3 : 1))) { activity in
                        Link(destination: activity.url) { activityRow(activity) }
                    }
                    Spacer(minLength: 0)
                    createLink
                }
            } else {
                message("Room for something good.", detail: "Make a plan with your friends", symbol: "sun.max.fill")
                if !isSmall { createLink }
            }
        }
        .foregroundStyle(ink)
        .widgetURL(destination)
        .containerBackground(for: .widget) {
            LinearGradient(colors: [Color(red: 0.96, green: 0.97, blue: 1), Color(red: 0.86, green: 0.89, blue: 1)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private func smallActivity(_ activity: WidgetActivity) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(activity.icon).font(.title2)
                Spacer()
                timeLabel(activity).font(.caption2.bold())
            }
            Text(activity.title).font(.system(.headline, design: .rounded)).lineLimit(2)
            Text(activity.location).font(.caption).foregroundStyle(ink.opacity(0.65)).lineLimit(1)
        }
        .privacySensitive()
    }

    private func activityRow(_ activity: WidgetActivity) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(activity.icon).font(.system(size: 29))
                .frame(width: 52, height: 56)
                .background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 4) {
                timeLabel(activity).font(.caption.bold()).foregroundStyle(accent)
                Text(activity.title).font(.system(.headline, design: .rounded)).lineLimit(1)
                HStack(spacing: 8) {
                    Label(activity.location, systemImage: "mappin").lineLimit(1)
                    Label("\(activity.people)", systemImage: "person.2.fill").fixedSize()
                }.font(.caption2).foregroundStyle(ink.opacity(0.65))
            }
            Spacer(minLength: 0)
        }
        .privacySensitive()
    }

    @ViewBuilder
    private func timeLabel(_ activity: WidgetActivity) -> some View {
        if activity.start <= entry.date {
            Text("HAPPENING NOW")
        } else if Calendar.current.isDate(activity.start, inSameDayAs: entry.date) {
            Text(activity.start, format: .dateTime.hour().minute())
        } else {
            Text(activity.start, format: .dateTime.weekday(.abbreviated).hour().minute())
        }
    }

    private var createLink: some View {
        Link(destination: WidgetSnapshotStore.createURL) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Make a plan").fontWeight(.semibold)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption.bold())
            }
            .font(.subheadline).foregroundStyle(accent)
            .padding(.top, 2)
        }
    }

    private func message(_ title: String, detail: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: symbol).foregroundStyle(accent).font(.title3)
            Text(title).font(.system(isSmall ? .headline : .title3, design: .rounded, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(detail).font(.caption).foregroundStyle(ink.opacity(0.65))
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

@main
struct SpawnPlansWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshotStore.kind, provider: PlansProvider()) { entry in
            SpawnPlansView(entry: entry)
        }
        .configurationDisplayName("Plans with your people")
        .description("See what’s coming up and make your next plan.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    SpawnPlansWidget()
} timeline: {
    PlansEntry(date: Date(), snapshot: .signedOut)
}
