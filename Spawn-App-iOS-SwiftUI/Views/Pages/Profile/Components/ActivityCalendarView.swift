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
                    
                    Text("Your Activity Calendar")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    // Invisible spacer to center the title
                    Color.clear
                        .frame(width: 20, height: 20)
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
                // Background rectangle
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(activityBackgroundColor)
                    .frame(width: tileSize, height: tileSize)
                    .shadow(color: Color.black.opacity(0.1), radius: 12.34, x: 0, y: 3.09)
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
                                    
                                    activityEmoji(for: activities[1])
                                        .font(.onestMedium(size: 37.03))
                                        .foregroundColor(figmaBlack300)
                                }
                            }
                        }
                    )
                    .onTapGesture {
                        if activities.count >= 1 {
                            onActivitySelected(activities[0])
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
    
    private var dayNumberColor: Color {
        if activities.isEmpty {
            return figmaBlack300
        } else {
            return Color.white
        }
    }
    
    private var dayNumberBackgroundColor: Color {
        if activities.isEmpty {
            return Color.clear
        } else {
            return Color.black.opacity(0.6)
        }
    }
    
    private var activityBackgroundColor: Color {
        if activities.isEmpty {
            return Color(hex: "#F6F6F6")
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
                        
                        Text(DateFormatter.dayMonthYear.string(from: activity.date))
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
    ActivityCalendarView(profileViewModel: ProfileViewModel(userId: UUID()))
} 