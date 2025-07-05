import SwiftUI

struct UserActivitiesSection: View {
    var user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showActivityDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            friendActivitiesSection
            
            addToSeeActivitiesSection
        }
    }
    
    // Computed property to sort activities as specified
    private var sortedActivities: [ProfileActivityDTO] {
        let upcomingActivities = profileViewModel.profileActivities
            .filter { !$0.isPastActivity }
        
        // Sort upcoming activities by soonest to latest
        let sortedUpcoming = upcomingActivities.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 < start2
        }
        
        let pastActivities = profileViewModel.profileActivities
            .filter { $0.isPastActivity }
        
        // Sort past activities by most recent first
        let sortedPast = pastActivities.sorted { activity1, activity2 in
            guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
                return false
            }
            return start1 > start2
        }
        
        // Combine upcoming activities followed by past activities
        return sortedUpcoming + sortedPast
    }
    
    // User Activities Section for friend profiles
    private var friendActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    // TODO: Navigate to full activities list
                }) {
                    Text("Show All")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(universalAccentColor)
                }
            }
            .padding(.horizontal)
            
            if profileViewModel.isLoadingUserActivities {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if profileViewModel.profileActivities.isEmpty {
                HStack {
                    Spacer()
                    Text("No activities")
                        .font(.onestRegular(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(sortedActivities) { activity in
                            ActivityCardView(
                                userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                                activity: activity,
                                color: activity.isSelfOwned == true ? universalAccentColor : getActivityColor(for: activity.id),
                                callback: { selectedActivity, color in
                                    profileViewModel.selectedActivity = selectedActivity
                                    showActivityDetails = true
                                }
                            )
                            .frame(width: 280)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // "Add to see activities" section for non-friends
    private var addToSeeActivitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if profileViewModel.friendshipStatus != .friends {
                VStack(alignment: .center, spacing: 8) {
                    Text("Add \(FormatterService.shared.formatFirstName(user: user)) to see their activities")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("Connect with them to discover what they're up to!")
                        .font(.onestRegular(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    UserActivitiesSection(
        user: BaseUserDTO.danielAgapov,
        profileViewModel: ProfileViewModel(),
        showActivityDetails: .constant(false)
    )
} 
