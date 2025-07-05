import SwiftUI

struct ActivityCardView: View {
    @ObservedObject var viewModel: ActivityCardViewModel
    @ObservedObject var activity: FullFeedActivityDTO
    var color: Color
    var callback: (FullFeedActivityDTO, Color) -> Void
    @Environment(\.colorScheme) private var colorScheme
    
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
    
    // Use the same color for both light and dark modes
    private var cardBackgroundColor: Color {
        return color
    }
    
    // Border color for better definition in dark mode
    private var cardBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.clear
        @unknown default:
            return Color.clear
        }
    }
    
    // Shadow configuration for different modes
    private var shadowColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.3)
        case .light:
            return Color.black.opacity(0.10)
        @unknown default:
            return Color.black.opacity(0.10)
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 16) {
                // Top Row: Title, Participants
                ActivityCardTopRowView(activity: activity)
                // Location Row
                ActivityLocationView(activity: activity)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(cardBorderColor, lineWidth: 1)
                    )
            )
            .shadow(color: shadowColor, radius: 8, x: 0, y: 4)
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

extension Color {
    var components: (red: Double, green: Double, blue: Double, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let uiColor = UIColor(self)
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (Double(red), Double(green), Double(blue), Double(alpha))
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
