//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

struct FeedView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()
    // Using AppCache as a singleton instead of environment object

    @Namespace private var animation: Namespace.ID

    @State private var showingActivityDescriptionPopup: Bool = false
    @State private var activityInPopup: FullFeedActivityDTO?
    @State private var colorInPopup: Color?

    @State private var showActivityCreationDrawer: Bool = false

    // for popups:
    @State private var creationOffset: CGFloat = 1000
    // --------
    
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
                    HeaderView(user: user).padding(.top, 75)
                    Spacer()
                    activitiesListView
                }
                .background(universalBackgroundColor)
                .ignoresSafeArea(.container, edges: .top)
                .dimmedBackground(
                    isActive: showActivityCreationDrawer
                )
            }
            .background(universalBackgroundColor)
            .onAppear {
                Task {
                    if !MockAPIService.isMocking {
                        await AppCache.shared.validateCache()
                    }
                    await viewModel.fetchAllData()
                }
            }
            .refreshable {
                Task {
                    await AppCache.shared.refreshActivities()
                    await viewModel.fetchAllData()
                }
            }
            .sheet(isPresented: $showingActivityDescriptionPopup) {
                if let activity = activityInPopup, let color = colorInPopup {
                    ActivityDescriptionView(
                        activity: activity,
                        users: activity.participantUsers,
                        color: color,
                        userId: user.id
                    )
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $showActivityCreationDrawer) {
                ActivityCreationView(
                    creatingUser: user,
                    closeCallback: {
                        showActivityCreationDrawer = false
                    },
                    selectedTab: .constant(TabType.home)
                )
                .presentationDragIndicator(.visible)
            }
        }
    }

    func closeCreation() {
        ActivityCreationViewModel.reInitialize()
        creationOffset = 1000
        showActivityCreationDrawer = false
    }
}

@available(iOS 17.0, *)
#Preview {
    FeedView(user: .danielAgapov)
}

extension FeedView {
    var activitiesListView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 25) {
                if viewModel.activities.isEmpty {
                    Image("ActivityNotFound")
                        .resizable()
                        .frame(width: 125, height: 125)
                    Text("No Activities Found").font(.onestSemiBold(size: 32)).foregroundColor(universalAccentColor)
                    Text("We couldn't find any activities nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                    CreateActivityButton(showActivityCreationDrawer: $showActivityCreationDrawer)
                } else {
                    ForEach(viewModel.activities) { activity in
                        ActivityCardView(
                            userId: user.id,
                            activity: activity,
                            color: getActivityColor(for: activity.id),
                            locationManager: locationManager
                        )
                        { activity, color in
                            activityInPopup = activity
                            colorInPopup = color
                            showingActivityDescriptionPopup = true
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding()
        .padding(.top, 16)
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
