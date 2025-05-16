import SwiftUI

struct DayEventsView: View {
    let activities: [CalendarActivityDTO]
    let onDismiss: () -> Void
    let onEventSelected: (CalendarActivityDTO) -> Void
    
    @StateObject private var viewModel: DayEventsViewModel
    
    init(activities: [CalendarActivityDTO], onDismiss: @escaping () -> Void, onEventSelected: @escaping (CalendarActivityDTO) -> Void) {
        self.activities = activities
        self.onDismiss = onDismiss
        self.onEventSelected = onEventSelected
        
        // Initialize the view model
        let apiService: IAPIService = MockAPIService.isMocking
            ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID())
            : APIService()
        
        _viewModel = StateObject(wrappedValue: DayEventsViewModel(apiService: apiService, activities: activities))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Group {
                    if let firstActivity = activities.first {
                        Text(viewModel.formatDate(firstActivity.date))
                            .font(.headline)
                    } else {
                        Text(viewModel.headerTitle)
                            .font(.headline)
                    }
                }
                .padding(.leading)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Text("Done")
                        .foregroundColor(universalAccentColor)
                }
                .padding(.trailing)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            // Events list
            ScrollView {
                VStack(spacing: 15) {
                    ForEach(activities, id: \.id) { activity in
                        if let eventId = activity.eventId, let event = AppCache.shared.getEventById(eventId) {
                            EventCardView(
                                userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                                event: event,
                                color: getColorForEvent(activity, event: event),
                                callback: { _, _ in
                                    onEventSelected(activity)
                                }
                            )
                            .padding(.horizontal)
                        } else {
                            // Fallback if the event is not in the cache
                            HStack {
                                Text("Loading event details...")
                                if let eventId = activity.eventId, viewModel.isEventLoading(eventId) {
                                    ProgressView()
                                        .padding(.leading, 5)
                                }
                            }
                            .padding()
                            .onAppear {
                                if let eventId = activity.eventId {
                                    Task {
                                        await viewModel.fetchEvent(eventId)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .background(universalBackgroundColor)
        .onAppear {
            Task {
                await viewModel.loadEventsIfNeeded()
            }
        }
    }
    
    func getColorForEvent(_ activity: CalendarActivityDTO, event: FullFeedEventDTO? = nil) -> Color {
        // First, check if this is a self-owned event
        if let event = event, event.isSelfOwned == true {
            return universalAccentColor
        }
        
        // Check if the event has a friend tag color
        if let event = event, let hexCode = event.eventFriendTagColorHexCodeForRequestingUser, !hexCode.isEmpty {
            return Color(hex: hexCode)
        }
        
        // Check if activity has a custom color hex code
        if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
            return Color(hex: colorHexCode)
        }
        
        // Fallback to category color
        guard let category = activity.eventCategory else {
            return Color.gray.opacity(0.6) // Default color for null category
        }
        return category.color()
    }
}

#if DEBUG
struct DayEventsView_Previews: PreviewProvider {
    static var previews: some View {
        DayEventsView(
            activities: [
                // Sample activities would go here
            ],
            onDismiss: {},
            onEventSelected: { _ in }
        ).environmentObject(AppCache.shared)
    }
}
#endif 
