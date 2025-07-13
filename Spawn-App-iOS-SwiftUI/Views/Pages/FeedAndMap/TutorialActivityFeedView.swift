//
//  TutorialActivityFeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import SwiftUI

struct TutorialActivityFeedView: View {
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
    @State private var showLoadingScreen: Bool = true
    
    // Deep link parameters
    @Binding var deepLinkedActivityId: UUID?
    @Binding var shouldShowDeepLinkedActivity: Bool
    @State private var isFetchingDeepLinkedActivity = false
    
    init(user: BaseUserDTO, selectedTab: Binding<TabType>, deepLinkedActivityId: Binding<UUID?> = .constant(nil), shouldShowDeepLinkedActivity: Binding<Bool> = .constant(false)) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: FeedViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService(), userId: user.id))
        self._selectedTab = selectedTab
        self._deepLinkedActivityId = deepLinkedActivityId
        self._shouldShowDeepLinkedActivity = shouldShowDeepLinkedActivity
    }
    
    var body: some View {
        ZStack {
            if showLoadingScreen {
                TutorialLoadingScreen {
                    handleLoadingComplete()
                }
            } else {
                mainFeedContent
            }
        }
        .onAppear {
            setupTutorialIfNeeded()
            loadData()
        }
        .sheet(isPresented: $showingActivityPopup) {
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
    }
    
    private var mainFeedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, 16)
                
                // Main content
                VStack(spacing: 24) {
                    // Activity types section
                    activityTypesSection
                    
                    // Activities section
                    activitiesSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100) // Bottom padding for tab bar
            }
        }
        .background(Color.white)
        .overlay(
            tutorialOverlay
        )
        .refreshable {
            await refreshData()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Greeting
            HStack {
                Text("Hey \(user.firstName ?? "there")! 👋")
                    .font(Font.custom("Onest", size: 32).weight(.bold))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var activityTypesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Text("Spawn in!")
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                
                Spacer()
                
                Button("See All") {
                    // Handle see all action
                }
                .font(Font.custom("Onest", size: 12).weight(.medium))
                .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98))
            }
            
            // Activity types grid
            tutorialAwareActivityTypeGrid
        }
    }
    
    private var tutorialAwareActivityTypeGrid: some View {
        HStack(spacing: 8) {
            ForEach(Array(viewModel.sortedActivityTypes.prefix(4)), id: \.id) { activityType in
                let isInTutorial = tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .feedViewActivityTypes
                let canInteract = !isInTutorial || tutorialViewModel.canInteractWithUI
                
                ActivityTypeCardView(activityType: activityType) { selectedActivityTypeDTO in
                    handleActivityTypeSelection(selectedActivityTypeDTO)
                }
                .tutorialFocusable(isFocused: canInteract) {
                    handleActivityTypeSelection(activityType)
                }
                .scaleEffect(isInTutorial ? 1.0 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isInTutorial)
            }
        }
    }
    
    private var activitiesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack {
                Text("See what's happening")
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(Color(red: 0.40, green: 0.38, blue: 0.38))
                
                Spacer()
                
                Button("See All") {
                    // Handle see all action
                }
                .font(Font.custom("Onest", size: 12).weight(.medium))
                .foregroundColor(Color(red: 0.42, green: 0.51, blue: 0.98))
            }
            
            // Activities list
            activityListView
        }
    }
    
    private var activityListView: some View {
        VStack(spacing: 14) {
            if viewModel.activities.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 143, height: 143)
                        .background(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                    
                    Text("No Activities Found")
                        .font(Font.custom("Onest", size: 32).weight(.semibold))
                        .foregroundColor(.black)
                    
                    Text("We couldn't find any activities happening nearby. Start one yourself and be spontaneous!")
                        .font(Font.custom("Onest", size: 16).weight(.medium))
                        .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                ForEach(0..<viewModel.activities.count, id: \.self) { activityIndex in
                    ActivityCardView(
                        userId: user.id,
                        activity: viewModel.activities[activityIndex],
                        color: Color(red: 0.42, green: 0.51, blue: 0.98),
                        locationManager: locationManager,
                        callback: { activity, color in
                            activityInPopup = activity
                            colorInPopup = color
                            showingActivityPopup = true
                        },
                        deleteCallback: { activityId in
                            viewModel.deleteActivity(activityId: activityId)
                        }
                    )
                }
            }
        }
    }
    
    private var tutorialOverlay: some View {
        ZStack {
            // Tutorial overlay for feed view activity types
            if tutorialViewModel.isInTutorial && tutorialViewModel.currentStep == .feedViewActivityTypes {
                TutorialFeedActivityTypesOverlay(
                    activityTypes: viewModel.sortedActivityTypes,
                    onActivityTypeSelected: handleActivityTypeSelection
                )
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupTutorialIfNeeded() {
        if tutorialViewModel.shouldShowTutorialForNewUser() && !tutorialViewModel.isInTutorial {
            tutorialViewModel.startTutorial()
        }
    }
    
    private func loadData() {
        Task {
            await viewModel.fetchAllData()
            
            // Check if activity types are loaded
            if !viewModel.sortedActivityTypes.isEmpty {
                tutorialViewModel.enableUIInteraction()
                
                // Hide loading screen if not in tutorial or if tutorial is ready
                if !tutorialViewModel.isInTutorial || tutorialViewModel.canInteractWithUI {
                    showLoadingScreen = false
                }
            }
        }
    }
    
    private func handleLoadingComplete() {
        showLoadingScreen = false
        tutorialViewModel.enableUIInteraction()
    }
    
    private func refreshData() async {
        await AppCache.shared.refreshActivities()
        await viewModel.fetchAllData()
    }
    
    private func handleActivityTypeSelection(_ activityType: ActivityTypeDTO) {
        guard tutorialViewModel.canInteractWithUI else { return }
        
        print("🎯 TutorialActivityFeedView: Activity type '\(activityType.title)' selected")
        
        // Set the selected activity type for tutorial
        tutorialViewModel.setSelectedActivityType(activityType)
        
        // If in tutorial, advance to next step
        if tutorialViewModel.isInTutorial {
            tutorialViewModel.nextStep()
        }
        
        // Navigate to creation tab
        selectedTab = TabType.creation
        
        // Pre-select the activity type
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            ActivityCreationViewModel.initializeWithSelectedActivityType(activityType)
        }
    }
} 