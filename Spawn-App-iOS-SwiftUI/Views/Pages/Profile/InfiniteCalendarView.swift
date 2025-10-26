import SwiftUI

// Expanded calendar view that shows all months in a year
struct InfiniteCalendarView: View {
    let activities: [CalendarActivityDTO]
    let isLoading: Bool
    let userCreationDate: Date?
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    let onDayActivitiesSelected: ([CalendarActivityDTO]) -> Void
    
    @State private var currentDate = Date()
    
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
                                    // Add safety check to prevent force unwrapping crash
                                    if let firstActivity = activities.first {
                                        onActivitySelected(firstActivity)
                                    }
                                } else if activities.count > 1 {
                                    onDayActivitiesSelected(activities)
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

@available(iOS 17.0, *)
#Preview {
    InfiniteCalendarView(
        activities: [],
        isLoading: false,
        userCreationDate: nil,
        onDismiss: {},
        onActivitySelected: { _ in },
        onDayActivitiesSelected: { _ in }
    )
}
