import SwiftUI

// Expanded calendar view that shows all months in a year
struct InfiniteCalendarView: View {
    let activities: [CalendarActivityDTO]
    let isLoading: Bool
    let onDismiss: () -> Void
    let onEventSelected: (CalendarActivityDTO) -> Void
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedDayActivities: [CalendarActivityDTO]?
    @State private var showingDayEvents: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if activities.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No calendar activities")
                            .font(.headline)
                        
                        Text("When you create or participate in events, they'll appear here.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Year picker
                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears(), id: \.self) { year in
                            Text("\(year)").tag(year)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Calendar content
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            LazyVStack(spacing: 30) {
                                ForEach(1...12, id: \.self) { month in
                                    MonthCalendarView(
                                        month: month,
                                        year: selectedYear,
                                        activities: activitiesForMonth(month: month, year: selectedYear),
                                        onEventSelected: onEventSelected,
                                        onDaySelected: { dayActivities in
                                            self.selectedDayActivities = dayActivities
                                            self.showingDayEvents = true
                                        }
                                    )
                                    .id("month-\(month)")
                                }
                            }
                            .padding()
                        }
                        .onAppear {
                            // Scroll to current month when view appears
                            scrollProxy.scrollTo("month-\(currentMonth)", anchor: .top)
                        }
                        .onChange(of: selectedYear) { _ in
                            // Maintain scroll position at current month when year changes
                            scrollProxy.scrollTo("month-\(currentMonth)", anchor: .top)
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDayEvents) {
                if let activities = selectedDayActivities {
                    DayEventsView(
                        activities: activities,
                        onDismiss: { showingDayEvents = false },
                        onEventSelected: { activity in
                            showingDayEvents = false
                            onEventSelected(activity)
                        }
                    )
                }
            }
        }
    }
    
    private func availableYears() -> [Int] {
        // Determine the range of years from activities
        if activities.isEmpty {
            // Default to current year if no activities
            return [Calendar.current.component(.year, from: Date())]
        }
        
        var years = Set<Int>()
        
        for activity in activities {
            let year = Calendar.current.component(.year, from: activity.date)
                years.insert(year)
        }
        
        // If no valid years found, use current year
        if years.isEmpty {
            return [Calendar.current.component(.year, from: Date())]
        }
        
        // Return sorted years
        return Array(years).sorted()
    }
    
    private func activitiesForMonth(month: Int, year: Int) -> [CalendarActivityDTO] {
        return activities.filter { activity in
            let activityMonth = Calendar.current.component(.month, from: activity.date)
            let activityYear = Calendar.current.component(.year, from: activity.date)
            return activityMonth == month && activityYear == year
        }
    }
}

// Individual month view in the calendar
struct MonthCalendarView: View {
    let month: Int
    let year: Int
    let activities: [CalendarActivityDTO]
    let onEventSelected: (CalendarActivityDTO) -> Void
    let onDaySelected: ([CalendarActivityDTO]) -> Void
    
    private var monthName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let date = Calendar.current.date(from: DateComponents(year: year, month: month))!
        return dateFormatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthName)
                .font(.headline)
                .padding(.leading, 8)
            
            // Days of week header
            HStack(spacing: 0) {
                ForEach(Array(zip(0..<7, ["S", "M", "T", "W", "T", "F", "S"])), id: \.0) { index, day in
                    Text(day)
                        .font(.caption2)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.gray)
                }
            }
            
            // Calendar grid
            let calendarGrid = createCalendarGrid()
            VStack(spacing: 6) {
                ForEach(0..<calendarGrid.count, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<7, id: \.self) { col in
                            if let dayActivities = calendarGrid[row][col] {
                                if dayActivities.isEmpty {
                                    // Empty day cell
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 32)
                                } else {
                                    // Cell with activities
                                    DayCell(
                                        activities: dayActivities, 
                                        onEventSelected: onEventSelected,
                                        onDaySelected: onDaySelected
                                    )
                                }
                            } else {
                                // Null cell (outside month)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 32)
                            }
                        }
                    }
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    private func createCalendarGrid() -> [[[CalendarActivityDTO]?]] {
        var grid = Array(
            repeating: Array(repeating: nil as [CalendarActivityDTO]?, count: 7),
            count: 6 // Use 6 rows to accommodate months that span 6 weeks
        )
        
        let firstDayOffset = firstDayOfMonth(month: month, year: year)
        let daysInMonth = self.daysInMonth(month: month, year: year)
        
        // Group activities by day
        var activitiesByDay: [Int: [CalendarActivityDTO]] = [:]
        for activity in activities {
            let day = Calendar.current.component(.day, from: activity.date)
            if activitiesByDay[day] == nil {
                activitiesByDay[day] = []
            }
            activitiesByDay[day]?.append(activity)
        }
        
        // Initialize all days in month with empty arrays
        for day in 1...daysInMonth {
            let position = day + firstDayOffset - 1
            let row = position / 7
            let col = position % 7
            
            if row < grid.count {
                grid[row][col] = activitiesByDay[day] ?? []
            }
        }
        
        return grid
    }
    
    private func firstDayOfMonth(month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let weekday = calendar.component(.weekday, from: date)
            // Convert from 1-7 (Sunday-Saturday) to 0-6 for our grid
            return weekday - 1
        }
        return 0
    }
    
    private func daysInMonth(month: Int, year: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        
        if let date = calendar.date(from: components),
           let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 30 // Default fallback
    }
}

