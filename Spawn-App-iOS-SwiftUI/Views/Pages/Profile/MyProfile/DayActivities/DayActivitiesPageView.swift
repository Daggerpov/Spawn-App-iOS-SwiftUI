import SwiftUI

struct DayActivitiesPageView: View {
	let date: Date
	let initialActivities: [CalendarActivityDTO]
	let onDismiss: () -> Void
	let onActivitySelected: (CalendarActivityDTO) -> Void

	@Environment(\.dismiss) private var dismiss
	// CRITICAL FIX: Use optional ViewModel to prevent repeated init() calls
	// when SwiftUI recreates this view struct. Initialize lazily in .task.
	@State private var profileViewModel: ProfileViewModel?
	@ObservedObject private var userAuth = UserAuthViewModel.shared
	@ObservedObject private var locationManager = LocationManager.shared
	@State private var showActivityDetails: Bool = false
	@State private var fullActivities: [UUID: FullFeedActivityDTO] = [:]
	@State private var isLoadingActivities = false
	// Mutable copy of activities that can be updated when activities are deleted/updated
	@State private var activities: [CalendarActivityDTO] = []

	var body: some View {
		VStack(spacing: 0) {
			// Header
			headerView

			// Content
			contentView
		}
		.background(universalBackgroundColor)
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.overlay(
			// Use the same ActivityPopupDrawer as the feed view for consistency
			Group {
				if showActivityDetails, profileViewModel?.selectedActivity != nil {
					EmptyView()  // Replaced with global popup system
				}
			}
			.onChange(of: showActivityDetails) { _, isShowing in
				if isShowing, let activity = profileViewModel?.selectedActivity {
					let activityColor = getActivityColor(for: activity.id)

					// Post notification to show global popup
					NotificationCenter.default.post(
						name: .showGlobalActivityPopup,
						object: nil,
						userInfo: ["activity": activity, "color": activityColor]
					)
					// Reset local state since global popup will handle it
					showActivityDetails = false
					profileViewModel?.selectedActivity = nil
				}
			}
		)
		.task {
			// Initialize activities from initialActivities on first load
			if activities.isEmpty {
				activities = initialActivities
			}
			// CRITICAL: Initialize ViewModel lazily to prevent repeated init() calls
			if profileViewModel == nil {
				profileViewModel = ProfileViewModel()
			}
			fetchAllActivityDetails()
		}
		// Listen for activity deletion notifications to update UI immediately
		.onReceive(NotificationCenter.default.publisher(for: .activityDeleted)) { notification in
			if let deletedActivityId = notification.object as? UUID {
				handleActivityDeleted(deletedActivityId)
			}
		}
		// Listen for activity update notifications to refresh activity details
		.onReceive(NotificationCenter.default.publisher(for: .activityUpdated)) { notification in
			if let updatedActivity = notification.object as? FullFeedActivityDTO {
				handleActivityUpdated(updatedActivity)
			}
		}
	}

	// MARK: - Header View

