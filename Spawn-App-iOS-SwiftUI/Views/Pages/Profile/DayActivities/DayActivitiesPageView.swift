import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()
    @ObservedObject private var userAuth = UserAuthViewModel.shared
    @StateObject private var locationManager = LocationManager()
    @State private var showActivityDetails: Bool = false
    @State private var fullActivities: [UUID: FullFeedActivityDTO] = [:]
    @State private var isLoadingActivities = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            contentView
        }
        .background(universalBackgroundColor)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .overlay(
            // Use the same ActivityPopupDrawer as the feed view for consistency
            Group {
                if showActivityDetails, let _ = profileViewModel.selectedActivity {
                                                    EmptyView() // Replaced with global popup system
            }
        }
        .onChange(of: showActivityDetails) { _, isShowing in
            if isShowing, let activity = profileViewModel.selectedActivity {
                let activityColor = getActivityColor(for: activity.id)
                
                // Post notification to show global popup
                NotificationCenter.default.post(
                    name: .showGlobalActivityPopup,
                    object: nil,
                    userInfo: ["activity": activity, "color": activityColor]
                )
                // Reset local state since global popup will handle it
                showActivityDetails = false
                profileViewModel.selectedActivity = nil
            }
        }
        )
        .onAppear {
            fetchAllActivityDetails()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            UnifiedBackButton(action: onDismiss)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(dayOfWeek)
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(figmaBlack400)
                
                Text(formattedDate)
                    .font(.onestMedium(size: 14))
                    .foregroundColor(figmaBlack300)
            }
            
            Spacer()
            
            // Invisible button for spacing balance
            Color.clear.frame(width: 24, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if activities.isEmpty {
                emptyStateView
            } else if isLoadingActivities {
                loadingStateView
            } else {
                activitiesListView
            }
        }
    }
    
    private var emptyStateView: some View {
        EmptyStateView.noActivitiesForDay()
    }
    
    private var loadingStateView: some View {
        LoadingStateView(message: "Loading activities...")
    }
    
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(activities, id: \.id) { activity in
                    if let activityId = activity.activityId,
                       let fullActivity = fullActivities[activityId] {
                        // Always use the full ActivityCardView for consistent styling
                        ActivityCardView(
                            userId: userAuth.spawnUser?.id ?? UUID(),
                            activity: fullActivity,
                            color: getColorForActivity(activity),
                            locationManager: locationManager,
                            callback: { _, _ in
                                onActivitySelected(activity)
                            }
                        )
                    } else {
                        // Show loading placeholder while activity details are being fetched
                        ActivityLoadingCard(
                            activity: activity,
                            color: getColorForActivity(activity)
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func fetchAllActivityDetails() {
        guard !activities.isEmpty else { return }
        
        isLoadingActivities = true
        
        Task {
            var fetchedActivities: [UUID: FullFeedActivityDTO] = [:]
            
            // Fetch all activity details concurrently
            await withTaskGroup(of: (UUID, FullFeedActivityDTO?).self) { group in
                for activity in activities {
                    guard let activityId = activity.activityId else { continue }
                    
                    group.addTask {
                        let fullActivity = await profileViewModel.fetchActivityDetails(activityId: activityId)
                        return (activityId, fullActivity)
                    }
                }
                
                for await (activityId, fullActivity) in group {
                    if let fullActivity = fullActivity {
                        fetchedActivities[activityId] = fullActivity
                    }
                }
            }
            
            await MainActor.run {
                self.fullActivities = fetchedActivities
                self.isLoadingActivities = false
            }
        }
    }
    
    private func handleActivitySelection(_ activity: CalendarActivityDTO) {
        Task {
            if let activityId = activity.activityId,
               let _ = await profileViewModel.fetchActivityDetails(activityId: activityId) {
                await MainActor.run {
                    showActivityDetails = true
                }
            }
        }
    }
    
    private func getColorForActivity(_ activity: CalendarActivityDTO) -> Color {
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Use the exact same logic as feed view - ActivityColorService with activityId
        if let activityId = activity.activityId {
            return ActivityColorService.shared.getColorForActivity(activityId)
        }
        
        // For calendar-only activities without activityId, use the calendar activity's own id
        return ActivityColorService.shared.getColorForActivity(activity.id)
    }
    
    // MARK: - Computed Properties
    
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
    DayActivitiesPageView(
        date: Date(),
        activities: [],
        onDismiss: {},
        onActivitySelected: { _ in }
    )
}
