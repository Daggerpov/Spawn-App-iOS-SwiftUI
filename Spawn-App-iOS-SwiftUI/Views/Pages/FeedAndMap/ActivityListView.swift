//
//  ActivityListView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Steve on 6/30/25.
//

import SwiftUI

struct ActivityListView: View {
    @ObservedObject var viewModel: FeedViewModel
    @ObservedObject private var locationManager = LocationManager.shared
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
                    EmptyStateView.noActivities()
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
            .padding(.bottom, 72) // Add bottom padding to ensure last activity shows fully above nav bar
        }
        .background(universalBackgroundColor)
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