	private var headerView: some View {
		HStack {
			UnifiedBackButton(action: onDismiss)

			Spacer()

			VStack(spacing: 2) {
				Text(dayOfWeek)
					.font(.onestSemiBold(size: 16))
					.foregroundColor(figmaBlack400)

				Text(formattedDate)
					.font(.onestMedium(size: 14))
					.foregroundColor(figmaBlack300)
			}

			Spacer()

			// Invisible button for spacing balance
			Color.clear.frame(width: 24, height: 24)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
	}

	// MARK: - Content View

	private var contentView: some View {
		Group {
			if activities.isEmpty {
				emptyStateView
			} else if isLoadingActivities {
				loadingStateView
			} else {
				activitiesListView
			}
		}
	}

	private var emptyStateView: some View {
		EmptyStateView.noActivitiesForDay()
	}

	private var loadingStateView: some View {
		LoadingStateView(message: "Loading activities...")
	}

	private var activitiesListView: some View {
		ScrollView {
			LazyVStack(spacing: 14) {
				ForEach(activities, id: \.id) { activity in
					if let activityId = activity.activityId,
						let fullActivity = fullActivities[activityId]
					{
						// Always use the full ActivityCardView for consistent styling
						ActivityCardView(
							userId: userAuth.spawnUser?.id ?? UUID(),
							activity: fullActivity,
							color: getColorForActivity(activity),
							locationManager: locationManager,
							callback: { _, _ in
								onActivitySelected(activity)
							},
							horizontalPadding: 16
						)
					} else {
						// Show loading placeholder while activity details are being fetched
						ActivityLoadingCard(
							activity: activity,
							color: getColorForActivity(activity)
						)
					}
				}
			}
			.padding(.horizontal, 16)
			.padding(.top, 4)
		}
	}

	// MARK: - Helper Methods

	private func fetchAllActivityDetails() {
		guard !activities.isEmpty, let viewModel = profileViewModel else { return }

		isLoadingActivities = true

		Task {
			var fetchedActivities: [UUID: FullFeedActivityDTO] = [:]

			// Fetch all activity details concurrently
			await withTaskGroup(of: (UUID, FullFeedActivityDTO?).self) { group in
				for activity in activities {
					guard let activityId = activity.activityId else { continue }

					group.addTask {
						let fullActivity = await viewModel.fetchActivityDetails(activityId: activityId)
						return (activityId, fullActivity)
					}
				}

				for await (activityId, fullActivity) in group {
					if let fullActivity = fullActivity {
						fetchedActivities[activityId] = fullActivity
					}
				}
			}

			await MainActor.run {
				self.fullActivities = fetchedActivities
				self.isLoadingActivities = false
			}
		}
	}

	/// Handles activity deletion by removing it from the local activities list
	private func handleActivityDeleted(_ activityId: UUID) {
		// Remove from the calendar activities list
		let previousCount = activities.count
		activities.removeAll { $0.activityId == activityId }

		// Also remove from full activities dictionary
		fullActivities.removeValue(forKey: activityId)

		if activities.count < previousCount {
			print("✅ DayActivitiesPageView: Removed deleted activity \(activityId) from list")
		}
	}

	/// Handles activity updates by refreshing the activity details
	private func handleActivityUpdated(_ updatedActivity: FullFeedActivityDTO) {
		// Update the full activity details if we have it
		if fullActivities[updatedActivity.id] != nil {
			fullActivities[updatedActivity.id] = updatedActivity
			print("✅ DayActivitiesPageView: Updated activity \(updatedActivity.id) in list")
		}
	}

	private func handleActivitySelection(_ activity: CalendarActivityDTO) {
		guard let viewModel = profileViewModel else { return }
		Task {
			if let activityId = activity.activityId,
				await viewModel.fetchActivityDetails(activityId: activityId) != nil
			{
				await MainActor.run {
					showActivityDetails = true
				}
			}
		}
	}

	private func getColorForActivity(_ activity: CalendarActivityDTO) -> Color {
		// If we have a color hex code from the backend, use it
		if let colorHex = activity.colorHexCode, !colorHex.isEmpty {
			return Color(hex: colorHex)
		}

		// Use the exact same logic as feed view - ActivityColorService with activityId
		if let activityId = activity.activityId {
			return ActivityColorService.shared.getColorForActivity(activityId)
		}

		// For calendar-only activities without activityId, use the calendar activity's own id
		return ActivityColorService.shared.getColorForActivity(activity.id)
	}

	// MARK: - Computed Properties

	private var dayOfWeek: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "EEEE"
		return formatter.string(from: date)
	}

	private var formattedDate: String {
		let formatter = DateFormatter()
		formatter.dateFormat = "MMMM d, yyyy"
		return formatter.string(from: date)
	}
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
	DayActivitiesPageView(
		date: Date(),
		initialActivities: [],
		onDismiss: {},
		onActivitySelected: { _ in }
	)
}
