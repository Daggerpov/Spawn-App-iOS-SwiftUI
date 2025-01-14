//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

struct FeedView: View {
	@EnvironmentObject var user: ObservableUser
	@StateObject var viewModel: FeedViewModel = FeedViewModel(
		events: Event.mockEvents)

	@Namespace private var animation: Namespace.ID

	let mockTags: [FriendTag] = FriendTag.mockTags

	@State private var showingEventDescriptionPopup: Bool = false
	@State private var eventInPopup: Event?
	@State private var colorInPopup: Color?

	@State private var showingEventCreationPopup: Bool = false

	@State private var descriptionOffset: CGFloat = 1000
	@State private var creationOffset: CGFloat = 1000

	var body: some View {
		ZStack {
		NavigationStack {
				VStack {
					Spacer()
					HeaderView().padding(.top, 50)
					Spacer()
					TagsScrollView(tags: mockTags)
					// TODO: implement logic here to adjust search results when the tag clicked is changed
					Spacer()
					Spacer()
					VStack {
						eventsListView
						HStack(spacing: 35) {
							BottomNavButtonView(buttonType: .map)
							Spacer()
							EventCreationButtonView(
								showingEventCreationPopup:
									$showingEventCreationPopup)
							Spacer()
							BottomNavButtonView(buttonType: .friends)
						}
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
			if showingEventDescriptionPopup {
				if let event = eventInPopup, let color = colorInPopup {
					ZStack {
						Color(.black)
							.opacity(0.5)
							.onTapGesture {
								closeDescription()
							}

						EventDescriptionView(
							event: event,
							users: User.mockUsers,
							color: color
						)
						.offset(x: 0, y: descriptionOffset)
						.onAppear {
							withAnimation(.spring()) {
								descriptionOffset = 0
							}
						}
					}
					.ignoresSafeArea()
				}
			}
			if showingEventCreationPopup {
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeCreation()
						}

					EventCreationView(creatingUser: user.user)
					.offset(x: 0, y: creationOffset)
					.onAppear {
						withAnimation(.spring()) {
							creationOffset = 0
						}
					}
				}
				.ignoresSafeArea()
			}
		}
	}
	func closeDescription() {
		withAnimation(.spring()) {
			descriptionOffset = 1000
			showingEventDescriptionPopup = false
		}
	}

	func closeCreation() {
		withAnimation(.spring()) {
			creationOffset = 1000
			showingEventCreationPopup = false
		}
	}
}
@available(iOS 17.0, *)
#Preview {
	@Previewable
	@StateObject var observableUser = ObservableUser(user: .danielLee)

	FeedView()
		.environmentObject(observableUser)
}

extension FeedView {
	var eventsListView: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 15) {
				ForEach(viewModel.events) { mockEvent in
					EventCardView(
						user: user.user,
						event: mockEvent,
						// TODO: change this logic to be based on the event in relation to which friend tag the creator belongs to
						color: eventColors.randomElement() ?? Color.blue
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
