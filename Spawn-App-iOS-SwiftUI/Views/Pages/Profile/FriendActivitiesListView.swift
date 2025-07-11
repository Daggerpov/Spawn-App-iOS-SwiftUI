import SwiftUI

struct FriendActivitiesListView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showActivityDetails: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            universalBackgroundColor
            
            VStack(spacing: 32) {
                // Header Section
                headerSection
                
                // Sample Activity Cards
                sampleActivityCards
                
                // Calendar Grid
                calendarGrid
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .navigationTitle("Activities by \(FormatterService.shared.formatFirstName(user: user))")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .sheet(isPresented: $showActivityDetails) {
            activityDetailsView
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(spacing: 12) {
            Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
                .font(.onestSemiBold(size: 16))
                .foregroundColor(figmaBlack300)
            
            Spacer()
            
            Text("Show All")
                .font(.onestMedium(size: 14))
                .foregroundColor(figmaBlue)
        }
    }
    
    // MARK: - Sample Activity Cards
    private var sampleActivityCards: some View {
        VStack(spacing: 12) {
            // First activity card (blue)
            ActivityCardExample(
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
            ActivityCardExample(
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
    
    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        VStack(spacing: 16) {
            // Days of the week header
            dayOfWeekHeader
            
            // Calendar grid rows
            ForEach(0..<6, id: \.self) { row in
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
    
    // MARK: - Days of Week Header
    private var dayOfWeekHeader: some View {
        HStack(spacing: 8) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                Text(day)
                    .font(.onestMedium(size: 13))
                    .foregroundColor(figmaBlack300)
                    .frame(width: 46, height: 16)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func getColorForDay(row: Int, col: Int) -> Color {
        let dayIndex = row * 7 + col
        
        // Define the color pattern based on the Figma design using project constants
        let colorPatterns: [Color] = [
            // Row 1 - all gray
            universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor,
            
            // Row 2 
            universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, Color(red: 1, green: 0.57, blue: 0.57), Color(red: 0.35, green: 0.93, blue: 0.88),
            
            // Row 3
            universalPlaceHolderTextColor, Color(red: 1, green: 0.62, blue: 0.42), universalPlaceHolderTextColor, Color(red: 0.88, green: 0.36, blue: 0.45), universalPlaceHolderTextColor, universalPlaceHolderTextColor, Color(red: 0.59, green: 0.59, blue: 1),
            
            // Row 4
            universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, Color(red: 0.37, green: 0.88, blue: 0.16), universalPlaceHolderTextColor,
            
            // Row 5
            universalPlaceHolderTextColor, Color(red: 0.36, green: 0.94, blue: 0.75), universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, universalPlaceHolderTextColor, Color(red: 0.87, green: 0.61, blue: 1),
            
            // Row 6
            Color(red: 1, green: 0.87, blue: 0.36), universalPlaceHolderTextColor, Color(red: 0.52, green: 0.49, blue: 0.49), Color(red: 0.52, green: 0.49, blue: 0.49), Color(red: 0.52, green: 0.49, blue: 0.49), Color(red: 0.52, green: 0.49, blue: 0.49), Color(red: 0.52, green: 0.49, blue: 0.49),
        ]
        
        return colorPatterns[safe: dayIndex] ?? universalPlaceHolderTextColor
    }
    
    private func getEmojiForDay(row: Int, col: Int) -> String {
        let dayIndex = row * 7 + col
        
        // Define emoji patterns based on the Figma design
        let emojiPatterns: [String?] = [
            // Row 1 - all empty
            nil, nil, nil, nil, nil, nil, nil,
            // Row 2 
            nil, nil, nil, nil, nil, nil, nil,
            // Row 3
            nil, nil, nil, nil, nil, nil, nil,
            // Row 4
            nil, nil, nil, nil, nil, nil, nil,
            // Row 5
            nil, nil, nil, nil, "🚗", nil, nil,
            // Row 6
            nil, nil, "🍣", "🏃‍♂️", "💻", "💻", "🎉"
        ]
        
        // Additional emojis for last row
        if row == 5 {
            let lastRowEmojis = ["📚", "🏖️", "🎮", "✈️"]
            if col >= 3 && col < 7 {
                return lastRowEmojis[safe: col - 3] ?? ""
            }
        }
        
        if let emoji = emojiPatterns[safe: dayIndex] {
            return emoji ?? ""
        }
        return ""
    }
    
    private func hasEmojiForDay(row: Int, col: Int) -> Bool {
        return !getEmojiForDay(row: row, col: col).isEmpty
    }
    
    // MARK: - Activity Details Sheet
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
}

// MARK: - Activity Card Example
struct ActivityCardExample: View {
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
                
                // Right side - participants
                VStack(alignment: .trailing, spacing: 8) {
                    // Participant count
                    Text(participantCount)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(participantColor)
                        .frame(width: 34, height: 34)
                        .background(.white)
                        .clipShape(Circle())
                    
                    // Mock profile pictures
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 34, height: 34)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                        
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .frame(width: 34, height: 34)
                            .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    }
                }
            }
            .padding(20)
            .background(backgroundColor)
            .cornerRadius(universalNewRectangleCornerRadius)
            .shadow(color: .black.opacity(0.20), radius: 16, y: 4)
            
            // Time label overlay
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(timeLabel)
                        .font(.onestSemiBold(size: 11))
                        .foregroundColor(.black.opacity(0.80))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(timeLabelColor)
                        .cornerRadius(universalNewRectangleCornerRadius)
                        .shadow(color: .white.opacity(0.25), radius: 24)
                        .offset(x: -16, y: -12)
                }
            }
        }
    }
}

// MARK: - Calendar Day Square
struct CalendarDaySquare: View {
    let color: Color
    let emoji: String
    let hasEmoji: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6.62)
                .fill(color)
                .frame(width: 46, height: 46)
                .shadow(color: .black.opacity(0.10), radius: 6.62, y: 1.65)
            
            if hasEmoji {
                Text(emoji)
                    .font(.system(size: 26))
            }
        }
    }
}

// MARK: - Array Extension for Safe Access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
