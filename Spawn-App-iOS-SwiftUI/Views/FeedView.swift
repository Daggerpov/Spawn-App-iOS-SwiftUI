//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import PopupView

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var user: ObservableUser
    @StateObject var viewModel: FeedViewModel = FeedViewModel(events: Event.mockEvents)
    
    @Namespace private var animation: Namespace.ID
    
    let mockTags: [FriendTag] = FriendTag.mockTags
    
    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: Event?
    @State private var colorInPopup: Color?

	@State private var showingEventCreationPopup: Bool = false

    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                HeaderView().padding(.top, 50)
                Spacer()
                TagsScrollView(tags: mockTags)
                // TODO: implement logic here to adjust search results when the tag clicked is changed
                Spacer()
                Spacer()
                VStack{
                    eventsListView
                    HStack (spacing: 35) {
                        BottomNavButtonView(buttonType: .map)
                        Spacer()
						EventCreationButtonView(showingEventCreationPopup: $showingEventCreationPopup)
                        Spacer()
                        BottomNavButtonView(buttonType: .friends)
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(universalBackgroundColor)
            .ignoresSafeArea(.container)
            .dimmedBackground(isActive: showingEventDescriptionPopup)
        }
        .popup(isPresented: $showingEventDescriptionPopup) {
            if let event = eventInPopup, let color = colorInPopup {
                EventDescriptionView(
                    event: event,
                    users: User.mockUsers,
                    color: color
                )
            }
        } customize: {
            $0
                .type(.floater(
                    verticalPadding: 20,
                    horizontalPadding: 20,
                    useSafeAreaInset: false
                ))
            // TODO: read up on the documentation: https://github.com/exyte/popupview
            // so that the description view is dismissed upon clicking outside
        }
		.popup(isPresented: $showingEventCreationPopup) {
			EventCreationView(creatingUser: user.user)
		} customize: {
			$0
				.type(.floater(
					verticalPadding: 20,
					horizontalPadding: 20,
					useSafeAreaInset: false
				))
			// TODO: read up on the documentation: https://github.com/exyte/popupview
			// so that the description view is dismissed upon clicking outside
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
                ForEach(viewModel.events) {mockEvent in
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
