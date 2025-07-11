import SwiftUI

struct FriendActivitiesShowAllView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showActivityDetails: Bool
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                universalBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            // Activity Cards Section
                            activityCardsSection
                            
                            // Calendar Section
                            calendarSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Safe area padding
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showActivityDetails) {
            activityDetailsView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.onestSemiBold(size: 18))
                    .foregroundColor(universalAccentColor)
            }
            
            Spacer()
            
            // Title
            Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
                .font(.onestSemiBold(size: 18))
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            // Invisible spacer to balance the back button
            Color.clear
                .frame(width: 24, height: 24)
        }
    }
    
    // MARK: - Activity Cards Section
    private var activityCardsSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Text("Show All")
                    .font(.onestMedium(size: 14))
                    .foregroundColor(figmaBlue)
            }
            
            // Custom Activity Cards
            VStack(spacing: 12) {
                // First activity card (blue)
                FriendActivityCard(
                    title: "Activity Name",
                    creator: "First Last",
                    time: "1 - 2:30pm",
                    location: "Location • 500m away",
                    participantCount: "+12",
                    timeLabel: "Later Today",
                    backgroundColor: figmaBlue,
                    participantColor: figmaBlue,
                    timeLabelColor: Color(red: 1, green: 0.95, blue: 0.70).opacity(0.80)
                )
                
                // Second activity card (red)
                FriendActivityCard(
                    title: "Activity Name",
                    creator: "First Last",
                    time: "1 - 2:30pm",
                    location: "Location • 500m away",
                    participantCount: "+12",
                    timeLabel: "In 3 Hours",
                    backgroundColor: Color(red: 0.77, green: 0.19, blue: 0.19),
                    participantColor: Color(red: 0.77, green: 0.19, blue: 0.19),
                    timeLabelColor: Color(red: 1, green: 0.78, blue: 0.49).opacity(0.80)
                )
            }
        }
    }
    
    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(spacing: 16) {
            // Days of the week header
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.onestMedium(size: 13))
                        .foregroundColor(figmaBlack300)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid - EXACTLY 5 rows
            VStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { row in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { col in
                            CalendarDaySquare(
                                color: getColorForDay(row: row, col: col),
                                emoji: getEmojiForDay(row: row, col: col),
                                hasEmoji: hasEmojiForDay(row: row, col: col)
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    private var sortedActivities: [ProfileActivityDTO] {
        let upcomingActivities = profileViewModel.profileActivities
            .filter { !$0.isPastActivity }
        
        let sortedUpcoming = upcomingActivities.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 < start2
        }
        
        let pastActivities = profileViewModel.profileActivities
            .filter { $0.isPastActivity }
        
        let sortedPast = pastActivities.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 > start2
        }
        
        return sortedUpcoming + sortedPast
    }
    
    private var activityDetailsView: some View {
        Group {
            if let activity = profileViewModel.selectedActivity {
                let activityColor = activity.isSelfOwned == true ?
                    universalAccentColor : getActivityColor(for: activity.id)
                
                ActivityDescriptionView(
                    activity: activity,
                    users: activity.participantUsers,
                    color: activityColor,
                    userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Calendar Helper Methods
    private func getColorForDay(row: Int, col: Int) -> Color {
        // Sample calendar colors matching the screenshot
        let colors = [
            Color(hex: "#DBDBDB"), // Default gray
            Color(hex: "#FF9191"), // Red
            Color(hex: "#59EFE1"), // Teal
            Color(hex: "#FF9F6B"), // Orange
            Color(hex: "#E15B73"), // Pink
            Color(hex: "#9696FF"), // Purple
            Color(hex: "#5FE041"), // Green
            Color(hex: "#FFDE5C"), // Yellow
        ]
        
        let dayIndex = row * 7 + col
        let colorIndex = dayIndex % colors.count
        return colors[colorIndex]
    }
    
    private func getEmojiForDay(row: Int, col: Int) -> String {
        // Sample emojis matching the screenshot
        let emojis = ["🚗", "🍣", "🏃‍♂️", "💻", "📚", "🎉", "🏖️", "🎮", "✈️"]
        let dayIndex = row * 7 + col
        let emojiIndex = dayIndex % emojis.count
        return emojis[emojiIndex]
    }
    
    private func hasEmojiForDay(row: Int, col: Int) -> Bool {
        // Logic to show emojis on certain days
        let dayIndex = row * 7 + col
        return dayIndex % 3 != 0 // Show emoji for some days
    }
}

// MARK: - Custom Activity Card Component
struct FriendActivityCard: View {
    let title: String
    let creator: String
    let time: String
    let location: String
    let participantCount: String
    let timeLabel: String
    let backgroundColor: Color
    let participantColor: Color
    let timeLabelColor: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .shadow(color: Color.black.opacity(0.20), radius: 16, x: 0, y: 4)
            
            HStack(alignment: .top, spacing: 16) {
                // Left side - activity info
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.onestSemiBold(size: 20))
                            .foregroundColor(.white)
                        
                        Text("By \(creator) • \(time)")
                            .font(.onestRegular(size: 13))
                            .foregroundColor(.white.opacity(0.80))
                    }
                    
                    // Location badge
                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(location)
                            .font(.onestSemiBold(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.20))
                    .cornerRadius(100)
                }
                
                Spacer()
                
                // Right side - participants and time badge
                VStack(alignment: .trailing, spacing: 8) {
                    // Participants
                    VStack(spacing: 4) {
                        // Participant count badge
                        Text(participantCount)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(participantColor)
                            .frame(width: 34, height: 34)
                            .background(.white)
                            .cornerRadius(17)
                        
                        // Sample profile pictures
                        HStack(spacing: -8) {
                            Circle()
                                .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                            
                            Circle()
                                .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                        }
                    }
                    
                    Spacer()
                    
                    // Time label
                    Text(timeLabel)
                        .font(.onestSemiBold(size: 11))
                        .foregroundColor(.black.opacity(0.80))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(timeLabelColor)
                        .cornerRadius(8)
                        .shadow(color: Color.white.opacity(0.25), radius: 24)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - Calendar Day Square Component
struct CalendarDaySquare: View {
    let color: Color
    let emoji: String
    let hasEmoji: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 6.6)
            .fill(color)
            .frame(width: 46, height: 46)
            .shadow(color: Color.black.opacity(0.1), radius: 6.6, x: 0, y: 1.6)
            .overlay(
                Group {
                    if hasEmoji {
                        Text(emoji)
                            .font(.onestMedium(size: 20))
                    }
                }
            )
    }
}

// MARK: - Preview
#Preview {
    FriendActivitiesShowAllView(
        user: BaseUserDTO.danielAgapov,
        profileViewModel: ProfileViewModel(),
        showActivityDetails: .constant(false)
    )
} 