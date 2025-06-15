import SwiftUI

struct ActivityCardView: View {
    @ObservedObject var viewModel: ActivityCardViewModel
    var activity: FullFeedActivityDTO
    var color: Color
    var callback: (FullFeedActivityDTO, Color) -> Void
    
    
    init(
        userId: UUID, activity: FullFeedActivityDTO, color: Color,
        callback: @escaping (FullFeedActivityDTO, Color) -> Void
    ) {
        self.activity = activity
        self.color = color
        self.viewModel = ActivityCardViewModel(
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService(), userId: userId,
            activity: activity)
        self.callback = callback
        
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Row: Title, Participants
                ActivityCardTopRowView(activity: activity)
                // Location Row
                ActivityLocationView(activity: activity)
                // Description Row
                //EventCardInfoView(event: event)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(color)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
            .onAppear {
                viewModel.fetchIsParticipating()
            }
            .onTapGesture {
                callback(activity, color)
            }

            // Time Status Badge
            ActivityStatusView(activity: activity)
        }
    }
}

#Preview {
    let mockUserId: UUID = UUID()
    ActivityCardView(
        userId: mockUserId,
        activity: .mockDinnerActivity,
        color: figmaSoftBlue
    ) { event, color in
        print("Event tapped: \(event.title ?? "Untitled")")
    }
}
