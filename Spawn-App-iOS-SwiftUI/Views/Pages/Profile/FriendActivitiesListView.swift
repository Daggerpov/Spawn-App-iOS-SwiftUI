import SwiftUI

struct FriendActivitiesListView: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showActivityDetails: Bool
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
                    // Display all activity cards vertically
                    LazyVStack(spacing: 16) {
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
                        }
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
    
    // MARK: - Helper Methods
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

#Preview {
    NavigationView {
        FriendActivitiesListView(
            user: BaseUserDTO.danielAgapov,
            profileViewModel: ProfileViewModel(),
            showActivityDetails: .constant(false)
        )
    }
} 