import SwiftUI

struct DayActivitiesView: View {
    let date: Date
    let onDismiss: () -> Void
    let onActivitySelected: (CalendarActivityDTO) -> Void
    
    @StateObject private var viewModel: DayActivitiesViewModel
    
    init(
        date: Date,
        onDismiss: @escaping () -> Void,
        onActivitySelected: @escaping (CalendarActivityDTO) -> Void
    ) {
        self.date = date
        self.onDismiss = onDismiss
        self.onActivitySelected = onActivitySelected
        
        // Initialize the view model with empty activities array for now
        // The activities will be loaded based on the date
        self._viewModel = StateObject(
            wrappedValue: DayActivitiesViewModel(
                apiService: MockAPIService.isMocking 
                    ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
                    : APIService(),
                activities: [] // Will be populated in onAppear
            )
        )
    }
    
    // Alternative initializer for when we already have activities
    init(
        activities: [CalendarActivityDTO],
        onDismiss: @escaping () -> Void,
        onActivitySelected: @escaping (CalendarActivityDTO) -> Void
    ) {
        self.date = activities.first?.date ?? Date()
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
        VStack {
            // Header
            HStack {
                Text(viewModel.formatDate(date))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
            }
            .padding()
            
            if viewModel.activities.isEmpty {
                // Show empty state
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No activities for this day")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                activitiesListView
            }
        }
    }
    
    func getColorForActivity(
        _ activity: CalendarActivityDTO
    ) -> Color {
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
}

extension DayActivitiesView {
    var activitiesListView: some View {
        // Activities list
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.activities, id: \.id) { activity in
                    if let activityId = activity.activityId,
                       let fullActivity = viewModel.getActivity(for: activityId)
                    {
                        // If activity details are available from the view model
                        ActivityCardView(
                            userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                            activity: fullActivity,
                            color: getColorForActivity(activity),
                            callback: { _, _ in
                                onActivitySelected(activity)
                            }
                        )
                    } else {
                        // Show loading state while fetching activity
                        VStack {
                            Text("Loading activity details...")
                            if let activityId = activity.activityId,
                               viewModel.isActivityLoading(activityId)
                            {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
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
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.loadActivitiesIfNeeded()
            }
        }
    }
}

@available(iOS 17, *)
struct DayActivitiesView_Previews: PreviewProvider {
    static var previews: some View {
        DayActivitiesView(
            date: Date(),
            onDismiss: {},
            onActivitySelected: { _ in }
        )
    }
}
