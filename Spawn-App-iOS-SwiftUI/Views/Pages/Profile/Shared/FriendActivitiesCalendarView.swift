import SwiftUI

struct FriendActivitiesCalendarView: View {
	let user: Nameable
	var profileViewModel: ProfileViewModel
	@Binding var showActivityDetails: Bool

	@Environment(\.dismiss) private var dismiss
	@ObservedObject private var locationManager = LocationManager.shared

	@State private var showFullActivityList: Bool = false
	@State private var showCalendarPopup: Bool = false
	@State private var navigateToCalendar: Bool = false
	@State private var navigateToDayActivities: Bool = false
	@State private var selectedDayActivities: [CalendarActivityDTO] = []

	private var sortedActivities: [ProfileActivityDTO] {
		let upcomingActivities = profileViewModel.profileActivities
			.filter { !$0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 < start2
			}

		let pastActivities = profileViewModel.profileActivities
			.filter { $0.isPastActivity }
			.sorted { activity1, activity2 in
				guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
					return false
				}
				return start1 > start2
			}

		return upcomingActivities + pastActivities
	}

	var body: some View {
		ZStack {
			universalBackgroundColor
				.ignoresSafeArea()

			ScrollView {
				VStack(alignment: .leading, spacing: 24) {
					activitiesSection

					ProfileCalendarView(
						profileViewModel: profileViewModel,
						showCalendarPopup: $showCalendarPopup,
						navigateToCalendar: $navigateToCalendar,
						navigateToDayActivities: $navigateToDayActivities,
						selectedDayActivities: $selectedDayActivities,
						showMonthHeader: true,
						friendUserId: user.id
					)
				}
				.padding(.horizontal, 16)
				.padding(.top, 16)
				.padding(.bottom, 100)
			}
		}
		.navigationBarBackButtonHidden(true)
		.navigationBarTitleDisplayMode(.inline)
		.toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
				Button(action: {
					dismiss()
				}) {
					Image(systemName: "chevron.left")
						.font(.system(size: 20, weight: .semibold))
						.foregroundColor(universalAccentColor)
				}
			}
		}
		.onChange(of: showActivityDetails) { _, isShowing in
			if isShowing, let activity = profileViewModel.selectedActivity {
				let activityColor = getActivityColor(for: activity.id)

				NotificationCenter.default.post(
					name: .showGlobalActivityPopup,
					object: nil,
					userInfo: ["activity": activity, "color": activityColor]
				)
				showActivityDetails = false
				profileViewModel.selectedActivity = nil
			}
		}
		.navigationDestination(isPresented: $showFullActivityList) {
			FriendActivitiesShowAllView(
				user: user,
				profileViewModel: profileViewModel,
				showActivityDetails: $showActivityDetails
			)
		}
		.navigationDestination(isPresented: $navigateToCalendar) {
			ActivityCalendarView(
				profileViewModel: profileViewModel,
				userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
				calendarOwnerName: FormatterService.shared.formatFirstName(user: user),
				friendUserId: user.id,
				onActivitySelected: { activity in
					handleCalendarActivitySelection(activity)
				},
				onDayActivitiesSelected: { activities in
					selectedDayActivities = activities
					navigateToDayActivities = true
				}
			)
		}
		.navigationDestination(isPresented: $navigateToDayActivities) {
			calendarDayActivitiesPageView
		}
	}

	// MARK: - Activities Section
	private var activitiesSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			HStack {
				Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
					.font(.onestSemiBold(size: 16))
					.foregroundColor(universalAccentColor)
				Spacer()
				Button(action: {
					showFullActivityList = true
				}) {
					Text("Show All")
						.font(.onestMedium(size: 14))
						.foregroundColor(universalSecondaryColor)
				}
			}

			if profileViewModel.isLoadingUserActivities {
				HStack {
					Spacer()
					ProgressView()
					Spacer()
				}
			} else if profileViewModel.profileActivities.isEmpty {
				emptyActivitiesView
			} else {
				VStack(spacing: 12) {
					ForEach(Array(sortedActivities.prefix(2))) { activity in
						let fullFeedActivity = activity.toFullFeedActivityDTO()
						ActivityCardView(
							userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
							activity: fullFeedActivity,
							color: getActivityColor(for: activity.id),
							locationManager: locationManager,
							callback: { selectedActivity, color in
								profileViewModel.selectedActivity = selectedActivity
								showActivityDetails = true
							},
							horizontalPadding: 0
						)
					}
				}
			}
		}
	}

	private var emptyActivitiesView: some View {
		VStack(spacing: 16) {
			Image(systemName: "calendar.badge.exclamationmark")
				.font(.system(size: 32))
				.foregroundColor(Color.gray.opacity(0.6))

			Text("\(FormatterService.shared.formatFirstName(user: user)) hasn't spawned any activities yet!")
				.font(.onestMedium(size: 16))
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
		}
		.padding(32)
		.frame(maxWidth: .infinity)
		.background(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
		)
	}

	// MARK: - Calendar Navigation Helpers

	private var calendarDayActivitiesPageView: some View {
		let date = selectedDayActivities.first?.dateAsDate ?? Date()

		return DayActivitiesPageView(
			date: date,
			initialActivities: selectedDayActivities,
			onDismiss: {
				navigateToDayActivities = false
			},
			onActivitySelected: { activity in
				navigateToDayActivities = false
				handleCalendarActivitySelection(activity)
			}
		)
	}

	private func handleCalendarActivitySelection(_ activity: CalendarActivityDTO) {
		Task {
			if let activityId = activity.activityId,
				await profileViewModel.fetchActivityDetails(activityId: activityId) != nil
			{
				await MainActor.run {
					showActivityDetails = true
				}
			}
		}
	}
}

// MARK: - Preview
@available(iOS 17, *)
#Preview {
	let viewModel: ProfileViewModel = {
		let vm = ProfileViewModel()
		vm.friendshipStatus = .friends
		vm.profileActivities = ProfileActivityDTO.mockActivities
		return vm
	}()

	NavigationStack {
		FriendActivitiesCalendarView(
			user: BaseUserDTO.danielAgapov,
			profileViewModel: viewModel,
			showActivityDetails: .constant(false)
		)
	}
}
