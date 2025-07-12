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
                date: selectedDayActivities.first?.dateAsDate ?? Date(),
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
            calendar.isDate(activity.dateAsDate, equalTo: date, toGranularity: .month)
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
            calendar.isDate(activity.dateAsDate, inSameDayAs: date)
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
    
    private var activityBackgroundColor: Color {
        if let firstActivity = activities.first {
            return activityColor(for: firstActivity)
        }
        return Color.gray.opacity(0.05)
    }
    
    var body: some View {
        Button(action: onTapped) {
            ZStack {
                // Main calendar cell background
                RoundedRectangle(cornerRadius: 12)
                    .fill(activities.isEmpty ? figmaCalendarDayIcon : activityBackgroundColor)
                    .frame(width: 86, height: 86)
                    .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? universalAccentColor : Color.clear, lineWidth: 2)
                    )
                
                // Activity display (centered)
                if !activities.isEmpty {
                    if activities.count == 1 {
                        // Single activity - show its icon
                        activityIconView(for: activities.first!)
                    } else {
                        // Multiple activities - show count or multiple icons
                        multipleActivitiesView
                    }
                }
                
                // Date number badge (positioned in top-right corner)
                VStack {
                    HStack {
                        Spacer()
                        Text(dayNumber)
                            .font(.onestMedium(size: 12))
                            .foregroundColor(.black)
                            .padding(6)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .padding(.top, 6)
                    .padding(.trailing, 6)
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    @ViewBuilder
    private func activityIconView(for activity: CalendarActivityDTO) -> some View {
        // Activity icon (centered in the cell, no background since cell has the color)
        if let icon = activity.icon, !icon.isEmpty {
            Text(icon)
                .font(.custom("Onest", size: 40).weight(.medium))
                .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
        } else {
            Text("⭐️")
                .font(.custom("Onest", size: 40).weight(.medium))
                .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
        }
    }
    

    
    @ViewBuilder
    private var multipleActivitiesView: some View {
        if activities.count == 2 {
            // Show 2 icons side by side (matching Figma design)
            HStack(spacing: -5) {
                ForEach(activities.prefix(2), id: \.id) { activity in
                    if let icon = activity.icon, !icon.isEmpty {
                        Text(icon)
                            .font(.custom("Onest", size: 30).weight(.medium))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    } else {
                        Text("⭐️")
                            .font(.custom("Onest", size: 30).weight(.medium))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    }
                }
            }
        } else {
            // For 3+ activities, show the first icon larger
            if let firstActivity = activities.first, let icon = firstActivity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.custom("Onest", size: 40).weight(.medium))
                    .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
            } else {
                Text("⭐️")
                    .font(.custom("Onest", size: 40).weight(.medium))
                    .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
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
