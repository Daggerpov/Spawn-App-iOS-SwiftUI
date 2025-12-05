import SwiftUI

struct FriendActivitiesShowAllView: View {
	let user: Nameable
	@ObservedObject var profileViewModel: ProfileViewModel
	@Binding var showActivityDetails: Bool

	@Environment(\.presentationMode) var presentationMode
	@Environment(\.colorScheme) private var colorScheme

	// Add navigation state for full calendar view
	@State private var navigateToCalendar: Bool = false

	@ObservedObject private var locationManager = LocationManager.shared

	var body: some View {
		NavigationStack {
			ZStack {
				// Background
				universalBackgroundColor
					.ignoresSafeArea()

				VStack(spacing: 0) {
					// Header
					headerView
						.padding(.horizontal, 16)
						.padding(.top, 16)

					ScrollView {
						VStack(spacing: 32) {
							// Activity Cards Section
							activityCardsSection

							// Calendar Section
							calendarSection
						}
						.padding(.horizontal, 16)
						.padding(.bottom, 16)  // Standard bottom padding
					}
				}
			}
			.navigationBarHidden(true)
			.sheet(isPresented: $showActivityDetails) {
				activityDetailsView
			}
			.navigationDestination(isPresented: $navigateToCalendar) {
				friendCalendarFullScreenView
			}
		}
		.onAppear {
			Task {
				await fetchFriendData()
			}
		}
	}

	// MARK: - Calendar Full Screen View
	private var friendCalendarFullScreenView: some View {
		ActivityCalendarView(
			profileViewModel: profileViewModel,
			userCreationDate: profileViewModel.userProfileInfo?.dateCreated,
			calendarOwnerName: FormatterService.shared.formatFirstName(user: user),
			onDismiss: {
				// Reset navigation state when calendar view is dismissed
				navigateToCalendar = false
			},
			onDayActivitiesSelected: { activities in
				// Handle day activities selection for friend's calendar
				// For now, just log it - could be implemented later if needed
				print("Day activities selected: \(activities.count) activities")
			}
		)
	}

	// MARK: - Header View
	private var headerView: some View {
		HStack {
			// Back button
			Button(action: {
				presentationMode.wrappedValue.dismiss()
			}) {
				Image(systemName: "chevron.left")
					.font(.onestSemiBold(size: 18))
					.foregroundColor(universalAccentColor)
			}

			Spacer()

			// Title
			Text("Activities by \(FormatterService.shared.formatFirstName(user: user))")
				.font(.onestSemiBold(size: 18))
				.foregroundColor(universalAccentColor)

			Spacer()

			// Invisible spacer to balance the back button
			Color.clear
				.frame(width: 24, height: 24)
		}
	}

