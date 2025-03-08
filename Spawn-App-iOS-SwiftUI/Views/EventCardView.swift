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

                // "CREATED BY YOU" vertical text on the right side (only if self-owned)
                if event.isSelfOwned == true {
                    HStack {
                        Spacer()
                        
                        // Vertical text container
                        VStack {
                            Text("CREATED BY YOU")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(90))
                                .fixedSize()
                                .frame(height: 15)
                        }
                        .padding(.trailing, -8)
                        .frame(maxHeight: .infinity)
                        .background(Color.clear)
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
        let participantCount = (event.participantUsers?.count ?? 0) - 1  // Subtract 1 to exclude creator
        let invitedCount = event.invitedUsers?.count ?? 0
        let totalCount = participantCount + invitedCount

        let displayText =
            (event.isSelfOwned == true)
            ? "You\(totalCount > 0 ? " + \(totalCount) more" : "")"
            : "@\(event.creatorUser.username)\(totalCount > 0 ? " + \(totalCount) more" : "")"

        return Text(displayText)
            .foregroundColor(Color(.systemGray4))
            .font(.caption)
    }
}

#Preview {
    EventCardView(
        userId: UUID(),
        event: FullFeedEventDTO.mockDinnerEvent,
        color: universalSecondaryColor,
        callback: { _, _ in }
    )
}
