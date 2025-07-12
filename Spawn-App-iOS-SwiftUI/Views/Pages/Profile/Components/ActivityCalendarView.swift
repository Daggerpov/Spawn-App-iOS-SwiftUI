//
//  ActivityCalendarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct ActivityCalendarView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @StateObject var userAuth = UserAuthViewModel.shared
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    let userCreationDate: Date?
    let calendarOwnerName: String?
    
    @State private var currentMonth = Date()
    @State private var scrollOffset: CGFloat = 0
    @State private var hasInitiallyScrolled = false
    @State private var showingDayActivities = false
    @State private var selectedDayActivities: [CalendarActivityDTO] = []
    
    var onDismiss: (() -> Void)?
    
    var body: some View {
        ZStack {
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Scrollable calendar content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 32) {
                            ForEach(monthsArray, id: \.self) { month in
                                MonthCalendarView(
                                    month: month,
                                    profileViewModel: profileViewModel,
                                    userAuth: userAuth
                                )
                                .id(month)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Safe area padding
                        .onAppear {
                            // Only scroll to current month on first appearance
                            guard !hasInitiallyScrolled else { return }
                            
                            // Find the current month and scroll to it
                            let today = Date()
                            if let currentMonth = monthsArray.first(where: { month in
                                Calendar.current.isDate(month, equalTo: today, toGranularity: .month)
                            }) {
                                // Scroll to current month immediately on first appearance
                                // Use a small delay to ensure the scroll view has loaded
                                DispatchQueue.main.async {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        proxy.scrollTo(currentMonth, anchor: .center)
                                    }
                                    hasInitiallyScrolled = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(calendarOwnerName != nil ? "\(calendarOwnerName!)'s Activity Calendar" : "Your Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingDayActivities) {
            DayActivitiesPageView(
                date: selectedDayActivities.first?.dateAsDate ?? Date(),
                activities: selectedDayActivities,
                onDismiss: { showingDayActivities = false },
                onActivitySelected: { activity in
                    showingDayActivities = false
                    handleActivitySelection(activity)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Fetch calendar data for current and upcoming months
            fetchCalendarData()
        }
        .onDisappear {
            // Reset navigation state when leaving the calendar view
            // This prevents the NavigationLink from getting stuck in active state
            onDismiss?()
        }
    }
    
    private var monthsArray: [Date] {
        let calendar = Calendar.current
        let today = Date()
        var months: [Date] = []
        
        // Calculate the earliest date to show in the calendar
        let earliestDate: Date
        if let userCreationDate = userCreationDate {
            earliestDate = userCreationDate
        } else {
            // If no user creation date, go back 2 years as default
            earliestDate = calendar.date(byAdding: .year, value: -2, to: today) ?? today
        }
        
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
                    months.append(date)
                }
            }
        }
        
        return months
    }
    
    private func fetchCalendarData() {
        Task {
            await profileViewModel.fetchAllCalendarActivities()
        }
    }
    
    private func handleActivitySelection(_ activity: CalendarActivityDTO) {
        Task {
            if let activityId = activity.activityId,
               let _ = await profileViewModel.fetchActivityDetails(activityId: activityId) {
                await MainActor.run {
                    // Activity details will be shown via the existing sheet in the calling view
                }
            }
        }
    }
}

struct MonthCalendarView: View {
    let month: Date
    @StateObject var profileViewModel: ProfileViewModel
    @StateObject var userAuth: UserAuthViewModel
    
    @State private var showActivityDetails = false
    @State private var selectedActivity: CalendarActivityDTO?
    @State private var showingDayActivities = false
    @State private var selectedDayActivities: [CalendarActivityDTO] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header
            Text(monthYearString())
                .font(.onestMedium(size: 16))
                .foregroundColor(figmaBlack300)
                .padding(.leading, 4)
            
            // Calendar grid - 4 days per row
            VStack(spacing: 12) {
                ForEach(0..<numberOfRows, id: \.self) { rowIndex in
                    HStack(spacing: 12) {
                        ForEach(0..<4, id: \.self) { dayIndex in
                            let dayOffset = rowIndex * 4 + dayIndex
                            let day = dayForOffset(dayOffset)
                            
                            CalendarDayTile(
                                day: day,
                                activities: getActivitiesForDay(day),
                                isCurrentMonth: isCurrentMonth(day),
                                onDayTapped: { activities in
                                    if activities.count == 1 {
                                        selectedActivity = activities.first!
                                        showActivityDetails = true
                                    } else if activities.count > 1 {
                                        selectedDayActivities = activities
                                        showingDayActivities = true
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .sheet(isPresented: $showActivityDetails) {
            if let activity = selectedActivity {
                ActivityDetailsSheet(activity: activity, userAuth: userAuth)
            }
        }
        .sheet(isPresented: $showingDayActivities) {
            DayActivitiesPageView(
                date: selectedDayActivities.first?.dateAsDate ?? Date(),
                activities: selectedDayActivities,
                onDismiss: { showingDayActivities = false },
                onActivitySelected: { activity in
                    showingDayActivities = false
                    selectedActivity = activity
                    showActivityDetails = true
                }
            )
            .presentationDetents([.medium, .large])
        }
    }
    
    private var numberOfRows: Int {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<32
        let daysInMonth = range.count
        
        // Calculate number of rows needed for 4 days per row
        return Int(ceil(Double(daysInMonth) / 4.0))
    }
    
    private func dayForOffset(_ offset: Int) -> Date {
        let calendar = Calendar.current
        let firstOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        
        return calendar.date(byAdding: .day, value: offset, to: firstOfMonth) ?? firstOfMonth
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: month, toGranularity: .month)
    }
    
    private func getActivitiesForDay(_ date: Date) -> [CalendarActivityDTO] {
        // Create a UTC calendar for consistent date comparison
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        let filteredActivities = profileViewModel.allCalendarActivities.filter { activity in
            // Use UTC calendar for consistent date comparison since backend sends UTC dates
            utcCalendar.isDate(activity.dateAsDate, inSameDayAs: date)
        }
        
        // Add debug logging for this view as well
        if !filteredActivities.isEmpty {
            print("📅 ActivityCalendarView: Day \(Calendar.current.component(.day, from: date)) has \(filteredActivities.count) activities")
        }
        
        return filteredActivities
    }
    
    private func monthYearString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month)
    }
}

struct CalendarDayTile: View {
    let day: Date
    let activities: [CalendarActivityDTO]
    let isCurrentMonth: Bool
    let onDayTapped: ([CalendarActivityDTO]) -> Void
    
    private let tileSize: CGFloat = 86.4
    private let cornerRadius: CGFloat = 12.34
    
    private var dayNumber: String {
        String(Calendar.current.component(.day, from: day))
    }
    
    var body: some View {
        ZStack {
            if isCurrentMonth {
                // Background rectangle
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(activityBackgroundColor)
                    .frame(width: tileSize, height: tileSize)
                    .shadow(color: Color.black.opacity(0.1), radius: 12.34, x: 0, y: 3.09)
                    .overlay(
                        // Blue border overlay for current day
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .inset(by: 1)
                            .stroke(isToday ? figmaBlue : Color.clear, lineWidth: 2)
                    )
                    .overlay(
                        // Activity content
                        VStack(spacing: 4) {
                            if activities.count == 1 {
                                // Single activity emoji
                                activityEmoji(for: activities[0])
                                    .font(.onestMedium(size: 49.37))
                                    .foregroundColor(figmaBlack300)
                            } else if activities.count > 1 {
                                // Multiple activities - show first two emojis
                                HStack(spacing: 2) {
                                    activityEmoji(for: activities[0])
                                        .font(.onestMedium(size: 37.03))
                                        .foregroundColor(figmaBlack300)
                                    
                                    if activities.count > 1 {
                                        activityEmoji(for: activities[1])
                                            .font(.onestMedium(size: 37.03))
                                            .foregroundColor(figmaBlack300)
                                    }
                                }
                            }
                        }
                    )
                    .overlay(
                        // Date number badge (positioned in top-right corner)
                        VStack {
                            HStack {
                                Spacer()
                                Text(dayNumber)
                                    .font(.onestMedium(size: 10))
                                    .foregroundColor(.black)
                                    .padding(4)
                                    .background(Color.white.opacity(0.9))
                                    .clipShape(Circle())
                            }
                            .padding(.top, 4)
                            .padding(.trailing, 4)
                            Spacer()
                        }
                    )
                    .onTapGesture {
                        if !activities.isEmpty {
                            onDayTapped(activities)
                        }
                    }
                

            } else {
                // Days outside current month - invisible
                Color.clear
                    .frame(width: tileSize, height: tileSize)
            }
        }
        .frame(width: tileSize, height: tileSize)
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(day, inSameDayAs: Date())
    }
    
    private var activityBackgroundColor: Color {
        if isToday {
            return Color(hex: "#848484")
        } else if activities.isEmpty {
            return figmaCalendarDayIcon
        } else {
            return Color.white
        }
    }
    
    private func activityEmoji(for activity: CalendarActivityDTO) -> some View {
        Group {
            if let icon = activity.icon, !icon.isEmpty {
                Text(icon)
            } else {
                Text("⭐️")
            }
        }
    }
}

struct ActivityDetailsSheet: View {
    let activity: CalendarActivityDTO
    @StateObject var userAuth: UserAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Activity header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Activity")
                            .font(.onestSemiBold(size: 24))
                            .foregroundColor(universalAccentColor)
                        
                        Text(DateFormatter.dayMonthYear.string(from: activity.dateAsDate))
                            .font(.onestMedium(size: 16))
                            .foregroundColor(figmaBlack300)
                    }
                    
                    Spacer()
                    
                    // Activity icon
                    if let icon = activity.icon, !icon.isEmpty {
                        Text(icon)
                            .font(.onestMedium(size: 40))
                    } else {
                        Text("⭐️")
                            .font(.onestMedium(size: 40))
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal, 20)
                
                // Activity details
                VStack(alignment: .leading, spacing: 16) {
                    if let activityId = activity.activityId {
                        Text("Activity ID: \(activityId.uuidString)")
                            .font(.onestMedium(size: 14))
                            .foregroundColor(figmaBlack300)
                    }
                    
                    if let colorHex = activity.colorHexCode {
                        HStack {
                            Text("Color:")
                                .font(.onestMedium(size: 14))
                                .foregroundColor(figmaBlack300)
                            
                            Circle()
                                .fill(Color(hex: colorHex))
                                .frame(width: 20, height: 20)
                            
                            Text(colorHex)
                                .font(.onestMedium(size: 14))
                                .foregroundColor(figmaBlack300)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Close")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(universalAccentColor)
                        .cornerRadius(universalRectangleCornerRadius)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
        }
    }
}

extension DateFormatter {
    static let dayMonthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
}

#Preview {
    ActivityCalendarView(
        profileViewModel: ProfileViewModel(userId: UUID()),
        userCreationDate: nil,
        calendarOwnerName: nil,
        onDismiss: {}
    )
} 