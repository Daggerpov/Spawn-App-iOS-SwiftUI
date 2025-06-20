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
    private let horizontalSubHeadingPadding: CGFloat = 21
    private let bottomSubHeadingPadding: CGFloat = 14
    
    init(user: BaseUserDTO) {
        self.user = user
        self._viewModel = StateObject(wrappedValue: FeedViewModel(apiService: MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService(), userId: user.id))
    }
    
    var body: some View {
        ZStack {
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
                    seeAllActivityTypesButton
                }
                .padding(.horizontal, horizontalSubHeadingPadding)
                .padding(.bottom, bottomSubHeadingPadding)
                // Activities
                activityListView
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
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .allFriends)) { // TODO: change destination
            Text("See All")
                .font(.onestRegular(size: 13))
                .foregroundColor(universalSecondaryColor)
        }
    }
}

extension ActivityFeedView {
    var activityTypeListView: some View {
        HStack {
            ForEach(viewModel.activityTypes) { activityType in
                ActivityTypeCardView(activityType: activityType)
            }
        }
        .padding(.horizontal, 20)
    }
}

extension ActivityFeedView {
    var activityListView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 14) {
                if viewModel.activities.isEmpty {
                    Image("ActivityNotFound")
                        .resizable()
                        .frame(width: 125, height: 125)
                    Text("No Events Found")
                        .font(.onestSemiBold(size:32))
                        .foregroundColor(universalAccentColor)
                    Text("We couldn't find any events nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                } else {
                    ForEach(viewModel.activities) { activity in
                        ActivityCardView(userId: user.id, activity: activity, color: figmaBlue) { activity, color in
                                activityInPopup = activity
                                colorInPopup = color
                                showingActivityPopup = true
                            }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal)
        .refreshable {
            Task {
                await AppCache.shared.refreshActivities()
                await viewModel.fetchAllData()
            }
        }
    }
}

//struct SeeAllButtonView: View {
//    var destination: () -> View
//    var body: some View {
//        NavigationLink(destinati) { // TODO: change destination
//            Text("See All")
//                .font(.onestRegular(size: 13))
//                .foregroundColor(universalSecondaryColor)
//        }
//    }
//}

#Preview {
    let mockUserId: UUID = BaseUserDTO.danielAgapov.id
    ActivityFeedView(user: .danielAgapov)
}
