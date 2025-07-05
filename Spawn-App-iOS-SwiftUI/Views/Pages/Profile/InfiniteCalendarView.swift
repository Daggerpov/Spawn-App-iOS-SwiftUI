import SwiftUI

// Expanded calendar view that shows all months in a year
struct InfiniteCalendarView: View {
    let activities: [CalendarActivityDTO]
    let isLoading: Bool
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @State private var currentDate = Date()
    @State private var showingDayActivities: Bool = false
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with month/year and navigation
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentDate = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(universalAccentColor)
                }
                
                Spacer()
                
                Text(DateFormatter.monthYear.string(from: currentDate))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentDate = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(universalAccentColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                CalendarGridView(
                    currentDate: currentDate,
                    activities: activities,
                    onActivitySelected: onActivitySelected,
                    onDateSelected: { date in
                        selectedDate = date
                        // Show day activities if there are activities for this date
                        if !getActivitiesForDate(date).isEmpty {
                            self.showingDayActivities = true
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingDayActivities) {
            NavigationView {
                DayActivitiesView(
                    date: selectedDate,
                    onDismiss: { showingDayActivities = false },
                    onActivitySelected: { activity in
                        showingDayActivities = false
                        onActivitySelected(activity)
                    }
                )
            }
        }
    }
    
    private func getActivitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
        return activities.filter { activity in
            Calendar.current.isDate(activity.date, inSameDayAs: date)
        }
    }
}

// Empty state view for when no activities are found
struct EmptyCalendarView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Activities Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("When you create or participate in activities, they'll appear here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// Calendar grid view
struct CalendarGridView: View {
    let currentDate: Date
    let activities: [CalendarActivityDTO]
    let onActivitySelected: (CalendarActivityDTO) -> Void
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    private var monthDays: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysToSubtract = firstWeekday - 1
        
        guard let startDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: firstOfMonth) else {
            return []
        }
        
        var days: [Date] = []
        for i in 0..<42 { // 6 weeks * 7 days
            if let day = calendar.date(byAdding: .day, value: i, to: startDate) {
                days.append(day)
            }
        }
        return days
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            // Weekday headers
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .frame(height: 30)
            }
            
            // Calendar days
            ForEach(monthDays, id: \.self) { date in
                CalendarDayView(
                    date: date,
                    currentDate: currentDate,
                    activities: activitiesForDate(date),
                    onActivitySelected: onActivitySelected,
                    onDateSelected: onDateSelected
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func activitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
        return activities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }
}

// Cell representing a single day with one or more activities
struct CalendarDayView: View {
    let date: Date
    let currentDate: Date
    let activities: [CalendarActivityDTO]
    let onActivitySelected: (CalendarActivityDTO) -> Void
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    
    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: currentDate, toGranularity: .month)
    }
    
    private var isToday: Bool {
        calendar.isDate(date, inSameDayAs: Date())
    }
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(dayNumber)
                .font(.system(size: 16, weight: isToday ? .bold : .medium))
                .foregroundColor(isCurrentMonth ? (isToday ? .white : .primary) : .secondary)
            
            if activities.count == 1 {
                // Single activity - show as a colored circle
                if let activityId = activities[0].activityId {
                    Circle()
                        .fill(getActivityColor(for: activityId))
                        .frame(width: 8, height: 8)
                }
            } else if activities.count > 1 {
                // Multiple activities - show as dots
                HStack(spacing: 2) {
                    ForEach(activities.prefix(3), id: \.id) { activity in
                        Circle()
                            .fill(activity.activityId != nil ? getActivityColor(for: activity.activityId!) : .gray)
                            .frame(width: 4, height: 4)
                    }
                    if activities.count > 3 {
                        Text("+")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(width: 40, height: 40)
        .background(
            Circle()
                .fill(isToday ? universalAccentColor : Color.clear)
        )
        .onTapGesture {
            if activities.count == 1 {
                onActivitySelected(activities[0])
            } else if activities.count > 1 {
                // If multiple activities, show the day activities list
                onDateSelected(date)
            }
        }
    }
}

// Extension for activity category icon
extension CalendarActivityDTO {
    var categoryIcon: String {
        return activityCategory?.systemIcon() ?? "circle.fill"
    }
}

// Date formatter extension
extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
}

@available(iOS 17.0, *)
#Preview {
    InfiniteCalendarView(
        activities: [],
        isLoading: false,
        onDismiss: {},
        onActivitySelected: { _ in }
    )
} 
