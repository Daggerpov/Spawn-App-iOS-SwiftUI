//
//  EventCalendarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

struct EventCalendarView: View {
    @StateObject var profileViewModel: ProfileViewModel
    @StateObject var userAuth = UserAuthViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentMonth = Date()
    @State private var scrollOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation header
                HStack(spacing: 32) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.onestSemiBold(size: 20))
                            .foregroundColor(figmaBlack300)
                    }
                    
                    Spacer()
                    
                    Text("Your Event Calendar")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Image(systemName: "chevron.left")
                        .font(.onestSemiBold(size: 20))
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Scrollable calendar content
                ScrollView {
                    LazyVStack(spacing: 32) {
                        ForEach(monthsArray, id: \.self) { month in
                            MonthCalendarView(
                                month: month,
                                profileViewModel: profileViewModel,
                                userAuth: userAuth
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Safe area padding
                }
            }
        }
        .onAppear {
            // Fetch calendar data for current and upcoming months
            fetchCalendarData()
        }
    }
    
    private var monthsArray: [Date] {
        let calendar = Calendar.current
        let currentDate = Date()
        var months: [Date] = []
        
        // Generate 12 months starting from current month
        for i in 0..<12 {
            if let month = calendar.date(byAdding: .month, value: i, to: currentDate) {
                months.append(month)
            }
        }
        
        return months
    }
    
    private func fetchCalendarData() {
        Task {
            await profileViewModel.fetchAllCalendarActivities()
        }
    }
}

struct MonthCalendarView: View {
    let month: Date
    @StateObject var profileViewModel: ProfileViewModel
    @StateObject var userAuth: UserAuthViewModel
    
    @State private var showActivityDetails = false
    @State private var selectedActivity: CalendarActivityDTO?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Month header
            Text(monthYearString())
                .font(.onestMedium(size: 16))
                .foregroundColor(figmaBlack300)
                .padding(.leading, 4)
            
