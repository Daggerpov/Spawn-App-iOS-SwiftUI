//
//  ActivityListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 6/30/25.
//

import SwiftUI

struct ActivityListView: View {
    @ObservedObject var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()
    var user: BaseUserDTO
    var bound: Int = .max
    let callback: (FullFeedActivityDTO, Color) -> Void
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    init(
        viewModel: FeedViewModel,
        user: BaseUserDTO,
        bound: Int = .max,
        callback: @escaping (FullFeedActivityDTO, Color) -> Void,
        selectedTab: Binding<TabType?> = .constant(nil)
    ) {
        self.viewModel = viewModel
        self.user = user
        self.bound = bound
        self.callback = callback
        self._selectedTab = selectedTab
    }
    
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
                    Text("We couldn't find any activities nearby.\nStart one yourself and be spontaneous!")
                        .font(.onestRegular(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(figmaBlack300)
                } else {
                    ForEach(0..<min(bound, viewModel.activities.count), id: \.self) { activityIndex in
                        ActivityCardView(
                            userId: user.id,
                            activity: viewModel.activities[activityIndex],
                            color: getActivityColor(for: viewModel.activities[activityIndex].id),
                            locationManager: locationManager,
                            callback: callback,
                            selectedTab: $selectedTab
                        )
                    }
                }
            }
        }
        .background(universalBackgroundColor)
        .padding(.horizontal)
        .refreshable {
            Task {
                await AppCache.shared.refreshActivities()
                await viewModel.fetchAllData()
            }
        }
    }
    
    private func getActivityColor(for activityId: UUID) -> Color {
        return ActivityColorService.shared.getColorForActivity(activityId)
    }
}
