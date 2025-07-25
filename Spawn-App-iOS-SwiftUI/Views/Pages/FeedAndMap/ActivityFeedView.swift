//
//  ActivityFeed.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import SwiftUI

struct ActivityFeedView: View {
    var user: BaseUserDTO
    @StateObject var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @State private var showingActivityPopup: Bool = false
    @State private var activityInPopup: FullFeedActivityDTO?
    @State private var colorInPopup: Color?
    @Binding private var selectedTab: TabType
    private let horizontalSubHeadingPadding: CGFloat = 21
    private let bottomSubHeadingPadding: CGFloat = 14
    @State private var showFullActivitiesList: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Deep link parameters
    @Binding var deepLinkedActivityId: UUID?
    @Binding var shouldShowDeepLinkedActivity: Bool
    @State private var isFetchingDeepLinkedActivity = false
    
    // Tutorial state
    @State private var showTutorialPreConfirmation = false
    @State private var tutorialSelectedActivityType: ActivityTypeDTO?
    
    init(user: BaseUserDTO, selectedTab: Binding<TabType>, deepLinkedActivityId: Binding<UUID?> = .constant(nil), shouldShowDeepLinkedActivity: Binding<Bool> = .constant(false)) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: FeedViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService(), userId: user.id))
        self._selectedTab = selectedTab
        self._deepLinkedActivityId = deepLinkedActivityId
        self._shouldShowDeepLinkedActivity = shouldShowDeepLinkedActivity
    }
    
    var body: some View {
        ZStack {
            // Background color
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(user: user)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 14)
                    .padding(.top, 12)
                // Spawn In! row
                HStack {
                    Text("Spawn in!")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(figmaBlack400)
                    Spacer()
                    seeAllActivityTypesButton
                }
                .padding(.horizontal, horizontalSubHeadingPadding)
                .padding(.bottom, bottomSubHeadingPadding)
                // Activity Types row
                activityTypeListView
                    .padding(.bottom, 19)
                // Activities in Your Area row
                HStack {
                    Text("See what's happening")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(figmaBlack400)
                    Spacer()
                    seeAllActivitiesButton
                }
                .padding(.horizontal, horizontalSubHeadingPadding)
                .padding(.bottom, bottomSubHeadingPadding)
                // Activities
                //activityListView
                ActivityListView(
                    viewModel: viewModel,
                    user: user,
                    callback: { activity, color in
                        activityInPopup = activity
                        colorInPopup = color
                        showingActivityPopup = true
                    },
                    selectedTab: Binding(
                        get: { selectedTab },
                        set: { if let newValue = $0 { selectedTab = newValue } }
                    )
                )
            }
            .onAppear {
                Task {
                    if !MockAPIService.isMocking {
                        await AppCache.shared.validateCache()
                    }
                    await viewModel.fetchAllData()
                }
            }
        }
        .overlay(
            // Custom popup overlay
            Group {
                if showingActivityPopup, let popupActivity = activityInPopup, let color = colorInPopup {
                    ActivityPopupDrawer(
                        activity: popupActivity,
                        activityColor: color,
                        isPresented: $showingActivityPopup
                    )
                }
            }
        )
        .overlay(
            // Tutorial overlay
            TutorialOverlayView()
        )
        .overlay(
            // Tutorial pre-confirmation popup
            Group {
                if showTutorialPreConfirmation, let activityType = tutorialSelectedActivityType {
                    TutorialActivityPreConfirmationView(
                        activityType: activityType.title,
                        onContinue: {
                            showTutorialPreConfirmation = false
                            
                            // Navigate to creation view
                            selectedTab = TabType.creation
                            
                            // Initialize with selected activity type and skip people management if no friends
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                if tutorialViewModel.userHasFriends() {
                                    // Has friends - go through normal flow
                                    ActivityCreationViewModel.initializeWithSelectedActivityType(activityType)
                                } else {
                                    // No friends - skip to date/time selection
                                    ActivityCreationViewModel.initializeWithSelectedActivityType(activityType)
                                    // Set to start at dateTime step instead of activityType
                                    // This will be handled in ActivityCreationView
                                }
                            }
                        },
                        onCancel: {
                            showTutorialPreConfirmation = false
                            tutorialSelectedActivityType = nil
                        }
                    )
                }
            }
        )
        .onChange(of: showingActivityPopup) { isShowing in
            if !isShowing {
                // Clean up when popup is dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    activityInPopup = nil
                    colorInPopup = nil
                }
            }
        }
        .onChange(of: shouldShowDeepLinkedActivity) { shouldShow in
            print("🔗 ActivityFeedView onChange: shouldShowDeepLinkedActivity changed to \(shouldShow), activityId: \(deepLinkedActivityId?.uuidString ?? "nil")")
            if shouldShow, let activityId = deepLinkedActivityId {
                print("🔗 ActivityFeedView onChange: Calling handleDeepLinkedActivity with \(activityId)")
                handleDeepLinkedActivity(activityId)
            }
        }
        .onAppear {
            print("🔗 ActivityFeedView onAppear: shouldShowDeepLinkedActivity = \(shouldShowDeepLinkedActivity), activityId: \(deepLinkedActivityId?.uuidString ?? "nil")")
            
            // Check if tutorial should start
            if tutorialViewModel.tutorialState == .notStarted {
                let hasCompleted = UserDefaults.standard.bool(forKey: "HasCompletedFirstActivityTutorial")
                if !hasCompleted && UserAuthViewModel.shared.hasCompletedOnboarding {
                    tutorialViewModel.startTutorial()
                }
            }
            
            // Handle deep link if one is pending when view appears
            if shouldShowDeepLinkedActivity, let activityId = deepLinkedActivityId {
                print("🔗 ActivityFeedView onAppear: Calling handleDeepLinkedActivity with \(activityId)")
                handleDeepLinkedActivity(activityId)
            }
        }
    }
    
    var seeAllActivityTypesButton: some View {
        Button(action: {
            // Reset activity creation view model to ensure no pre-selection
            ActivityCreationViewModel.reInitialize()
            selectedTab = TabType.creation
        }) {
            seeAllText
        }
    }
    var seeAllActivitiesButton: some View {
        Button(action: {showFullActivitiesList = true}) {
            seeAllText
        }
        .fullScreenCover(isPresented: $showFullActivitiesList) {
            FullscreenActivityListView(viewModel: viewModel, user: user)  { activity, color in
                activityInPopup = activity
                colorInPopup = color
                showingActivityPopup = true
            }
        }
    }
    var seeAllText: some View {
        Text("See All")
            .font(.onestRegular(size: 13))
            .foregroundColor(universalSecondaryColor)
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLinkedActivity(_ activityId: UUID) {
        print("🎯 ActivityFeedView: Handling deep linked activity: \(activityId)")
        
        guard !isFetchingDeepLinkedActivity else {
            print("⚠️ ActivityFeedView: Already fetching deep linked activity, ignoring")
            return
        }
        
        isFetchingDeepLinkedActivity = true
        
        Task {
            do {
                // First check if the activity is already in our current activities list
                if let existingActivity = viewModel.activities.first(where: { $0.id == activityId }) {
                    print("✅ ActivityFeedView: Found activity in current feed: \(existingActivity.title ?? "No title")")
                    await MainActor.run {
                        activityInPopup = existingActivity
                        colorInPopup = ActivityColorService.shared.getColorForActivity(activityId)
                        showingActivityPopup = true
                        shouldShowDeepLinkedActivity = false
                        deepLinkedActivityId = nil
                        isFetchingDeepLinkedActivity = false
                        print("🎯 ActivityFeedView: Set popup state for existing activity - showing: \(showingActivityPopup), activity: \(existingActivity.title ?? "No title")")
                    }
                    return
                }
                
                // If not found in current activities, fetch from API
                print("🔄 ActivityFeedView: Activity not in current feed, fetching from API")
                let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService()
                
                guard let url = URL(string: "\(APIService.baseURL)activities/\(activityId)") else {
                    throw APIError.URLError
                }
                
                // Add autoJoin parameter to automatically join the user to the activity
                let parameters = [
                    "requestingUserId": user.id.uuidString,
                    "autoJoin": "true"
                ]
                let activity: FullFeedActivityDTO = try await apiService.fetchData(from: url, parameters: parameters)
                
                print("✅ ActivityFeedView: Successfully fetched deep linked activity: \(activity.title ?? "No title")")
                
                await MainActor.run {
                    // Ensure we're setting all required state atomically
                    activityInPopup = activity
                    colorInPopup = ActivityColorService.shared.getColorForActivity(activityId)
                    
                    // Clear deep link state first
                    shouldShowDeepLinkedActivity = false
                    deepLinkedActivityId = nil
                    isFetchingDeepLinkedActivity = false
                    
                    // Force a small delay to ensure UI is ready, then show popup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showingActivityPopup = true
                        print("🎯 ActivityFeedView: Set popup state - showing: \(showingActivityPopup), activity: \(activity.title ?? "No title")")
                    }
                }
                
            } catch {
                print("❌ ActivityFeedView: Failed to fetch deep linked activity: \(error)")
                print("❌ ActivityFeedView: Error details - Activity ID: \(activityId), Error: \(error.localizedDescription)")
                await MainActor.run {
                    shouldShowDeepLinkedActivity = false
                    deepLinkedActivityId = nil
                    isFetchingDeepLinkedActivity = false
                }
                
                // Show error to user via InAppNotificationManager
                await MainActor.run {
                    InAppNotificationManager.shared.showNotification(
                        title: "Unable to open activity",
                        message: "The activity you're trying to view might have been deleted or you might not have permission to view it.",
                        type: .error
                    )
                }
            }
        }
    }
}

