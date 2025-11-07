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
    
    // Store background refresh task so we can cancel it on disappear
    @State private var backgroundRefreshTask: Task<Void, Never>?

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
            .task {
                print("📍 [NAV] FeedView .task started")
                let taskStartTime = Date()
                
                // CRITICAL FIX: Load cached activities immediately to unblock UI
                // Cache validation is done on app startup, no need to repeat on every view load
                
                // Load cached activities through view model (fast, non-blocking)
                let cacheLoadStart = Date()
                let activitiesCount: Int = await MainActor.run {
                    viewModel.loadCachedActivities()
                    return viewModel.activities.count
                }
                let cacheLoadDuration = Date().timeIntervalSince(cacheLoadStart)
                let totalDuration = Date().timeIntervalSince(taskStartTime)
                
                print("📊 [NAV] Cache loaded in \(String(format: "%.3f", cacheLoadDuration))s - \(activitiesCount) activities")
                print("⏱️ [NAV] Total UI update took \(String(format: "%.3f", totalDuration))s")
                
                // Refresh from API in background (non-blocking)
                // Only if cache is empty or user explicitly refreshes
                if activitiesCount == 0 {
                    print("🔄 [NAV] Fetching activities from API (empty cache)")
                    let fetchStart = Date()
                    await viewModel.fetchAllData()
                    let fetchDuration = Date().timeIntervalSince(fetchStart)
                    print("⏱️ [NAV] API fetch took \(String(format: "%.2f", fetchDuration))s")
                } else {
                    // Check if task was cancelled before starting background refresh
                    if Task.isCancelled {
                        print("⚠️ [NAV] Task cancelled before starting background refresh - user navigated away")
                        return
                    }
                    
                    // Background refresh without blocking UI
                    // Store the task so we can cancel it if user navigates away
                    print("🔄 [NAV] Starting background refresh for activities")
                    backgroundRefreshTask = Task.detached(priority: .userInitiated) {
                        let refreshStart = Date()
                        await viewModel.fetchAllData()
                        let refreshDuration = Date().timeIntervalSince(refreshStart)
                        print("⏱️ [NAV] Background refresh took \(String(format: "%.2f", refreshDuration))s")
                        print("✅ [NAV] Background refresh completed")
                    }
                }
            }
            .onAppear {
                print("👁️ [NAV] FeedView appeared")
                // Resume timers when view appears
                viewModel.resumeTimers()
            }
            .onDisappear {
                print("👋 [NAV] FeedView disappearing - cancelling background tasks")
                
                // Pause timers to save resources when view is not visible
                viewModel.pauseTimers()
                
                // Cancel any ongoing background refresh to prevent blocking
                backgroundRefreshTask?.cancel()
                backgroundRefreshTask = nil
                print("👋 [NAV] FeedView disappeared")
            }
            .refreshable {
                // Pull to refresh - user-initiated refresh
                async let refreshCache: () = AppCache.shared.refreshActivities()
                async let fetchData: () = viewModel.fetchAllData()
                
                let _ = await (refreshCache, fetchData)
            }
            .onChange(of: showingActivityDescriptionPopup) { _, isShowing in
                if isShowing, let activity = activityInPopup, let color = colorInPopup {
                    // Post notification to show global popup
                    NotificationCenter.default.post(
                        name: .showGlobalActivityPopup,
                        object: nil,
                        userInfo: ["activity": activity, "color": color]
                    )
                    // Reset local state since global popup will handle it
                    showingActivityDescriptionPopup = false
                    activityInPopup = nil
                    colorInPopup = nil
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