            // Calendar grid
            VStack(spacing: 12) {
                ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                    HStack(spacing: 12) {
                        ForEach(0..<7, id: \.self) { dayIndex in
                            let dayOffset = weekIndex * 7 + dayIndex
                            let day = dayForOffset(dayOffset)
                            
                            CalendarDayTile(
                                day: day,
                                activities: getActivitiesForDay(day),
                                isCurrentMonth: isCurrentMonth(day),
                                onActivitySelected: { activity in
                                    selectedActivity = activity
                                    showActivityDetails = true
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
    }
    
    private var numberOfWeeks: Int {
        let calendar = Calendar.current
        let firstOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let range = calendar.range(of: .day, in: .month, for: month) ?? 1..<32
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysInMonth = range.count
        
        return Int(ceil(Double(daysInMonth + firstWeekday - 1) / 7.0))
    }
    
    private func dayForOffset(_ offset: Int) -> Date {
        let calendar = Calendar.current
        let firstOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let dayOffset = offset - firstWeekday + 1
        
        return calendar.date(byAdding: .day, value: dayOffset, to: firstOfMonth) ?? firstOfMonth
    }
    
    private func isCurrentMonth(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: month, toGranularity: .month)
    }
    
    private func getActivitiesForDay(_ date: Date) -> [CalendarActivityDTO] {
        let calendar = Calendar.current
        return profileViewModel.allCalendarActivities.filter { activity in
            calendar.isDate(activity.date, inSameDayAs: date)
        }
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
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    private let tileSize: CGFloat = 86.4
    private let cornerRadius: CGFloat = 12.34
    
    var body: some View {
        ZStack {
            if isCurrentMonth {
                if activities.isEmpty {
                    // Empty day tile
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color(hex: "#DBDBDB"))
                        .frame(width: tileSize, height: tileSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 12.34, x: 0, y: 3.09)
                } else {
                    // Day with activities
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(activityBackgroundColor)
                        .frame(width: tileSize, height: tileSize)
                        .shadow(color: Color.black.opacity(0.1), radius: 12.34, x: 0, y: 3.09)
                        .overlay(
                            VStack(spacing: 4) {
                                if activities.count == 1 {
                                    // Single activity emoji
                                    activityEmoji(for: activities[0])
                                        .font(.onestMedium(size: 49.37))
                                        .foregroundColor(figmaBlack300)
                                } else {
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
                        .onTapGesture {
                            if activities.count == 1 {
                                onActivitySelected(activities[0])
                            } else if activities.count > 1 {
                                // For multiple activities, select the first one
                                onActivitySelected(activities[0])
                            }
                        }
                }
                
                // Day number overlay
                VStack {
                    Spacer()
                    HStack {
                        Text("\(dayNumber)")
                            .font(.onestSemiBold(size: 12))
                            .foregroundColor(dayNumberColor)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(dayNumberBackgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        Spacer()
                    }
                    .padding(.bottom, 6)
                    .padding(.leading, 6)
                }
            } else {
                // Days outside current month - invisible
                Color.clear
                    .frame(width: tileSize, height: tileSize)
            }
        }
        .frame(width: tileSize, height: tileSize)
    }
    
    private var dayNumber: Int {
        Calendar.current.component(.day, from: day)
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    
    private var dayNumberColor: Color {
        isToday ? Color(hex: "#1D1D1D") : figmaBlack300
    }
    
    private var dayNumberBackgroundColor: Color {
        isToday ? figmaBlue : Color(hex: "#F2EAEA")
    }
    
    private var activityBackgroundColor: Color {
        if activities.isEmpty {
            return Color(hex: "#DBDBDB")
        }
        
        // Use predefined colors from the Figma design
        let colors = [
            Color(hex: "#FF9191"), // Red
            Color(hex: "#59EEE1"), // Teal
            Color(hex: "#FF9F6B"), // Orange
            Color(hex: "#E15B73"), // Pink
            Color(hex: "#9797FF"), // Purple
            Color(hex: "#5EF029"), // Green
            Color(hex: "#5EF0C0"), // Mint
            Color(hex: "#DEA0FF"), // Light Purple
            Color(hex: "#FFE45C")  // Yellow
        ]
        
        // Use activity ID to determine color consistently
        if let firstActivity = activities.first,
           let activityId = firstActivity.activityId {
            let index = abs(activityId.hashValue) % colors.count
            return colors[index]
        }
        
        return Color(hex: "#DBDBDB")
    }
    
    private func activityEmoji(for activity: CalendarActivityDTO) -> Text {
        if let icon = activity.icon, !icon.isEmpty {
            return Text(icon)
        }
        
        // Fallback emojis based on activity category
        let fallbackEmoji = activity.activityCategory?.emoji ?? "⭐"
        return Text(fallbackEmoji)
    }
}

struct ActivityDetailsSheet: View {
    let activity: CalendarActivityDTO
    @StateObject var userAuth: UserAuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2.5)
                .fill(figmaBlack300)
                .frame(width: 36, height: 5)
                .padding(.top, 12)
            
            // Activity details
            VStack(alignment: .leading, spacing: 12) {
                Text(activity.title ?? "Activity")
                    .font(.onestSemiBold(size: 24))
                    .foregroundColor(universalAccentColor)
                
                if let description = activity.description {
                    Text(description)
                        .font(.onestRegular(size: 16))
                        .foregroundColor(figmaBlack300)
                }
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(figmaBlue)
                    
                    Text(formatDate(activity.date))
                        .font(.onestMedium(size: 14))
                        .foregroundColor(figmaBlack300)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Text("Close")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(figmaBlue)
                    .clipShape(RoundedRectangle(cornerRadius: universalRectangleCornerRadius))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(universalBackgroundColor)
        .presentationDetents([.medium])
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Extension to add emoji support to ActivityCategory
extension ActivityCategory {
    var emoji: String {
        switch self {
        case .general:
            return "⭐"
        case .foodAndDrink:
            return "🍣"
        case .active:
            return "🏃‍♂️"
        case .grind:
            return "💻"
        case .chill:
            return "🎉"
        }
    }
}

#Preview {
    EventCalendarView(profileViewModel: ProfileViewModel(userId: UUID()))
} 