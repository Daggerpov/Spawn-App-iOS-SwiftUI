//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

struct FeedView: View {
	@State private var viewModel: FeedViewModel
	@ObservedObject private var locationManager = LocationManager.shared
	// Using AppCache as a singleton instead of environment object

	@Namespace private var animation: Namespace.ID

	@State private var showingActivityDescriptionPopup: Bool = false
	@State private var activityInPopup: FullFeedActivityDTO?
	@State private var colorInPopup: Color?

	@State private var showActivityCreationDrawer: Bool = false

	// Store background refresh task so we can cancel it on disappear
	@State private var backgroundRefreshTask: Task<Void, Never>?

	// for popups:
	@State private var creationOffset: CGFloat = 1000
	// --------

	var user: BaseUserDTO

	init(user: BaseUserDTO) {
		self.user = user
		_viewModel = State(
			initialValue: FeedViewModel(
				userId: user.id
			)
		)
	}

	var body: some View {
		ZStack {
			NavigationStack {
				VStack {
					HeaderView(user: user).padding(.top, 75)
					Spacer()
					activitiesListView
				}
				.background(universalBackgroundColor)
				.ignoresSafeArea(.container, edges: .top)
				.dimmedBackground(
					isActive: showActivityCreationDrawer
				)
			}
			.background(universalBackgroundColor)
			.task {
				// CRITICAL FIX: Load cached activities immediately to unblock UI
				// Cache validation is done on app startup, no need to repeat on every view load

				// Load cached activities through view model (fast, non-blocking)
				let activitiesCount: Int = await MainActor.run {
					viewModel.loadCachedActivities()
					return viewModel.activities.count
				}

				// Check if task was cancelled
				guard !Task.isCancelled else {
					return
				}

				// If cache is empty, block until we have data (critical for UX)
				if activitiesCount == 0 {
					await viewModel.fetchAllData()
				} else {
					// Cache exists - refresh in background (progressive enhancement)
					backgroundRefreshTask = Task { @MainActor in
						// Check cancellation before starting expensive work
						guard !Task.isCancelled else {
							return
						}

						await viewModel.fetchAllData()

						// Check cancellation after async work
						guard !Task.isCancelled else {
							return
						}
					}
				}
			}
			.onAppear {
				// Resume timers when view appears
				viewModel.resumeTimers()
			}
			.onDisappear {
				// Pause timers to save resources when view is not visible
				viewModel.pauseTimers()

				// Cancel any ongoing background refresh to prevent blocking
				backgroundRefreshTask?.cancel()
				backgroundRefreshTask = nil
			}
			.refreshable {
				// Pull to refresh - user-initiated refresh
				// Start the API fetch in background and return quickly to prevent long spinner
				// This matches the friends page behavior where the refresh animation is brief
				Task.detached {
					await viewModel.fetchAllData(forceRefresh: true)
				}
				// Brief delay to show visual feedback that refresh was triggered
				try? await Task.sleep(for: .seconds(0.5))
			}
			.onChange(of: showingActivityDescriptionPopup) { _, isShowing in
				if isShowing, let activity = activityInPopup, let color = colorInPopup {
					// Post notification to show global popup
					NotificationCenter.default.post(
						name: .showGlobalActivityPopup,
						object: nil,
						userInfo: ["activity": activity, "color": color]
					)
					// Reset local state since global popup will handle it
					showingActivityDescriptionPopup = false
					activityInPopup = nil
					colorInPopup = nil
				}
			}
			.sheet(isPresented: $showActivityCreationDrawer) {
				ActivityCreationView(
					creatingUser: user,
					closeCallback: {
						showActivityCreationDrawer = false
					},
					selectedTab: .constant(TabType.home)
				)
				.presentationDragIndicator(.visible)
			}
		}
	}

	func closeCreation() {
		ActivityCreationViewModel.reInitialize()
		creationOffset = 1000
		showActivityCreationDrawer = false
	}
}

@available(iOS 17.0, *)
#Preview {
	FeedView(user: .danielAgapov)
}

extension FeedView {
	var activitiesListView: some View {
		ScrollView(.vertical) {
			LazyVStack(spacing: 25) {
				if viewModel.activities.isEmpty {
					Image("ActivityNotFound")
						.resizable()
						.frame(width: 125, height: 125)
					Text("No Activities Found").font(.onestSemiBold(size: 32)).foregroundColor(universalAccentColor)
					Text("We couldn't find any activities nearby.\nStart one yourself and be spontaneous!")
						.font(.onestRegular(size: 16))
						.multilineTextAlignment(.center)
						.foregroundColor(figmaBlack300)
					CreateActivityButton(showActivityCreationDrawer: $showActivityCreationDrawer)
				} else {
					ForEach(viewModel.activities) { activity in
						ActivityCardView(
							userId: user.id,
							activity: activity,
							color: getActivityColor(for: activity.id),
							locationManager: locationManager
						) { activity, color in
							activityInPopup = activity
							colorInPopup = color
							showingActivityDescriptionPopup = true
						}
					}
				}
			}
		}
		.scrollIndicators(.hidden)
		.padding()
		.padding(.top, 16)
	}
}

extension View {
	func dimmedBackground(isActive: Bool) -> some View {
		self.overlay(
			Group {
				if isActive {
					Color.black.opacity(0.5)
						.ignoresSafeArea()
						.transition(.opacity)
						.animation(.easeInOut, value: isActive)
				}
			}
		)
	}
}
