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
    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: FullFeedActivityDTO?
    @State private var colorInPopup: Color?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HeaderView(user: user)
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            // Spawn In! row
            HStack {
                Text("Spawn In!")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(figmaBlack400)
                Spacer()
                seeAllButton
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            // Activity Types row
            activityTypeListView.padding(.bottom, 16)
            // Activities in Your Area row
            HStack {
                Text("See What's Happening!")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(figmaBlack400)
                Spacer()
                seeAllButton
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
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
    
    var seeAllButton: some View {
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
        .padding(.horizontal)
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
                        ActivityCardView(userId: user.id, activity: activity, color: figmaBlue) { event, color in
                                eventInPopup = event
                                colorInPopup = color
                                showingEventDescriptionPopup = true
                            }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding(.horizontal)
    }
}

#Preview {
    let mockUserId: UUID = BaseUserDTO.danielAgapov.id
    ActivityFeedView(
        user: .danielAgapov,
        viewModel: FeedViewModel(
            apiService: MockAPIService(userId: mockUserId),
            userId: mockUserId
        )
    )
}
