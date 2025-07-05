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
    @State private var showingActivityPopup: Bool = false
    @State private var activityInPopup: FullFeedActivityDTO?
    @State private var colorInPopup: Color?
    @Binding private var selectedTab: TabType
    private let horizontalSubHeadingPadding: CGFloat = 21
    private let bottomSubHeadingPadding: CGFloat = 14
    @State private var showFullActivitiesList: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    init(user: BaseUserDTO, selectedTab: Binding<TabType>) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: FeedViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService(), userId: user.id))
        self._selectedTab = selectedTab
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
                    Text("Spawn In!")
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
                    Text("See What's Happening!")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(figmaBlack400)
                    Spacer()
                    seeAllActivitiesButton
                }
                .padding(.horizontal, horizontalSubHeadingPadding)
                .padding(.bottom, bottomSubHeadingPadding)
                // Activities
                //activityListView
                ActivityListView(viewModel: viewModel, user: user, bound: 3) { activity, color in
                    activityInPopup = activity
                    colorInPopup = color
                    showingActivityPopup = true
                }
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
        .onChange(of: showingActivityPopup) { isShowing in
            if !isShowing {
                // Clean up when popup is dismissed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    activityInPopup = nil
                    colorInPopup = nil
                }
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
}

extension ActivityFeedView {
    var activityTypeListView: some View {
        HStack(spacing: 12) {
            // Show only first 4 activity types and make them tappable to pre-select
            ForEach(Array(viewModel.activityTypes.prefix(4)), id: \.id) { activityType in
                ActivityTypeCardView(activityType: activityType) { selectedActivityType in
                    // Pre-select the activity type and navigate to creation
                    ActivityCreationViewModel.initializeWithSelectedType(selectedActivityType)
                    selectedTab = TabType.creation
                }
            }
        }
        .padding(.horizontal, 20)
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
                    Text("We couldn't find any events nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                } else {
                    ForEach(0..<min(3, viewModel.activities.count), id: \.self) { activityIndex in
                        ActivityCardView(userId: user.id, activity: viewModel.activities[activityIndex], color: figmaBlue) { activity, color in
                            activityInPopup = activity
                            colorInPopup = color
                            showingActivityPopup = true
                        }
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
    NavigationView {
        ActivityFeedView(user: .danielAgapov, selectedTab: $tab)
    }
    
}
