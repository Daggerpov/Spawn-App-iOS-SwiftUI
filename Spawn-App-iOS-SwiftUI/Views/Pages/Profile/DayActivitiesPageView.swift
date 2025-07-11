import SwiftUI

struct DayActivitiesPageView: View {
    let date: Date
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @StateObject private var viewModel: DayActivitiesViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        date: Date,
        activities: [CalendarActivityDTO],
        onDismiss: @escaping () -> Void,
        onActivitySelected: @escaping (CalendarActivityDTO) -> Void
    ) {
        self.date = date
        self.activities = activities
        self.onDismiss = onDismiss
        self.onActivitySelected = onActivitySelected
        
        self._viewModel = StateObject(
            wrappedValue: DayActivitiesViewModel(
                apiService: MockAPIService.isMocking 
                    ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
                    : APIService(),
                activities: activities
            )
        )
    }
    
    var body: some View {
        ZStack {
            // Dark background matching Figma design
            Color(red: 0.12, green: 0.12, blue: 0.12)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Activities list
                if viewModel.activities.isEmpty {
                    emptyStateView
                } else {
                    activitiesListView
                }
                
                Spacer()
            }
        }
        .onAppear {
            Task {
                await viewModel.loadActivitiesIfNeeded()
            }
        }
    }
}

// MARK: - Header View
extension DayActivitiesPageView {
    private var headerView: some View {
        HStack(spacing: 32) {
            // Back button
            Button(action: onDismiss) {
                Text("􀆉")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            // Title
            Text("Events - \(formattedDate)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
            
            // Invisible spacer to balance the layout
            Text("􀆉")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .opacity(0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 16) // Reduced for sheet presentation
        .padding(.bottom, 20)
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Activities List View
extension DayActivitiesPageView {
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.activities, id: \.id) { activity in
                    if let activityId = activity.activityId,
                       let fullActivity = viewModel.getActivity(for: activityId)
                    {
                        DayActivityCard(
                            activity: fullActivity,
                            color: getColorForActivity(activity),
                            onTap: {
                                onActivitySelected(activity)
                            }
                        )
                        .padding(.horizontal, 32)
                    } else {
                        // Loading state
                        ActivityLoadingCard(activity: activity, color: getColorForActivity(activity))
                            .padding(.horizontal, 32)
                            .onAppear {
                                if let activityId = activity.activityId {
                                    Task {
                                        await viewModel.fetchActivity(activityId)
                                    }
                                }
                            }
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100) // Extra padding for bottom safe area
        }
        .refreshable {
            Task {
                await viewModel.loadActivitiesIfNeeded()
            }
        }
    }
}

// MARK: - Empty State View
extension DayActivitiesPageView {
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.7))
            
            Text("No Events Found")
                .font(.onestSemiBold(size: 24))
                .foregroundColor(.white)
            
            Text("There are no activities scheduled for this day.")
                .font(.onestRegular(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Custom Activity Card for Day Sheet
extension DayActivitiesPageView {
    private struct DayActivityCard: View {
        let activity: FullFeedActivityDTO
        let color: Color
        let onTap: () -> Void
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(activity.title ?? "Sample Activity")
                            .font(.onestSemiBold(size: 17))
                            .foregroundColor(.white)
                        
						Text("\(activity.location?.name ?? "Activity Location") • \(formattedDate)")
                            .font(.onestMedium(size: 13))
                            .foregroundColor(Color.black.opacity(0.80))
                    }
                    
                    Spacer()
                    
                    // Participant count and avatars
                    HStack(spacing: -8) {
                        // Participant count
                        VStack(spacing: 0) {
							Text(
								"+\(max(0, (activity.participantUsers?.count ?? 0) - 2))"
							)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(figmaBlue)
                        }
                        .frame(width: 33.60, height: 33.60)
                        .background(.white)
                        .clipShape(Circle())
                        
                        // Avatar circles (placeholder)
                        ForEach(0..<min(2, activity.participantUsers?.count ?? 0), id: \.self) { _ in
                            Circle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: 33.53, height: 34.26)
                                .shadow(color: Color.black.opacity(0.25), radius: 3.22, x: 0, y: 1.29)
                        }
                    }
                }
                .padding(EdgeInsets(top: 13, leading: 16, bottom: 13, trailing: 16))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(color)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
        }
        
        private var formattedDate: String {
            guard let startTime = activity.startTime else { return "Date TBD" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: startTime)
        }
    }
}

// MARK: - Loading Card Component
extension DayActivitiesPageView {
    private struct ActivityLoadingCard: View {
        let activity: CalendarActivityDTO
        let color: Color
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Loading content
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        // Title placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 16)
                        
                        // Subtitle placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 200, height: 12)
                    }
                    
                    Spacer()
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
                
                // Location placeholder
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.onestMedium(size: 12))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 12)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.15))
                .cornerRadius(100)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
                    .opacity(0.8)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Helper Functions
extension DayActivitiesPageView {
    private func getColorForActivity(_ activity: CalendarActivityDTO) -> Color {
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise, use the activity color based on ID
        guard let activityId = activity.activityId else {
            return figmaBlue // Default color
        }
        
        return getActivityColor(for: activityId)
    }
}

// MARK: - Previews
#if DEBUG
@available(iOS 17, *)
struct DayActivitiesPageView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesPageView(
            date: Date(),
            activities: [
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
        
                    icon: "🎉",
                    colorHexCode: "#5667FF",
                    activityId: UUID()
                ),
                CalendarActivityDTO(
                    id: UUID(),
                    date: Date(),
        
                    icon: "🥾",
                    colorHexCode: "#1AB979",
                    activityId: UUID()
                )
            ],
            onDismiss: {},
            onActivitySelected: { _ in }
        )
    }
}
#endif 
