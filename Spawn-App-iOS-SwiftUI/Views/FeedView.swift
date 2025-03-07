//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

struct FeedView: View {
	@StateObject private var viewModel: FeedViewModel

	@Namespace private var animation: Namespace.ID

	@State private var showingEventDescriptionPopup: Bool = false
	@State private var eventInPopup: FullFeedEventDTO?
	@State private var colorInPopup: Color?

	@State private var showingEventCreationPopup: Bool = false

	// for popups:
	@State private var descriptionOffset: CGFloat = 1000
	@State private var creationOffset: CGFloat = 1000
	// --------

	var user: BaseUserDTO

	init(user: BaseUserDTO) {
		self.user = user
		_viewModel = StateObject(
			wrappedValue: FeedViewModel(
				apiService: MockAPIService.isMocking
					? MockAPIService(userId: user.id) : APIService(),
				userId: user.id))
	}

	var body: some View {
		ZStack {
			NavigationStack {
				VStack {
					Spacer()
					HeaderView(user: user).padding(.top, 50)
					Spacer()
					TagsScrollView(
						tags: viewModel.tags,
						activeTag: $viewModel.activeTag
					)
					Spacer()
					Spacer()
					VStack {
						eventsListView
						bottomButtonsView
					}
					.padding(.horizontal)
				}
				.padding()
				.background(universalBackgroundColor)
				.ignoresSafeArea(.container)
				.dimmedBackground(
					isActive: showingEventDescriptionPopup
						|| showingEventCreationPopup
				)
			}
			.background(universalBackgroundColor)
			.onAppear {
				Task {
					await viewModel.fetchAllData()
				}
			}
			.onChange(of: viewModel.activeTag) { _ in
				Task {
					await viewModel.fetchEventsForUser()
				}
			}
			if showingEventDescriptionPopup {
				eventDescriptionPopupView
			}
			if showingEventCreationPopup {
				eventCreationPopupView
			}
		}
	}
	func closeDescription() {
		descriptionOffset = 1000
		showingEventDescriptionPopup = false
	}

	func closeCreation() {
		EventCreationViewModel.reInitialize()
		creationOffset = 1000
		showingEventCreationPopup = false
	}
}

@available(iOS 17.0, *)
#Preview {
	FeedView(user: .danielAgapov)
}

extension FeedView {
	var eventDescriptionPopupView: some View {
		Group {
			if let event = eventInPopup, let color = colorInPopup {
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeDescription()
						}

					EventDescriptionView(
						event: event,
						users: event.participantUsers,
						color: color,
						userId: user.id
					)
					.offset(x: 0, y: descriptionOffset)
					.onAppear {
						descriptionOffset = 0
					}
					.padding(.horizontal)
					// brute-force algorithm I wrote
					.padding(
						.vertical,
						max(
							330,
							330
								- CGFloat(
									100 * (event.chatMessages?.count ?? 0))
								- CGFloat(event.note != nil ? 200 : 0))
					)
				}
				.ignoresSafeArea()
			}
		}
	}
	var eventCreationPopupView: some View {
		ZStack {
			Color(.black)
				.opacity(0.5)
				.onTapGesture {
					closeCreation()
				}
				.ignoresSafeArea()

			EventCreationView(creatingUser: user, closeCallback: closeCreation)
				.offset(x: 0, y: creationOffset)
				.onAppear {
					creationOffset = 0
				}
				.padding(32)
				.cornerRadius(universalRectangleCornerRadius)
				.padding(.bottom, 50)
		}
	}
	var bottomButtonsView: some View {
		HStack(spacing: 35) {
			BottomNavButtonView(user: user, buttonType: .map)
			Spacer()
			EventCreationButtonView(
				showingEventCreationPopup:
					$showingEventCreationPopup)
			Spacer()
			BottomNavButtonView(user: user, buttonType: .friends)
		}
	}
	var eventsListView: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 15) {
				if viewModel.events.isEmpty {
					Text("Add some friends to see what they're up to!")
						.foregroundColor(universalAccentColor)
				} else {
					ForEach(viewModel.events) { event in
						EventCardView(
							userId: user.id,
							event: event,
							color: Color(
								hex: event
									.eventFriendTagColorHexCodeForRequestingUser
									?? eventColorHexCodes[0])
						) { event, color in
							eventInPopup = event
							colorInPopup = color
							showingEventDescriptionPopup = true
						}
					}
				}
			}
		}
	}
}

extension View {
	func dimmedBackground(isActive: Bool) -> some View {
		self.overlay(
			Group {
				if isActive {
					Color.black.opacity(0.5)
						.ignoresSafeArea()
						.transition(.opacity)
						.animation(.easeInOut, value: isActive)
				}
			}
		)
	}
}
