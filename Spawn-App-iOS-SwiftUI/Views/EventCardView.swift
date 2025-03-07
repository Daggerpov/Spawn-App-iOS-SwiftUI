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
			VStack {
				EventCardTopRowView(event: event)
				HStack{
					usernamesView
					Spacer()
				}
				Spacer()
				HStack {
					VStack {
						HStack {
							EventInfoView(event: event, eventInfoType: .time)
							Spacer()
						}
						Spacer()
						HStack {
							EventInfoView(
								event: event, eventInfoType: .location)
							Spacer()
						}
					}
					.foregroundColor(.white)
					Spacer()
						.frame(width: 30)
					Circle()
						.CircularButton(
							systemName: viewModel.isParticipating
								? "checkmark" : "star.fill",
							buttonActionCallback: {
								Task {
									await viewModel.toggleParticipation()
								}
							})
				}
				.frame(alignment: .trailing)
			}
			.padding(20)
			.background(color)
			.cornerRadius(universalRectangleCornerRadius)
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
		let participantCount = (event.participantUsers?.count ?? 0) - 1 // Subtract 1 to exclude creator
		let invitedCount = event.invitedUsers?.count ?? 0
		let totalCount = participantCount + invitedCount
		
		let displayText = (event.isSelfOwned == true) 
			? "You\(totalCount > 0 ? " + \(totalCount) more" : "")"
			: "@\(event.creatorUser.username)\(totalCount > 0 ? " + \(totalCount) more" : "")"
		
		return Text(displayText)
			.foregroundColor(.white)
			.font(.caption)
	}
}

#Preview {
	EventCardView(
		userId: UUID(),
		event: FullFeedEventDTO.mockDinnerEvent,
		color: universalSecondaryColor,
		callback: {_, _ in}
	)
}