	// MARK: - Activity Cards Section
	private var activityCardsSection: some View {
		VStack(spacing: 12) {
			// Use real activity data from the friend's profile
			if profileViewModel.isLoadingUserActivities {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 100)
			} else if sortedActivities.isEmpty {
				VStack(spacing: 8) {
					Text("No activities found")
						.font(.onestMedium(size: 16))
						.foregroundColor(figmaBlack300)

					Text("This user hasn't created any activities yet.")
						.font(.onestRegular(size: 14))
						.foregroundColor(figmaBlack300)
						.multilineTextAlignment(.center)
				}
				.padding()
			} else {
				VStack(spacing: 12) {
					ForEach(Array(sortedActivities.prefix(2).enumerated()), id: \.1.id) { index, activity in
						let activityColor = getActivityColor(for: activity.id)

						ActivityCardView(
							userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
							activity: activity,  // ProfileActivityDTO IS a FullFeedActivityDTO
							color: activityColor,
							locationManager: locationManager,
							callback: { selectedActivity, color in
								profileViewModel.selectedActivity = selectedActivity
								showActivityDetails = true
							}
						)
					}
				}
			}
		}
	}

	// MARK: - Calendar Section
	private var calendarSection: some View {
		VStack(spacing: 16) {
			// Days of the week header
			HStack(spacing: 0) {
				ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
					Text(day)
						.font(.onestMedium(size: 13))
						.foregroundColor(figmaBlack300)
						.frame(maxWidth: .infinity)
				}
			}

			if profileViewModel.isLoadingCalendar {
				ProgressView()
					.frame(maxWidth: .infinity, minHeight: 150)
			} else {
				// Calendar grid - EXACTLY 5 rows using real friend data
				VStack(spacing: 8) {
					ForEach(0..<5, id: \.self) { row in
						HStack(spacing: 8) {
							ForEach(0..<7, id: \.self) { col in
								if let activity = profileViewModel.calendarActivities[row][col] {
									// Day cell with real activity data
									FriendCalendarDaySquare(activity: activity)
										.onTapGesture {
											// Navigate to full calendar view instead of just showing activity details
											navigateToFullCalendar()
										}
								} else {
									// Empty day cell
									RoundedRectangle(cornerRadius: 6.6)
										.fill(figmaCalendarDayIcon)
										.frame(width: 46, height: 46)
										.shadow(color: Color.black.opacity(0.1), radius: 6.6, x: 0, y: 1.6)
										.onTapGesture {
											// Navigate to full calendar view on empty day tap
											navigateToFullCalendar()
										}
								}
							}
						}
					}
				}
			}
		}
	}

	// MARK: - Helper Properties
	private var sortedActivities: [ProfileActivityDTO] {
		let upcomingActivities = profileViewModel.profileActivities
			.filter { !$0.isPastActivity }

		let sortedUpcoming = upcomingActivities.sorted { activity1, activity2 in
			guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
				return false
			}
			return start1 < start2
		}

		let pastActivities = profileViewModel.profileActivities
			.filter { $0.isPastActivity }

		let sortedPast = pastActivities.sorted { activity1, activity2 in
			guard let start1 = activity1.startTime, let start2 = activity2.startTime else {
				return false
			}
			return start1 > start2
		}

		return sortedUpcoming + sortedPast
	}

	private var activityDetailsView: some View {
		Group {
			if let activity = profileViewModel.selectedActivity {
				let activityColor = getActivityColor(for: activity.id)

				ActivityDescriptionView(
					activity: activity,
					users: activity.participantUsers,
					color: activityColor,
					userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
				)
				.presentationDetents([.medium, .large])
			}
		}
	}

	// MARK: - Helper Methods
	private func fetchFriendData() async {
		await MainActor.run {
			// isLoading = true // This line was removed as per the edit hint
		}

		await MainActor.run {
			// isLoading = false // This line was removed as per the edit hint
		}
	}

	private func navigateToFullCalendar() {
		Task {
			// Fetch all calendar activities for the friend before navigating
			await profileViewModel.fetchAllCalendarActivities(friendUserId: user.id)
			await MainActor.run {
				navigateToCalendar = true
			}
		}
	}

	// TODO: investigate why this isn't being used
	private func handleActivitySelection(_ activity: CalendarActivityDTO) {
		guard let activityId = activity.activityId else { return }

		print("🔄 Fetching activity details for activity: \(activityId)")

		Task {
			if (await profileViewModel.fetchActivityDetails(activityId: activityId)) != nil {
				await MainActor.run {
					showActivityDetails = true
				}
			} else {
				print("❌ Failed to fetch activity details for: \(activityId)")
			}
		}
	}
}

// MARK: - Friend Calendar Day Square Component
struct FriendCalendarDaySquare: View {
	let activity: CalendarActivityDTO

	private var dayNumber: String {
		String(Calendar.current.component(.day, from: activity.dateAsDate))
	}

	var body: some View {
		RoundedRectangle(cornerRadius: 6.62)
			.fill(activityColor)
			.frame(width: 46.33, height: 46.33)
			.shadow(
				color: Color.black.opacity(0.1),
				radius: 6.62,
				x: 0,
				y: 1.65
			)
			.overlay(
				Group {
					if let icon = activity.icon, !icon.isEmpty {
						Text(icon)
							.font(.onestMedium(size: 26.47))
							.foregroundColor(.black)
					} else {
						Text("⭐️")
							.font(.onestMedium(size: 26.47))
							.foregroundColor(.black)
					}
				}
			)
			.overlay(
				// Date number badge (positioned in top-right corner)
				VStack {
					HStack {
						Spacer()
						Text(dayNumber)
							.font(.onestMedium(size: 8))
							.foregroundColor(.black)
							.padding(2)
							.background(Color.white.opacity(0.9))
							.clipShape(Circle())
					}
					.padding(.top, 2)
					.padding(.trailing, 2)
					Spacer()
				}
			)
	}

	private var activityColor: Color {
		// First check if activity has a custom color hex code
		if let colorHexCode = activity.colorHexCode, !colorHexCode.isEmpty {
			return Color(hex: colorHexCode)
		}

		// Fallback to activity color based on ID
		guard let activityId = activity.activityId else {
			return figmaCalendarDayIcon  // Default gray color matching Figma
		}
		return getActivityColor(for: activityId)
	}
}

// MARK: - Preview
#Preview {
	FriendActivitiesShowAllView(
		user: BaseUserDTO.danielAgapov,
		profileViewModel: ProfileViewModel(),
		showActivityDetails: .constant(false)
	)
}
