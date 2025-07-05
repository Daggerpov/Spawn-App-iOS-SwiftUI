//
//  ActivityListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 6/30/25.
//

import SwiftUI

struct ActivityListView: View {
    @ObservedObject var viewModel: FeedViewModel
    var user: BaseUserDTO
    var bound: Int = .max
    let callback: (FullFeedActivityDTO, Color) -> Void
    
    
    var body: some View {
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
                    ForEach(0..<min(bound, viewModel.activities.count), id: \.self) { activityIndex in
                        ActivityCardView(userId: user.id, activity: viewModel.activities[activityIndex], color: figmaBlue, callback: callback)
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
