//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
	var user: BaseUserDTO
    @State private var selectedTab: TabType = .home
    @StateObject private var friendsViewModel: FriendsTabViewModel
    @StateObject private var tutorialViewModel = TutorialViewModel.shared
    @StateObject private var inAppNotificationManager = InAppNotificationManager.shared
    @ObservedObject var deepLinkManager: DeepLinkManager
    
    // Deep link state
    @State private var shouldShowDeepLinkedActivity = false
    @State private var deepLinkedActivityId: UUID?
    @State private var shouldShowDeepLinkedProfile = false
    @State private var deepLinkedProfileId: UUID?
    
    // Global activity popup state
    @State private var showingGlobalActivityPopup = false
    @State private var globalPopupActivity: FullFeedActivityDTO?
    @State private var globalPopupColor: Color?
    
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
                ActivityFeedView(
                    user: user, 
                    selectedTab: $selectedTab, 
                    deepLinkedActivityId: $deepLinkedActivityId, 
                    shouldShowDeepLinkedActivity: $shouldShowDeepLinkedActivity
                )
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
                    .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
                ActivityCreationView(
                    creatingUser: user,
                    closeCallback: {
                        // Navigate back to home tab when closing
                        selectedTab = .home
                    },
                    selectedTab: $selectedTab
                )
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
                FriendsView(
                    user: user,
                    viewModel: friendsViewModel,
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
                        .withNotificationBadge(
                            count: friendsViewModel.incomingFriendRequests.count,
                            offset: CGPoint(x: 10, y: -8)
                        )
                        Text("Friends")
                    }
                    .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
                
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
                    .disabled(tutorialViewModel.tutorialState.shouldRestrictNavigation)
            }
            .tint(universalSecondaryColor) // Set the tint color for selected tabs to purple
            .onChange(of: selectedTab) { newTab in
                // Restrict navigation during tutorial
                if tutorialViewModel.tutorialState.shouldRestrictNavigation {
                    if !tutorialViewModel.canNavigateToTab(newTab) {
                        // Revert to previous valid tab
                        selectedTab = .home
                    }
                }
            }
            .onAppear {
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
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkActivityReceived)) { notification in
                if let activityId = notification.userInfo?["activityId"] as? UUID {
                    handleDeepLinkActivity(activityId)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkProfileReceived)) { notification in
                if let profileId = notification.userInfo?["profileId"] as? UUID {
                    handleDeepLinkProfile(profileId)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowActivityFullAlert"))) { notification in
                if let message = notification.userInfo?["message"] as? String {
                    inAppNotificationManager.showNotification(
                        title: "Activity Full",
                        message: message,
                        type: .error,
                        duration: 4.0
                    )
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showGlobalActivityPopup)) { notification in
                if let activity = notification.userInfo?["activity"] as? FullFeedActivityDTO,
                   let color = notification.userInfo?["color"] as? Color {
                    globalPopupActivity = activity
                    globalPopupColor = color
                    showingGlobalActivityPopup = true
                }
            }
            
            // In-app notification overlay
            VStack {
                if inAppNotificationManager.isShowingNotification,
                   let notification = inAppNotificationManager.currentNotification {
                    InAppNotificationView(
                        title: notification.title,
                        message: notification.message,
                        notificationType: notification.type,
                        onDismiss: {
                            inAppNotificationManager.dismissNotification()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1000)
                }
                
                Spacer()
            }
            
            // Global activity popup overlay - covers entire screen including tab bar
            if showingGlobalActivityPopup, let activity = globalPopupActivity, let color = globalPopupColor {
                ActivityPopupDrawer(
                    activity: activity,
                    activityColor: color,
                    isPresented: $showingGlobalActivityPopup,
                    selectedTab: Binding<TabType?>(
                        get: { selectedTab },
                        set: { if let newTab = $0 { selectedTab = newTab } }
                    )
                )
                .allowsHitTesting(true)
                .ignoresSafeArea(.all, edges: .all) // Cover absolutely everything
                .zIndex(999) // Below notifications but above everything else
            }
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLinkActivity(_ activityId: UUID) {
        print("🎯 ContentView: Handling deep link for activity: \(activityId)")
        
        // Switch to home tab to show the activity in feed
        selectedTab = .home
        
        // Add a small delay to ensure tab switching completes before setting deep link state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Set up the deep linked activity state
            deepLinkedActivityId = activityId
            shouldShowDeepLinkedActivity = true
            
            print("🎯 ContentView: Set deep link state - activityId: \(activityId), shouldShow: \(shouldShowDeepLinkedActivity)")
        }
        
        // Clear the deep link manager state
        deepLinkManager.clearPendingDeepLink()
    }
    
    private func handleDeepLinkProfile(_ profileId: UUID) {
        print("🎯 ContentView: Handling deep link for profile: \(profileId)")
        
        // Switch to friends tab to show the profile
        selectedTab = .friends
        
        // Add a small delay to ensure tab switching completes before setting deep link state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Set up the deep linked profile state
            deepLinkedProfileId = profileId
            shouldShowDeepLinkedProfile = true
            
            print("🎯 ContentView: Set deep link state - profileId: \(profileId), shouldShow: \(shouldShowDeepLinkedProfile)")
        }
        
        // Clear the deep link manager state
        deepLinkManager.clearPendingDeepLink()
    }
}

@available(iOS 17.0, *)
#Preview {
	ContentView(user: BaseUserDTO.danielAgapov)
}

func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
	let size = image.size

	// Calculate the scaling factor to fit the image to the target dimensions while maintaining the aspect ratio
	let widthRatio = targetSize.width / size.width
	let heightRatio = targetSize.height / size.height
	let ratio = min(widthRatio, heightRatio)

	let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
	// Add padding by using a percentage of the available space (e.g., 40% from top, 60% from bottom)
	let paddingFactor = 0.9
	let yOffset = (targetSize.height - newSize.height) * paddingFactor

	//Create a new image context
	let renderer = UIGraphicsImageRenderer(size: targetSize)
	let newImage = renderer.image { context in
		// Fill the background with a transparent color
		context.cgContext.setFillColor(UIColor.clear.cgColor)
		context.cgContext.fill(CGRect(origin: .zero, size: targetSize))

		// draw new image
		image.draw(
			in: CGRect(
				x: 0,
				y: yOffset,
				width: newSize.width,
				height: newSize.height
			)
		)
	}

	return newImage
}
