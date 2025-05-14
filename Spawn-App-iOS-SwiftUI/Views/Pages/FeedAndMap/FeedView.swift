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
    @State private var creationOffset: CGFloat = 1000
    // --------
    
    @State private var activeTag: FilterTag? = nil

    var user: BaseUserDTO

    init(user: BaseUserDTO) {
        self.user = user
        _viewModel = StateObject(
            wrappedValue: FeedViewModel(
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService(),
                userId: user.id
            )
        )
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack {
                    Spacer()
                    HeaderView(user: user, numEvents: viewModel.events.count).padding(.top, 50)
                    Spacer()
                    TagsScrollView(activeTag: $activeTag)
                    Spacer()
                    Spacer()
                    VStack {
                        eventsListView
                    }
                    .padding(.horizontal)
                }
                .padding()
                .background(universalBackgroundColor)
                .ignoresSafeArea(.container)
                .dimmedBackground(
                    isActive: showEventCreationDrawer
                )
//                .gesture(
//                    DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
//                        .onEnded { value in
//                            switch (
//                                value.translation.width,
//                                value.translation.height
//                            ) {
//                            case (...0, -30...30):  // left swipe
//                                if let currentIndex = viewModel.tags.firstIndex(
//                                    where: { $0.displayName == viewModel.activeTag?.id }
//                                ),
//                                    currentIndex < viewModel.tags.count - 1
//                                {
//                                    viewModel.activeTag =
//                                        viewModel.tags[currentIndex + 1]
//                                }
//                            case (0..., -30...30):  // right swipe
//                                if let currentIndex = viewModel.tags.firstIndex(
//                                    where: { $0.id == viewModel.activeTag?.id }
//                                ),
//                                    currentIndex > 0
//                                {
//                                    viewModel.activeTag =
//                                        viewModel.tags[currentIndex - 1]
//                                }
//                            default: break
//                            }
//                        }
//                )
            }
            .background(universalBackgroundColor)
            .onAppear {
                guard ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" else {
                        return
                    }
                Task {
                    if !MockAPIService.isMocking {
                        await appCache.validateCache()
                    }
                    await viewModel.fetchAllData()
                }
            }
            .refreshable {
                Task {
                    await appCache.refreshEvents()
                    await viewModel.fetchAllData()
                }
            }
            .onChange(of: self.activeTag) { _ in
                Task {
                    await viewModel.fetchEventsForUser()
                }
            }
            .sheet(isPresented: $showingEventDescriptionPopup) {
                if let event = eventInPopup, let color = colorInPopup {
                    EventDescriptionView(
                        event: event,
                        users: event.participantUsers,
                        color: color,
                        userId: user.id
                    )
                    .presentationDragIndicator(.visible)
                }
            }
        }
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
    var eventsListView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 25) {
                if viewModel.events.isEmpty {
                    Spacer()
                    Spacer()
                    Image("EventNotFound")
                    Text("No Events Found").font(.onestSemiBold(size: 32))
                    Text("We couldn't find any events nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                    Spacer()
                    CreateEventButton(showEventCreationDrawer: $showEventCreationDrawer)
                } else {
                    Spacer()
                    ForEach(viewModel.events) { event in
                        EventCardView(
                            userId: user.id,
                            event: event,
                            color: Color(
                            hex: event
                                .eventFriendTagColorHexCodeForRequestingUser
                                ?? eventColorHexCodes[0])
                        )
                        { event, color in
                            eventInPopup = event
                            colorInPopup = color
                            showingEventDescriptionPopup = true
                        }
                        Spacer()
                        Spacer()
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
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
