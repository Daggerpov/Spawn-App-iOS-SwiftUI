//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @EnvironmentObject private var appCache: AppCache

    @Namespace private var animation: Namespace.ID

    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: FullFeedEventDTO?
    @State private var colorInPopup: Color?

    @State private var showEventCreationDrawer: Bool = false

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
                        || showEventCreationDrawer
                )
                .gesture(
                    DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                        .onEnded { value in
                            switch (
                                value.translation.width,
                                value.translation.height
                            ) {
                            case (...0, -30...30):  // left swipe
                                if let currentIndex = viewModel.tags.firstIndex(
                                    where: { $0.id == viewModel.activeTag?.id }
                                ),
                                    currentIndex < viewModel.tags.count - 1
                                {
                                    viewModel.activeTag =
                                        viewModel.tags[currentIndex + 1]
                                }
                            case (0..., -30...30):  // right swipe
                                if let currentIndex = viewModel.tags.firstIndex(
                                    where: { $0.id == viewModel.activeTag?.id }
                                ),
                                    currentIndex > 0
                                {
                                    viewModel.activeTag =
                                        viewModel.tags[currentIndex - 1]
                                }
                            default: break
                            }
                        }
                )
            }
            .background(universalBackgroundColor)
            .onAppear {
                Task {
                    await appCache.validateCache()
                    await viewModel.fetchAllData()
                }
            }
            .refreshable {
                Task {
                    await appCache.refreshEvents()
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
        }
    }
    func closeDescription() {
        descriptionOffset = 1000
        showingEventDescriptionPopup = false
    }

    func closeCreation() {
        EventCreationViewModel.reInitialize()
        creationOffset = 1000
        showEventCreationDrawer = false
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FeedView(user: .danielAgapov).environmentObject(appCache)
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
                    .cornerRadius(universalRectangleCornerRadius)
                    .padding(.horizontal)
                    .padding(
                        .vertical,
                        min(
                            250,
                            250
                                - CGFloat(
                                    (event.chatMessages?.count ?? 0) > 2
                                        ? 100 : 0)
                                - CGFloat(event.note != nil ? 50 : 0)
                        )
                    )
                    .padding(.top, 100)

                }
                .ignoresSafeArea()
            }
        }
    }
    var bottomButtonsView: some View {
        HStack(spacing: 35) {
            BottomNavButtonView(user: user, buttonType: .map)
            Spacer()
            EventCreationButtonView(
                showEventCreationDrawer: $showEventCreationDrawer
            )
            .sheet(isPresented: $showEventCreationDrawer) {
                EventCreationView(
                    creatingUser: user, feedViewModel: viewModel,
                    closeCallback: closeCreation
                )
                .presentationDragIndicator(.visible)
            }
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
