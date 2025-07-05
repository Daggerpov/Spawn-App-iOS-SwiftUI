import SwiftUI

struct FriendActivitiesListView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showActivityDetails: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                if profileViewModel.isLoadingUserActivities {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .frame(height: 200)
                } else if sortedActivities.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.6))
                        
                        VStack(spacing: 8) {
                            Text("No Activities Yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("\(FormatterService.shared.formatFirstName(user: user)) hasn't created any activities yet.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    // Upcoming Activities Section
                    if !upcomingActivities.isEmpty {
                        upcomingActivitiesSection
                    }
                    
                    // Past Activities Section
                    if !pastActivities.isEmpty {
                        pastActivitiesSection
                    }
                }
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
    
    // MARK: - Section Views
    private var upcomingActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("Upcoming Activities")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(upcomingActivities) { activity in
                    StyledActivityCard(
                        activity: activity,
                        isUpcoming: true,
                        onTap: {
                            profileViewModel.selectedActivity = activity
                            showActivityDetails = true
                        }
                    )
                }
            }
        }
    }
    
    private var pastActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text("Past Activities")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
                Spacer()
            }
            
            LazyVStack(spacing: 12) {
                ForEach(pastActivities) { activity in
                    StyledActivityCard(
                        activity: activity,
                        isUpcoming: false,
                        onTap: {
                            profileViewModel.selectedActivity = activity
                            showActivityDetails = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private var sortedActivities: [ProfileActivityDTO] {
        return upcomingActivities + pastActivities
    }
    
    private var upcomingActivities: [ProfileActivityDTO] {
        let upcoming = profileViewModel.profileActivities
            .filter { !$0.isPastActivity }
        
        return upcoming.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 < start2
        }
    }
    
    private var pastActivities: [ProfileActivityDTO] {
        let past = profileViewModel.profileActivities
            .filter { $0.isPastActivity }
        
        return past.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 > start2
        }
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

// MARK: - Styled Activity Card
struct StyledActivityCard: View {
    let activity: ProfileActivityDTO
    let isUpcoming: Bool
    let onTap: () -> Void
    
    private var cardColor: Color {
        if isUpcoming {
            // Cycle through colors for upcoming activities
            let colors = [
                Color(red: 0.20, green: 0.30, blue: 0.87), // Blue
                Color(red: 0.99, green: 0.31, blue: 0.30), // Red
                Color(red: 0.33, green: 0.42, blue: 0.93), // Purple
                Color(red: 0.92, green: 0.50, blue: 0.15), // Orange
            ]
            return colors[abs(activity.id.hashValue) % colors.count]
        } else {
            // Cycle through colors for past activities
            let colors = [
                Color(red: 0.21, green: 0.46, blue: 1.00), // Light Blue
                Color(red: 0.50, green: 1.00, blue: 0.75), // Light Green
                Color(red: 0.92, green: 0.15, blue: 0.52), // Pink
                Color(red: 1.00, green: 0.90, blue: 0.57), // Yellow
            ]
            return colors[abs(activity.id.hashValue) % colors.count]
        }
    }
    
    private var participantCountColor: Color {
        if isUpcoming {
            let colors = [
                Color(red: 0.20, green: 0.30, blue: 0.87), // Blue
                Color(red: 0.99, green: 0.31, blue: 0.30), // Red
                Color(red: 0.33, green: 0.42, blue: 0.93), // Purple
                Color(red: 0.92, green: 0.50, blue: 0.15), // Orange
            ]
            return colors[abs(activity.id.hashValue) % colors.count]
        } else {
            let colors = [
                Color(red: 0.21, green: 0.46, blue: 1.00), // Light Blue
                Color(red: 0.13, green: 0.25, blue: 0.19), // Dark Green
                Color(red: 0.92, green: 0.15, blue: 0.52), // Pink
                Color(red: 0.25, green: 0.22, blue: 0.14), // Brown
            ]
            return colors[abs(activity.id.hashValue) % colors.count]
        }
    }
    
    private var timeText: String {
        guard let startTime = activity.startTime else { return "" }
        
        let calendar = Calendar.current
        let now = Date()
        
        if isUpcoming {
            let timeInterval = startTime.timeIntervalSince(now)
            let hours = Int(timeInterval / 3600)
            
            if calendar.isDateInToday(startTime) {
                if hours <= 1 {
                    return "Later Today"
                } else {
                    return "In \(hours) Hours"
                }
            } else if calendar.isDateInTomorrow(startTime) {
                return "Tomorrow"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: startTime)
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: startTime)
        }
    }
    
    private var titleTextColor: Color {
        // For past activities with light backgrounds, use darker text
        if !isUpcoming {
            let lightBackgrounds = [1, 3] // Light Green and Yellow indices
            let colorIndex = abs(activity.id.hashValue) % 4
            if lightBackgrounds.contains(colorIndex) {
                return Color(red: 0, green: 0, blue: 0).opacity(0.75)
            }
        }
        return .white
    }
    
    private var subtitleTextColor: Color {
        // For past activities with light backgrounds, use different subtitle colors
        if !isUpcoming {
            let lightBackgrounds = [1, 3] // Light Green and Yellow indices
            let colorIndex = abs(activity.id.hashValue) % 4
            if lightBackgrounds.contains(colorIndex) {
                return Color(red: 1, green: 1, blue: 1).opacity(0.60)
            }
        }
        return Color(red: 1, green: 1, blue: 1).opacity(0.80)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                // Activity Title and Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 6) {
                        Text(activity.title ?? "Activity")
                            .font(.onestSemiBold(size: isUpcoming ? 20 : 17))
                            .foregroundColor(titleTextColor)
                            .lineLimit(1)
                    }
                    
                    if isUpcoming {
                        Text("By \(FormatterService.shared.formatFirstName(user: activity.creatorUser)) • \(formatTime())")
                            .font(.onestMedium(size: 13))
                            .foregroundColor(subtitleTextColor)
                            .lineLimit(1)
                    } else {
                        Text("\(activity.location?.name ?? "Location") • \(timeText)")
                            .font(.onestMedium(size: 13))
                            .foregroundColor(subtitleTextColor)
                            .lineLimit(1)
                    }
                }
                
                // Location badge for upcoming activities
                if isUpcoming, let locationName = activity.location?.name {
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Text("􀎫")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("\(locationName) • 500m away")
                                .font(.onestSemiBold(size: 13))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    .padding(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0.20))
                    .cornerRadius(100)
                }
            }
            
            Spacer()
            
            // Participant count and profile images
            VStack(alignment: .trailing, spacing: 0) {
                // Participant count
                VStack(spacing: 0) {
                    Text("+\(activity.participantUsers?.count ?? 0)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(participantCountColor)
                }
                .frame(width: 33.60, height: 33.60)
                .background(.white)
                .cornerRadius(51.67)
                
                // Profile image placeholders
                VStack(spacing: -8) {
                    ForEach(0..<min(2, activity.participantUsers?.count ?? 0), id: \.self) { _ in
                        Circle()
                            .frame(width: 33.53, height: 34.26)
                            .foregroundColor(.clear)
                            .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                            .shadow(
                                color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
                                radius: 3.22,
                                y: 1.29
                            )
                    }
                }
                .padding(.top, 8)
            }
            
            // Time badge for upcoming activities
            if isUpcoming {
                HStack(spacing: 10) {
                    Text(timeText)
                        .font(.onestSemiBold(size: 11))
                        .foregroundColor(Color(red: 0, green: 0, blue: 0).opacity(0.80))
                }
                .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
                .background(Color(red: 1, green: 1, blue: 1).opacity(0.80))
                .cornerRadius(8)
                .shadow(
                    color: Color(red: 1, green: 1, blue: 1, opacity: 0.25),
                    radius: 24
                )
                .offset(x: -50, y: 47)
            }
        }
        .padding(EdgeInsets(
            top: isUpcoming ? 20 : 13,
            leading: 16,
            bottom: isUpcoming ? 16 : 13,
            trailing: 16
        ))
        .background(cardColor)
        .cornerRadius(12)
        .shadow(
            color: Color(red: 0, green: 0, blue: 0, opacity: isUpcoming ? 0.20 : 0.25),
            radius: isUpcoming ? 16 : 8,
            y: isUpcoming ? 4 : 2
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private func formatTime() -> String {
        guard let startTime = activity.startTime else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startTimeStr = formatter.string(from: startTime)
        
        if let endTime = activity.endTime {
            let endTimeStr = formatter.string(from: endTime)
            return "\(startTimeStr) - \(endTimeStr)"
        } else {
            return startTimeStr
        }
    }
}

#Preview {
    NavigationView {
        FriendActivitiesListView(
            user: BaseUserDTO.danielAgapov,
            profileViewModel: ProfileViewModel(),
            showActivityDetails: .constant(false)
        )
    }
} 