extension ActivityFeedView {
    var activityTypeListView: some View {
        HStack(spacing: 8) {
            // Show only first 4 activity types (sorted with pinned first) and make them tappable to pre-select
            ForEach(Array(viewModel.sortedActivityTypes.prefix(4)), id: \.id) { activityType in
                ActivityTypeCardView(activityType: activityType) { selectedActivityTypeDTO in
                    handleActivityTypeSelection(selectedActivityTypeDTO)
                }
                .tutorialHighlight(
                    isHighlighted: tutorialViewModel.tutorialState == .activityTypeSelection,
                    cornerRadius: 12
                )
                .allowsHitTesting(
                    !tutorialViewModel.tutorialState.shouldRestrictNavigation || 
                    tutorialViewModel.tutorialState.shouldShowTutorialOverlay
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func handleActivityTypeSelection(_ selectedActivityTypeDTO: ActivityTypeDTO) {
        print("🎯 ActivityFeedView: Activity type '\(selectedActivityTypeDTO.title)' selected")
        
        // Check if we're in tutorial mode
        if case .activityTypeSelection = tutorialViewModel.tutorialState {
            // Tutorial flow
            tutorialSelectedActivityType = selectedActivityTypeDTO
            tutorialViewModel.handleActivityTypeSelection(selectedActivityTypeDTO)
            
            // Show the "You're about to..." popup
            showTutorialPreConfirmation = true
            
        } else {
            // Normal flow
            selectedTab = TabType.creation
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                ActivityCreationViewModel.initializeWithSelectedActivityType(selectedActivityTypeDTO)
            }
        }
    }
}

extension ActivityFeedView {
    var activityListView: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                if viewModel.activities.isEmpty {
                    Image("NoActivitiesFound")
                        .resizable()
                        .frame(width: 125, height: 125)
                    Text("No Activities Found")
                        .font(.onestSemiBold(size:32))
                        .foregroundColor(universalAccentColor)
                    Text("We couldn't find any activities nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                } else {
                    ForEach(0..<viewModel.activities.count, id: \.self) { activityIndex in
                        ActivityCardView(
                            userId: user.id,
                            activity: viewModel.activities[activityIndex],
                            color: figmaBlue,
                            locationManager: locationManager,
                            callback: { activity, color in
                                activityInPopup = activity
                                colorInPopup = color
                                showingActivityPopup = true
                            },
                            selectedTab: Binding(
                                get: { selectedTab },
                                set: { if let newValue = $0 { selectedTab = newValue } }
                            )
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .refreshable {
            Task {
                await AppCache.shared.refreshActivities()
                await viewModel.fetchAllData()
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var tab = TabType.home
    @Previewable @State var deepLinkedActivityId: UUID? = nil
    @Previewable @State var shouldShowDeepLinkedActivity = false
    NavigationView {
        ActivityFeedView(
            user: .danielAgapov, 
            selectedTab: $tab, 
            deepLinkedActivityId: $deepLinkedActivityId, 
            shouldShowDeepLinkedActivity: $shouldShowDeepLinkedActivity
        )
    }
}
