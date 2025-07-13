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
        .sheet(isPresented: $showActivityDetails) {
            if let activity = profileViewModel.selectedActivity {
                let activityColor = activity.isSelfOwned == true ?
                    universalAccentColor : getActivityColor(for: activity.id)

                ActivityDetailModalView(
                    activity: activity,
                    activityColor: activityColor,
                    onDismiss: {
                        showActivityDetails = false
                    }
                )
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                dismiss()
                onDismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(universalAccentColor)
            }
            .padding(.leading, 20)
            
            Spacer()
            
            // Title
            Text("Events - \(formattedDate)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(figmaBlack400)
            
            Spacer()
            
            // Invisible spacer for balance
            Color.clear
                .frame(width: 44, height: 44)
                .padding(.trailing, 20)
        }
        .padding(.vertical, 12)
        .background(universalBackgroundColor)
    }
    
    // MARK: - Content View
    private var contentView: some View {
        Group {
            if activities.isEmpty {
                emptyStateView
            } else {
                activitiesListView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No activities for this day")
                .font(.onestMedium(size: 18))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Activities List View
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(activities, id: \.id) { activity in
                    if let activityId = activity.activityId,
                       let fullActivity = getFullActivity(for: activityId) {
                        // Show full activity card
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
                        // Show simplified activity card for calendar activities
                        CalendarActivityCardView(
                            activity: activity,
                            color: getColorForActivity(activity),
                            onTap: {
                                handleActivitySelection(activity)
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func getFullActivity(for activityId: UUID) -> FullFeedActivityDTO? {
        // Try to get the activity from the profile view model
        return profileViewModel.selectedActivity
    }
    
    private func getColorForActivity(_ activity: CalendarActivityDTO) -> Color {
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise, use the activity color based on ID
        guard let activityId = activity.activityId else {
            return .gray
        }
        
        return getActivityColor(for: activityId)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Calendar Activity Card View
struct CalendarActivityCardView: View {
    let activity: CalendarActivityDTO
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Activity icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color)
                        .frame(width: 40, height: 40)
                    
                    Text(activity.icon ?? "📅")
                        .font(.system(size: 20))
                }
                
                // Activity info
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.title ?? "Activity")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(figmaBlack400)
                        .lineLimit(1)
                    
                    Text(formattedActivityDate)
                        .font(.onestMedium(size: 14))
                        .foregroundColor(figmaBlack300)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(figmaBlack300)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedActivityDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: activity.dateAsDate)
    }
}

// MARK: - Preview
@available(iOS 17, *)
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DayActivitiesPageView(
                date: Date(),
                activities: [
                    CalendarActivityDTO.create(
                        id: UUID(),
                        date: Date(),
                        title: "Sample Activity",
                        icon: "🎉",
                        colorHexCode: "#3575FF",
                        activityId: UUID()
                    ),
                    CalendarActivityDTO.create(
                        id: UUID(),
                        date: Date(),
                        title: "Another Activity",
                        icon: "🥾",
                        colorHexCode: "#80FF75",
                        activityId: UUID()
                    )
                ],
                onDismiss: {},
                onActivitySelected: { _ in }
            )
        }
    }
} 
