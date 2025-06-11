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
    @State private var eventInPopup: FullFeedEventDTO?
    @State private var colorInPopup: Color?
    
    var body: some View {
        HeaderView(user: user)
        
        VStack {
            // Spawn In! row
            HStack {
                Text("Spawn In!")
                    .font(.onestSemiBold(size: 14))
                    .foregroundColor(figmaBlack400)
                Spacer()
                seeAllButton
            }
            .padding(.horizontal)
            // Activity Types row
            activityTypeListView
            // Activities in Your Area row
            HStack {
                Text("See What's Happening!")
                    .font(.onestSemiBold(size: 14))
                    .foregroundColor(figmaBlack400)
                Spacer()
                seeAllButton
            }
            .padding(.horizontal)
            // Activities
            activityListView
        }
    }
    
    var seeAllButton: some View {
        NavigationLink(destination: FriendSearchView(userId: user.id, displayMode: .allFriends)) { // TODO: change destination
            Text("See All")
                .font(.onestRegular(size: 14))
                .foregroundColor(universalSecondaryColor)
        }
    }
}

extension ActivityFeedView {
    var activityTypeListView: some View {
        HStack {
            
        }
    }
}

extension ActivityFeedView {
    var activityListView: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 18) {
                if viewModel.events.isEmpty {
                    Image("EventNotFound")
                        .resizable()
                        .frame(width: 125, height: 125)
                    Text("No Events Found").font(.onestSemiBold(size: 32)).foregroundColor(universalAccentColor)
                    Text("We couldn't find any events nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                } else {
                    ForEach(viewModel.events) { activity in
                        EventCardView(userId: user.id, event: activity, color: figmaBlue) { event, color in
                                eventInPopup = event
                                colorInPopup = color
                                showingEventDescriptionPopup = true
                            }
                        
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
        .padding()
    }
}

#Preview {
    let mockUserId: UUID = UUID()
    ActivityFeedView(
        user: .danielAgapov,
        viewModel: FeedViewModel(
            apiService: MockAPIService(userId: mockUserId),
            userId: mockUserId
        )
    )
}
