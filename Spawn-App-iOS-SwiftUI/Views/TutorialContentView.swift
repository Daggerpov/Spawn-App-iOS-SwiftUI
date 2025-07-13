//
//  TutorialContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI

struct TutorialContentView: View {
    var user: BaseUserDTO
    @State private var selectedTab: TabType = .home
    @StateObject private var friendsViewModel: FriendsTabViewModel
    @StateObject private var inAppNotificationManager = InAppNotificationManager.shared
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @ObservedObject var deepLinkManager: DeepLinkManager
    
    // Deep link state
    @State private var shouldShowDeepLinkedActivity = false
    @State private var deepLinkedActivityId: UUID?
    @State private var shouldShowDeepLinkedProfile = false
    @State private var deepLinkedProfileId: UUID?
    
    init(user: BaseUserDTO, deepLinkManager: DeepLinkManager = DeepLinkManager.shared) {
        self.user = user
        self.deepLinkManager = deepLinkManager
        let vm = FriendsTabViewModel(
            userId: user.id,
            apiService: MockAPIService.isMocking
                ? MockAPIService(userId: user.id) : APIService())
        self._friendsViewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Home tab - Use tutorial-aware feed view
                tutorialAwareFeedView
                    .tag(TabType.home)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(named: "home_nav_icon")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                        Text("Home")
                    }
                
                // Map tab
                MapView(user: user)
                    .tag(TabType.map)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(named: "map_nav_icon")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                        Text("Map")
                    }
                
                // Activities tab - Use tutorial-aware activity creation
                tutorialAwareActivityCreationView
                    .tag(TabType.creation)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(named: "activities_nav_icon")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                        Text("Activities")
                    }
                
                // Friends tab
                FriendsView(
                    user: user,
                    deepLinkedProfileId: $deepLinkedProfileId,
                    shouldShowDeepLinkedProfile: $shouldShowDeepLinkedProfile
                )
                    .tag(TabType.friends)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(named: "friends_nav_icon")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                        .withNotificationBadge(count: friendsViewModel.incomingFriendRequests.count)
                        Text("Friends")
                    }
                
                // Profile tab
                NavigationStack {
                    ProfileView(user: user)
                }
                    .tag(TabType.profile)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(named: "profile_nav_icon")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                        Text("Profile")
                    }
            }
            .tint(universalSecondaryColor) // Set the tint color for selected tabs to purple
            .onAppear {
                setupView()
            }
            .onChange(of: deepLinkManager.shouldShowActivity) { shouldShow in
                if shouldShow, let activityId = deepLinkManager.activityToShow {
                    handleDeepLinkActivity(activityId)
                }
            }
            .onChange(of: deepLinkManager.shouldShowProfile) { shouldShow in
                if shouldShow, let profileId = deepLinkManager.profileToShow {
                    handleDeepLinkProfile(profileId)
                }
            }
            .onChange(of: tutorialViewModel.isInTutorial) { isInTutorial in
                // Disable tab switching during tutorial
                if isInTutorial {
                    disableTabSwitching()
                } else {
                    enableTabSwitching()
                }
            }
            
            // In-app notifications
            VStack {
                Spacer()
                InAppNotificationView()
                    .environmentObject(inAppNotificationManager)
                    .padding(.bottom, 100)
            }
        }
    }
    
    // MARK: - Tutorial-Aware Components
    
    private var tutorialAwareFeedView: some View {
        Group {
            if tutorialViewModel.shouldShowTutorialForNewUser() || tutorialViewModel.isInTutorial {
                TutorialActivityFeedView(
                    user: user,
                    selectedTab: $selectedTab,
                    deepLinkedActivityId: $deepLinkedActivityId,
                    shouldShowDeepLinkedActivity: $shouldShowDeepLinkedActivity
                )
            } else {
                ActivityFeedView(
                    user: user,
                    selectedTab: $selectedTab,
                    deepLinkedActivityId: $deepLinkedActivityId,
                    shouldShowDeepLinkedActivity: $shouldShowDeepLinkedActivity
                )
            }
        }
    }
    
    private var tutorialAwareActivityCreationView: some View {
        Group {
            if tutorialViewModel.shouldShowTutorialForNewUser() || tutorialViewModel.isInTutorial {
                TutorialActivityCreationView(
                    creatingUser: user,
                    closeCallback: {
                        selectedTab = .home
                    },
                    selectedTab: $selectedTab
                )
            } else {
                ActivityCreationView(
                    creatingUser: user,
                    closeCallback: {
                        selectedTab = .home
                    },
                    selectedTab: $selectedTab
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupView() {
        // Configure tab bar appearance for theme compatibility
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.systemBackground.withAlphaComponent(0.9)
            default:
                return UIColor.systemBackground.withAlphaComponent(0.9)
            }
        }
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor.label
            default:
                return UIColor.label
            }
        }
        
        // Fetch friend requests to show badge count
        Task {
            await friendsViewModel.fetchIncomingFriendRequests()
        }
        
        // Check if we should start the tutorial for a new user
        if tutorialViewModel.shouldShowTutorialForNewUser() {
            tutorialViewModel.startTutorial()
        }
    }
    
    private func handleDeepLinkActivity(_ activityId: UUID) {
        deepLinkedActivityId = activityId
        shouldShowDeepLinkedActivity = true
        selectedTab = .home
        deepLinkManager.clearActivityDeepLink()
    }
    
    private func handleDeepLinkProfile(_ profileId: UUID) {
        deepLinkedProfileId = profileId
        shouldShowDeepLinkedProfile = true
        selectedTab = .friends
        deepLinkManager.clearProfileDeepLink()
    }
    
    private func disableTabSwitching() {
        // During tutorial, users can only interact with the focused elements
        // Tab switching is handled by the tutorial system
    }
    
    private func enableTabSwitching() {
        // Re-enable normal tab switching after tutorial
    }
}

// MARK: - Tutorial Integration with User Registration

extension UserAuthViewModel {
    /// Triggers the tutorial for a newly registered user
    func triggerTutorialForNewUser() {
        // Only trigger if user hasn't completed tutorial
        if TutorialViewModel.shared.shouldShowTutorialForNewUser() {
            TutorialViewModel.shared.startTutorial()
        }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Utility function to resize images for tab bar icons
    func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if (widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }
        
        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
} 