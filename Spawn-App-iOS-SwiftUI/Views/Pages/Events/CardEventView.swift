import SwiftUI

struct CardEventView: View {
    @ObservedObject var viewModel: EventCardViewModel
    var event: FullFeedEventDTO
    var color: Color
    var callback: (FullFeedEventDTO, Color) -> Void
    
    init(
        userId: UUID, event: FullFeedEventDTO, color: Color,
        callback: @escaping (FullFeedEventDTO, Color) -> Void
    ) {
        self.event = event
        self.color = color
        self.viewModel = EventCardViewModel(
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService(), userId: userId,
            event: event)
        self.callback = callback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Row: Title, Participants
            EventCardTopRowView(event: event)
            // Location Row
            EventLocationView(event: event)
            // Description Row
            EventCardInfoView(event: event)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.48, green: 0.60, blue: 1.0))
        )
        .frame(height: 130)
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
        .onAppear {
            viewModel.fetchIsParticipating()
        }
        .onTapGesture {
            callback(event, color)
        }
    }
}
