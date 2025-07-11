import SwiftUI

// Expanded calendar view that shows all months in a year
struct InfiniteCalendarView: View {
    let activities: [CalendarActivityDTO]
    let isLoading: Bool
    let userCreationDate: Date?
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @State private var currentDate = Date()
    @State private var showingDayActivities: Bool = false
    @State private var selectedDayActivities: [CalendarActivityDTO] = []
    
    private let calendar = Calendar.current
    private let today = Date()
    
    // Calculate the earliest date to show in the calendar
    private var earliestDate: Date {
        guard let userCreationDate = userCreationDate else {
            // If no user creation date, go back 2 years as default
            return calendar.date(byAdding: .year, value: -2, to: today) ?? today
        }
        return userCreationDate
    }
    
    // Generate months for infinite scrolling - respecting user creation date
    private var monthsData: [MonthData] {
        var months: [MonthData] = []
        
        // Calculate how many months back we can go from today to the earliest date
        let monthsFromEarliestToToday = calendar.dateComponents([.month], from: earliestDate, to: today).month ?? 0
        let maxMonthsBack = max(0, monthsFromEarliestToToday) // Ensure we don't go negative
        
        // Go back to the earliest date and forward 1 month
        let startIndex = -maxMonthsBack
        let endIndex = 1
        
        for i in startIndex...endIndex {
            if let date = calendar.date(byAdding: .month, value: i, to: today) {
                // Only include dates that are not before the user's creation date
                if date >= earliestDate {
                    months.append(MonthData(date: date, activities: activitiesForMonth(date)))
                }
            }
        }
        
        return months
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                infiniteScrollCalendar
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Your Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showingDayActivities) {
            DayActivitiesPageView(
                date: selectedDayActivities.first?.date ?? Date(),
                activities: selectedDayActivities,
                onDismiss: { showingDayActivities = false },
                onActivitySelected: { activity in
                    showingDayActivities = false
                    onActivitySelected(activity)
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var infiniteScrollCalendar: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(monthsData, id: \.id) { monthData in
                        MonthView(
                            monthData: monthData,
                            today: today,
                            onDayTapped: { activities in
                                if activities.count == 1 {
                                    onActivitySelected(activities.first!)
                                } else if activities.count > 1 {
                                    selectedDayActivities = activities
                                    showingDayActivities = true
                                }
                            }
                        )
                        .id(monthData.id)
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    // Find the current month and scroll to it
                    if let todayMonthData = monthsData.first(where: { monthData in
                        calendar.isDate(monthData.date, equalTo: today, toGranularity: .month)
                    }) {
                        // Scroll to current month with animation after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo(todayMonthData.id, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func activitiesForMonth(_ date: Date) -> [CalendarActivityDTO] {
        return activities.filter { activity in
            calendar.isDate(activity.date, equalTo: date, toGranularity: .month)
        }
    }
}

// Data structure for each month
struct MonthData: Identifiable {
    let id = UUID()
    let date: Date
    let activities: [CalendarActivityDTO]
}

// Month view component
struct MonthView: View {
    let monthData: MonthData
    let today: Date
    let onDayTapped: ([CalendarActivityDTO]) -> Void
    
    private let calendar = Calendar.current
    
    // Get all days in the month
    private var daysInMonth: [Date] {
		guard let _ = calendar.dateInterval(of: .month, for: monthData.date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: monthData.date)) else {
            return []
        }
        
        let numberOfDays = calendar.range(of: .day, in: .month, for: monthData.date)?.count ?? 30
        var days: [Date] = []
        
        for day in 1...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header
            HStack {
                Text(DateFormatter.monthYear.string(from: monthData.date))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Days grid (4 columns)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(
                        date: date,
                        activities: activitiesForDate(date),
                        isToday: calendar.isDate(date, inSameDayAs: today),
                        onTapped: {
                            let dayActivities = activitiesForDate(date)
                            if !dayActivities.isEmpty {
                                onDayTapped(dayActivities)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func activitiesForDate(_ date: Date) -> [CalendarActivityDTO] {
        return monthData.activities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
    }
}

// Individual day cell
struct DayCell: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let isToday: Bool
    let onTapped: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayNumber: String {
        String(calendar.component(.day, from: date))
    }
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 4) {
                // Date number at the top
                HStack {
                    Spacer()
                    Text(dayNumber)
                        .font(.custom("SF Pro Text", size: 14).weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.8))
                        )
                }
                .padding(.top, 4)
                .padding(.trailing, 4)
                
                // Activity display
                if activities.isEmpty {
                    Spacer()
                        .frame(minHeight: 32)
                } else if activities.count == 1 {
                    // Single activity - show its icon
                    activityIconView(for: activities.first!)
                        .frame(width: 32, height: 32)
                } else {
                    // Multiple activities - show count or multiple icons
                    multipleActivitiesView
                        .frame(width: 32, height: 32)
                }
                
                Spacer()
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(activities.isEmpty ? figmaCalendarDayIcon : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isToday ? universalAccentColor : Color.clear, lineWidth: 3)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func activityIconView(for activity: CalendarActivityDTO) -> some View {
        ZStack {
            // Background color based on activity
            RoundedRectangle(cornerRadius: 8)
                .fill(activityColor(for: activity))
                .frame(width: 32, height: 32)
            
            // Activity icon
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            } else {
                Text("⭐️")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
    }
    

    
    @ViewBuilder
    private var multipleActivitiesView: some View {
        if activities.count <= 3 {
            // Show up to 3 activity icons as small dots
            HStack(spacing: 2) {
                ForEach(activities.prefix(3), id: \.id) { activity in
                    Circle()
                        .fill(activityColor(for: activity))
                        .frame(width: 8, height: 8)
                }
            }
        } else {
            // Show count for more than 3 activities
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: activities.prefix(3).map { activityColor(for: $0) }),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 32, height: 32)
                
                Text("\(activities.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    private func activityColor(for activity: CalendarActivityDTO) -> Color {
        // Use custom color if available
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise use activity color based on ID
        if let activityId = activity.activityId {
            return getActivityColor(for: activityId)
        }
        
        return .gray
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
        userCreationDate: nil,
        onDismiss: {},
        onActivitySelected: { _ in }
    )
} 