// Cell representing a single day with one or more events
struct DayCell: View {
    let activities: [CalendarActivityDTO]
    let onEventSelected: (CalendarActivityDTO) -> Void
    let onDaySelected: ([CalendarActivityDTO]) -> Void
    
    private var gradientColors: [Color] {
        // Get up to 3 unique colors from activities
        let colors = activities.prefix(3).compactMap { activity -> Color? in
            if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
                return Color(hex: colorHex)
            } else if let category = activity.eventCategory {
                return category.color()
            }
            return nil
        }
        
        // If no colors found, return default gray
        if colors.isEmpty {
            return [Color.gray.opacity(0.5)]
        }
        
        // If only one color, use it with different opacity
        if colors.count == 1 {
            return [colors[0].opacity(0.7), colors[0].opacity(0.9)]
        }
        
        return colors
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(height: 32)
            
            if activities.count <= 4 {
                // Show up to 4 icons in a grid
                let columns = [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1)
                ]
                
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(activities.prefix(4), id: \.id) { activity in
                        activityIcon(for: activity)
                            .foregroundColor(.white)
                            .font(.system(size: 10))
                    }
                }
                .padding(2)
            } else {
                // Show 3 icons + overflow indicator
                HStack(spacing: 2) {
                    ForEach(0..<2, id: \.self) { index in
                        if index < activities.count {
                            activityIcon(for: activities[index])
                                .foregroundColor(.white)
                                .font(.system(size: 10))
                        }
                    }
                    
                    Text("+\(activities.count - 2)")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
        .onTapGesture {
            if activities.count == 1 {
                // If only one activity, directly open it
                onEventSelected(activities[0])
            } else if activities.count > 1 {
                // If multiple activities, show the day events list
                onDaySelected(activities)
            }
        }
    }
    
    private func activityIcon(for activity: CalendarActivityDTO) -> some View {
        Group {
            // If we have an icon from the backend, use it directly
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 10))
            } else {
                // Fallback to system icon from the EventCategory enum
                Image(systemName: activity.eventCategory?.systemIcon() ?? "circle.fill")
                    .font(.system(size: 10))
            }
        }
    }
}

// Card-like view for activities in the day events sheet
struct EventDayCard: View {
    let activity: CalendarActivityDTO
    
    var body: some View {
        HStack {
            activityIcon(for: activity)
                .font(.title3)
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let time = activity.formattedTime {
                    Text(time)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    activityColor(for: activity).opacity(0.8),
                    activityColor(for: activity)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
    
    private func activityColor(for activity: CalendarActivityDTO) -> Color {
        // First check if activity has a custom color hex code
        if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
            return Color(hex: colorHexCode)
        }
        
        // Fallback to category color
        guard let category = activity.eventCategory else {
            return Color.gray.opacity(0.6) // Default color for null category
        }
        return category.color()
    }
    
    private func activityIcon(for activity: CalendarActivityDTO) -> some View {
        Group {
            // If we have an icon from the backend, use it directly
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
                    .font(.system(size: 16))
            } else {
                // Fallback to system icon from the EventCategory enum
                Image(systemName: activity.eventCategory?.systemIcon() ?? "circle.fill")
                    .font(.system(size: 16))
            }
        }
        .foregroundColor(.white)
    }
} 