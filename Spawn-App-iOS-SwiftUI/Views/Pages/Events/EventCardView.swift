//
//  EventCardView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct EventCardView: View {
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
        NavigationStack {
            ZStack {
                // "CREATED BY YOU" vertical text on the right side (only if self-owned)
                if event.isSelfOwned == true {
                    HStack{
                        Spacer()
                        // Vertical text container
                        VStack {
                            Text("CREATED BY YOU")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "#98A0E3"))
                                .rotationEffect(.degrees(90))
                                .fixedSize()
                                .frame(height: 15)
                        }
                        .frame(maxHeight: .infinity)
                        .background(Color(hex: "#C2C9FF"))
                        .frame(maxWidth: 30)
                        .padding(.horizontal, 5)
                    }
                    .cornerRadius(universalRectangleCornerRadius)
                }
                HStack{
                    // Main card content
                    VStack {
                        EventCardTopRowView(event: event)
                        HStack {
                            usernamesView
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            VStack {
                                HStack {
                                    EventInfoView(
                                        event: event, eventInfoType: .time)
                                    Spacer()
                                }
                                Spacer()
                                HStack {
                                    // Only show location if it exists
                                    if event.location?.name != nil
                                        && !(event.location?.name.isEmpty ?? true)
                                    {
                                        EventInfoView(
                                            event: event, eventInfoType: .location)
                                        Spacer()
                                    }
                                }
                            }
                            .foregroundColor(.white)
                            Spacer()
                                .frame(width: 30)
                            Circle()
                                .CircularButton(
                                    systemName: event.isSelfOwned == true
                                    ? "pencil"  // Edit icon for self-owned events
                                    : (viewModel.isParticipating
                                       ? "checkmark" : "star.fill"),
                                    buttonActionCallback: {
                                        Task {
                                            if event.isSelfOwned == true {
                                                // Handle edit action
                                                print("Edit event")
                                                // TODO: Implement edit functionality
                                            } else {
                                                // Toggle participation for non-owned events
                                                await viewModel.toggleParticipation()
                                            }
                                        }
                                    })
                        }
                        .frame(alignment: .trailing)
                    }
                    .padding(20)
                    .background(color)
                    .cornerRadius(universalRectangleCornerRadius)
                    if event.isSelfOwned == true {
                        Spacer()
                            .frame(width: 40)
                    }
                }

                
            }
            .onAppear {
                viewModel.fetchIsParticipating()
            }
            .onTapGesture {
                callback(event, color)
            }
        }
    }
}

extension EventCardView {
    var usernamesView: some View {
        let participantCount = (event.participantUsers?.count ?? 0) - 1

        let displayText =
            (event.isSelfOwned == true)
            ? "\(participantCount > 0 ? "You + \(participantCount) more" : "Just you. Invite some friends!")"
            : "@\(event.creatorUser.username)\(participantCount > 0 ? " + \(participantCount) more" : "")"

        return Text(displayText)
            .foregroundColor(Color(.systemGray4))
            .font(.caption)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    EventCardView(
        userId: UUID(),
        event: FullFeedEventDTO.mockDinnerEvent,
        color: universalSecondaryColor,
        callback: { _, _ in }
    )
}
