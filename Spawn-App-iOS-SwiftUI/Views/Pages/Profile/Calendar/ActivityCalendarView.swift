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
    
    var onDismiss: (() -> Void)?
    var onActivitySelected: ((CalendarActivityDTO) -> Void)?
    var onDayActivitiesSelected: ([CalendarActivityDTO]) -> Void
    
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
                                    userAuth: userAuth,
                                    onActivitySelected: onActivitySelected,
                                    onDayActivitiesSelected: onDayActivitiesSelected
                                )
                                .id(month)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 16) // Standard bottom padding
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
    

}

#Preview {
    ActivityCalendarView(
        profileViewModel: ProfileViewModel(userId: UUID()),
        userCreationDate: nil,
        calendarOwnerName: nil,
        onDismiss: {},
        onActivitySelected: { _ in },
        onDayActivitiesSelected: { _ in }
    )
}
