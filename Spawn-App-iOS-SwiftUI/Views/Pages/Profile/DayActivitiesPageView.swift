import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var userAuth = UserAuthViewModel.shared
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
                if showActivityDetails, let activity = profileViewModel.selectedActivity {
                                                    EmptyView() // Replaced with global popup system
            }
        }
        .onChange(of: showActivityDetails) { isShowing in
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
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(figmaBlack400)
            }
            
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
            Button(action: {}) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.clear)
            }
            .disabled(true)
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
        VStack(spacing: 16) {
            Spacer()
            
            Image("NoActivitiesFound")
                .resizable()
                .frame(width: 125, height: 125)
            
            Text("No activities for this day")
                .font(.onestSemiBold(size: 24))
                .foregroundColor(universalAccentColor)
            
            Text("Check out other days or create\nyour own activity!")
                .font(.onestMedium(size: 16))
                .foregroundColor(figmaBlack300)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Loading activities...")
                .font(.onestMedium(size: 16))
                .foregroundColor(figmaBlack300)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

// MARK: - Activity Loading Card
struct ActivityLoadingCard: View {
    let activity: CalendarActivityDTO
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Row: Title and icon
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title ?? "Activity")
                        .font(.onestBold(size: 24))
                        .foregroundColor(.white)
                        .redacted(reason: .placeholder)
                    
                    Text("Loading details...")
                        .font(.onestRegular(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                
                // Activity icon
                Text(activity.icon ?? "📅")
                    .font(.system(size: 24))
            }
            
            // Location placeholder
            HStack {
                Text(Image(systemName: "mappin.and.ellipse"))
                    .foregroundColor(.white)
                    .font(.onestSemiBold(size: 12))
                Text("Loading location...")
                    .foregroundColor(.white)
                    .font(.onestSemiBold(size: 14))
                    .redacted(reason: .placeholder)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.18))
            .cornerRadius(100)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
        .overlay(
            // Loading indicator
            VStack {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Spacer()
            }
            .padding(14)
        )
    }
}

// MARK: - Preview
@available(iOS 17, *)
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesPageView(
            date: Date(),
            activities: [],
            onDismiss: {},
            onActivitySelected: { _ in }
        )
    }
} 
