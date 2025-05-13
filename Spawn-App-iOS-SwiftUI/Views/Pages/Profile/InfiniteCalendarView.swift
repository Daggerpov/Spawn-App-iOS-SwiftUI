import SwiftUI

// Expanded calendar view that shows all months in a year
struct InfiniteCalendarView: View {
    let activities: [CalendarActivityDTO]
    let isLoading: Bool
    let onDismiss: () -> Void
    let onEventSelected: (CalendarActivityDTO) -> Void
    
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var currentMonth: Int = Calendar.current.component(.month, from: Date())
    
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
                                        onEventSelected: onEventSelected
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
                                    DayCell(activities: dayActivities, onEventSelected: onEventSelected)
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
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                .frame(height: 32)
            
            if activities.count <= 4 {
                // Show up to 4 icons
                let columns = [
                    GridItem(.flexible(), spacing: 1),
                    GridItem(.flexible(), spacing: 1)
                ]
                
                LazyVGrid(columns: columns, spacing: 1) {
                    ForEach(activities.prefix(4), id: \.id) { activity in
                        activityIcon(for: activity)
                            .foregroundColor(.white)
                            .frame(width: 12, height: 12)
                            .padding(2)
                            .background(activityColor(for: activity))
                            .clipShape(Circle())
                            .onTapGesture {
                                onEventSelected(activity)
                            }
                    }
                }
                .padding(2)
            } else {
                // Show 3 icons + overflow indicator
                let displayedActivities = Array(activities.prefix(3))
                
                ZStack(alignment: .bottomTrailing) {
                    // First 3 events
                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            ForEach(0..<min(2, displayedActivities.count), id: \.self) { index in
                                activityIcon(for: displayedActivities[index])
                                    .foregroundColor(.white)
                                    .frame(width: 12, height: 12)
                                    .padding(2)
                                    .background(activityColor(for: displayedActivities[index]))
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        onEventSelected(displayedActivities[index])
                                    }
                            }
                        }
                        
                        HStack(spacing: 1) {
                            if displayedActivities.count > 2 {
                                activityIcon(for: displayedActivities[2])
                                    .foregroundColor(.white)
                                    .frame(width: 12, height: 12)
                                    .padding(2)
                                    .background(activityColor(for: displayedActivities[2]))
                                    .clipShape(Circle())
                                    .onTapGesture {
                                        onEventSelected(displayedActivities[2])
                                    }
                            }
                            
                            // Overflow indicator
                            Text("+\(activities.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                                .frame(width: 16, height: 16)
                                .background(Color.gray)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(2)
            }
        }
        .onTapGesture {
            if !activities.isEmpty {
                // If we have activities, open the first one when tapping on the cell background
                onEventSelected(activities[0])
            }
        }
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
                    .font(.system(size: 10))
            } else {
                // Fallback to system icon from the EventCategory enum
                Image(systemName: activity.eventCategory?.systemIcon() ?? "circle.fill")
                    .font(.system(size: 8))
            }
        }
    }
} 