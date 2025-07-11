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
        NavigationView {
            ZStack {
                // Background
                universalBackgroundColor
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
        }
        .navigationBarHidden(true)
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
                Image(systemName: "chevron.left")
                    .font(.onestSemiBold(size: 20))
                    .foregroundColor(universalAccentColor)
            }
            
            Spacer()
            
            // Title
            Text("Events - \(formattedDate)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            // Invisible spacer to center the title
            Color.clear
                .frame(width: 20, height: 20)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
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
                        ActivityCardView(
                            userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                            activity: fullActivity,
                            color: getColorForActivity(activity),
                            callback: { _, _ in
                                onActivitySelected(activity)
                            }
                        )
                        .padding(.horizontal, 16)
                    } else {
                        // Loading state
                        ActivityLoadingCard(activity: activity, color: getColorForActivity(activity))
                            .padding(.horizontal, 16)
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
                .foregroundColor(figmaBlack300)
            
            Text("No Events Found")
                .font(.onestSemiBold(size: 24))
                .foregroundColor(universalAccentColor)
            
            Text("There are no activities scheduled for this day.")
                .font(.onestRegular(size: 16))
                .foregroundColor(figmaBlack300)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
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