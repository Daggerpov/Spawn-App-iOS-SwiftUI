import SwiftUI

struct UserEventsSection: View {
    let user: Nameable
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var showEventDetails: Bool
    
    var body: some View {
        Group {
            if profileViewModel.friendshipStatus == .friends {
                friendEventsSection
            } else {
                addToSeeEventsSection
            }
        }
    }
    
    // User Events Section for friend profiles
    private var friendEventsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upcoming Events by \(FormatterService.shared.formatFirstName(user: user))")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.horizontal)
            
            if profileViewModel.isLoadingUserEvents {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if profileViewModel.userEvents.isEmpty {
                Text("No upcoming events")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(profileViewModel.userEvents) { event in
                            EventCardView(
                                userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
                                event: event,
                                color: event.isSelfOwned == true ? universalAccentColor : determineEventColor(for: event),
                                callback: { selectedEvent, color in
                                    profileViewModel.selectedEvent = selectedEvent
                                    showEventDetails = true
                                }
                            )
                            .frame(width: 300, height: 180)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack {
                Spacer()
                Button(action: {
                    // Navigate to all events by this user
                }) {
                    Text("Show All")
                        .font(.subheadline)
                        .foregroundColor(universalSecondaryColor)
                }
                .padding(.trailing)
            }
        }
        .padding(.bottom, 15)
    }
    
    // "Add to see events" section for non-friends
    private var addToSeeEventsSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 28))
                .foregroundColor(Color.gray.opacity(0.7))
            
            Text("Add \(FormatterService.shared.formatFirstName(user: user)) to see their upcoming spawns!")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(Color.gray)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
        .padding(.horizontal)
        .padding(.vertical, 20)
    }
    
    private func determineEventColor(for event: FullFeedEventDTO) -> Color {
        // Logic to determine event color based on friend tag or category
        if let hexCode = event.eventFriendTagColorHexCodeForRequestingUser, !hexCode.isEmpty {
            return Color(hex: hexCode)
        } else {
            return event.category.color()
        }
    }
}

#Preview {
    UserEventsSection(
        user: BaseUserDTO.danielAgapov,
        profileViewModel: ProfileViewModel(),
        showEventDetails: .constant(false)
    )
} 
