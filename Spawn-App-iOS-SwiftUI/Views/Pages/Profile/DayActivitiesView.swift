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
        
        // Initialize the view model with the date
        self._viewModel = StateObject(
            wrappedValue: DayActivitiesViewModel(
                date: date,
                apiService: MockAPIService.isMocking 
                    ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
                    : APIService()
            )
        )
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Text(DateFormatter.dayMonthYear.string(from: date))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    onDismiss()
                }
            }
            .padding()
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                activitiesListView
            }
        }
    }
    
    func getColorForActivity(
        _ activity: CalendarActivityDTO,
        activity: FullFeedActivityDTO? = nil
    ) -> Color {
        // First, check if this is a self-owned activity
        if let activity = activity, activity.isSelfOwned == true {
            return universalAccentColor
        }
        
        // If we have a color hex code from the backend, use it
        if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
            return Color(hex: colorHex)
        }
        
        // Otherwise, use the category color
        guard let category = activity.activityCategory else {
            return .gray
        }
        
        return category.color()
    }
}

extension DayActivitiesView {
    var activitiesListView: some View {
        // Activities list
        ScrollView {
            LazyVStack(spacing: 15) {
                ForEach(viewModel.activities, id: \.id) { activity in
                    if let activityId = activity.activityId,
                       let activity = viewModel.getActivity(for: activityId)
                    {
                        // If activity details are available from the view model
                        ActivityCardView(
                            userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                            activity: activity,
                            color: getColorForActivity(activity, activity: activity),
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
