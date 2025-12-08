//
//  ActivityDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct ActivityDescriptionView: View {
	@State private var messageText: String = ""
	var viewModel: ActivityDescriptionViewModel
	var color: Color
	@State private var showActivityEditView = false
	@State private var showAttendees = false
	@ObservedObject private var locationManager = LocationManager.shared

	// State for activity reporting
	@State private var showActivityMenu: Bool = false
	@State private var showReportDialog: Bool = false
	@ObservedObject private var userAuth = UserAuthViewModel.shared

	init(
		activity: FullFeedActivityDTO, users: [BaseUserDTO]?, color: Color,
		userId: UUID
	) {
		// Get the most up-to-date activity from cache to ensure correct participation status
		let cachedActivity = AppCache.shared.getActivityById(activity.id) ?? activity

		self.viewModel = ActivityDescriptionViewModel(
			activity: cachedActivity,
			users: users,
			senderUserId: userId,
			dataService: DataService.shared
		)
		self.color = color
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 20) {
				// Title and Information with menu button
				HStack {
					VStack(alignment: .leading) {
						ActivityCardTopRowView(activity: viewModel.activity, locationManager: locationManager)
					}

					Spacer()

					// Only show menu for activities not owned by current user
					if let currentUserId = userAuth.spawnUser?.id,
						currentUserId != viewModel.activity.creatorUser.id
					{
						Button(action: {
							showActivityMenu = true
						}) {
							Image(systemName: "ellipsis")
								.foregroundColor(.white)
								.font(.title3)
								.padding(8)
						}
					}
				}

				// Username display
				HStack {
					Text(
						ActivityInfoViewModel(activity: viewModel.activity, locationManager: locationManager)
							.getDisplayString(activityInfoType: .time)
					)
					.font(.onestSemiBold(size: 14))
					.foregroundColor(.white)
					.opacity(0.5)

					Spacer()
				}

				VStack {
					HStack {
						// Note
						if let note = viewModel.activity.note {
							Text("\(note)")
								.font(.body)
								.padding(.bottom, 15)
								.foregroundColor(.white)
								.font(.body)
								.italic()
						}
					}
					.frame(maxWidth: .infinity, alignment: .leading)

					HStack(spacing: 10) {
						ActivityInfoView(
							activity: viewModel.activity, activityInfoType: .time, locationManager: locationManager)

						// Only show location if it exists
						if viewModel.activity.location?.name != nil
							&& !(viewModel.activity.location?.name.isEmpty ?? true)
						{
							ActivityInfoView(
								activity: viewModel.activity, activityInfoType: .location,
								locationManager: locationManager)
						}

						Spacer()

						// Add participation toggle or edit button
						Circle()
							.CircularButton(
								systemName: viewModel.activity.isSelfOwned == true
									? "pencil"  // Edit icon for self-owned activities
									: (viewModel.isParticipating ? "checkmark" : "star.fill"),
								buttonActionCallback: {
									Task {
										if viewModel.activity.isSelfOwned == true {
											// Handle edit action
											showActivityEditView = true
										} else {
											// Toggle participation for non-owned activities
											await viewModel.toggleParticipation()
										}
									}
								})
					}
					.foregroundColor(.white)
				}
				.frame(maxWidth: .infinity)  // Ensures the HStack uses the full width of its parent

				// Participants section
				if let participants = viewModel.activity.participantUsers, !participants.isEmpty {
					participantsSection(participants: participants)
				}

				if let chatMessages = viewModel.activity.chatMessages {
					Divider()
						.frame(height: 0.5)
						.background(Color.black)
						.opacity(1)
					HStack {
						Spacer()
						Text(
							"\(chatMessages.count) \(chatMessages.count == 1 ? "reply" : "replies")"
						)
						.foregroundColor(universalAccentColor)
						.opacity(0.7)
						.font(.caption)
					}
					.frame(maxWidth: .infinity)
				}

				chatMessagesView
			}
			.padding(20)
			.background(color)
			.cornerRadius(universalRectangleCornerRadius)
		}
		.fullScreenCover(isPresented: $showActivityEditView) {
			ActivityEditView(viewModel: viewModel)
		}
		.fullScreenCover(isPresented: $showAttendees) {
			ActivityParticipantsView(
				activity: viewModel.activity,
				onDismiss: {
					showAttendees = false
				}
			)
		}
		.sheet(isPresented: $showActivityMenu) {
			ActivityMenuView(
				activity: viewModel.activity,
				showReportDialog: $showReportDialog
			)
			.presentationDetents([.height(200)])
			.presentationDragIndicator(.visible)
		}
		.sheet(isPresented: $showReportDialog) {
			ReportActivityDrawer(
				activity: viewModel.activity,
				onReport: { reportType, description in
					Task {
						await reportActivity(reportType: reportType, description: description)
					}
				}
			)
			.presentationDetents([.medium, .large])
			.presentationDragIndicator(.visible)
		}
		.onReceive(NotificationCenter.default.publisher(for: .activityUpdated)) { notification in
			if let updatedActivity = notification.object as? FullFeedActivityDTO,
				updatedActivity.id == viewModel.activity.id
			{
				print("🔄 ActivityDescriptionView: Received activity update for \(updatedActivity.title ?? "Unknown")")

				// Update the view model with the new activity data and refresh participation status
				viewModel.updateActivity(updatedActivity)
			}
		}
	}

	var usernamesView: some View {
		let participantCount = (viewModel.activity.participantUsers?.count ?? 0) - 1  // Subtract 1 to exclude creator
		let invitedCount = viewModel.activity.invitedUsers?.count ?? 0
		let totalCount = participantCount + invitedCount

		let creatorUsername = viewModel.activity.creatorUser.username ?? "user"
		let displayText =
			(viewModel.activity.isSelfOwned == true)
			? "You\(totalCount > 0 ? " + \(totalCount) more" : "")"
			: "@\(creatorUsername)\(totalCount > 0 ? " + \(totalCount) more" : "")"

		return Text(displayText)
			.foregroundColor(.white)
			.font(.caption)
	}

	// MARK: - Participants Section

	private func participantsSection(participants: [BaseUserDTO]) -> some View {
		Button(action: {
			showAttendees = true
		}) {
			HStack(spacing: -10) {
				// Show first few participant avatars
				ForEach(Array(participants.prefix(3).enumerated()), id: \.offset) { index, participant in
					Circle()
						.fill(Color.gray.opacity(0.5))
						.frame(width: 42, height: 42)
						.overlay(
							Group {
								if let profilePictureUrl = participant.profilePicture,
									let url = URL(string: profilePictureUrl)
								{
									CachedProfileImage(
										userId: participant.id,
										url: url,
										imageType: .chatMessage
									)
									.clipShape(Circle())
								} else {
									Text(String(participant.name?.prefix(1) ?? participant.username?.prefix(1) ?? "U"))
										.foregroundColor(.white)
										.font(.system(size: 16, weight: .semibold))
								}
							}
						)
						.shadow(color: .black.opacity(0.25), radius: 4, y: 2)
				}

				// Show +count if more participants
				if participants.count > 3 {
					Circle()
						.fill(.white)
						.frame(width: 42, height: 42)
						.overlay(
							Text("+\(participants.count - 3)")
								.foregroundColor(universalAccentColor)
								.font(.system(size: 15, weight: .bold))
						)
						.shadow(color: .black.opacity(0.25), radius: 4, y: 2)
				}

				Spacer()

				Text("View Attendees")
					.font(.custom("Onest", size: 14).weight(.medium))
					.foregroundColor(.white.opacity(0.8))
			}
		}
		.buttonStyle(PlainButtonStyle())
		.padding(.vertical, 12)
	}
}

extension ActivityDescriptionView {
	var chatMessagesView: some View {
		VStack(spacing: 10) {
			ScrollView(.vertical) {
				LazyVStack(spacing: 15) {
					if let chatMessages = viewModel.activity.chatMessages {
						ForEach(chatMessages) { chatMessage in
							ChatMessageRow(chatMessage: chatMessage)
						}
					}
				}
				.padding(.horizontal, 5)
			}
			.frame(maxHeight: 150)

			chatBar
		}
		.padding(.top, 10)
		.padding(.bottom, 10)
		.background(Color.black.opacity(0.05))
		.cornerRadius(20)
	}

	struct ChatMessageRow: View {
		let chatMessage: FullActivityChatMessageDTO
		@State private var showMessageMenu: Bool = false
		@State private var showReportDialog: Bool = false
		@ObservedObject private var userAuth = UserAuthViewModel.shared

		private func abbreviatedTime(from timestamp: String) -> String {
			let abbreviations: [String: String] = [
				"seconds": "sec",
				"minutes": "mins",
				"week": "wk",
				"weeks": "wk",
			]
			var result = timestamp
			for (full, abbreviation) in abbreviations {
				result = result.replacingOccurrences(
					of: full, with: abbreviation)
			}
			return result
		}

		private var isFromCurrentUser: Bool {
			guard let currentUser = userAuth.spawnUser else { return false }
			return chatMessage.senderUser.id == currentUser.id
		}

		var body: some View {
			HStack {
				if let pfpUrl = chatMessage.senderUser.profilePicture {
					CachedProfileImage(
						userId: chatMessage.senderUser.id,
						url: URL(string: pfpUrl),
						imageType: .chatMessage
					)
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 25, height: 25)
				}

				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Image(systemName: "star.fill")
							.resizable()
							.scaledToFit()
							.frame(width: 15, height: 15)
							.foregroundColor(universalAccentColor)
						Text(chatMessage.senderUser.username ?? "User")
							.foregroundColor(universalAccentColor)
							.bold()
							.font(.caption)
					}
					Text(chatMessage.content)
						.foregroundColor(universalAccentColor)
						.font(.caption)
				}
				Spacer()
				HStack {
					Text(abbreviatedTime(from: chatMessage.formattedTimestamp))
						.foregroundColor(.white)
						.font(.caption)
					Image(systemName: "heart")  // Logic for liked/unliked can go here later
				}
			}
			.padding(.vertical, 5)
			.padding(.horizontal, 30)
			.onLongPressGesture(minimumDuration: 0.5) {
				// Only allow reporting other users' messages
				if !isFromCurrentUser {
					let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
					impactFeedback.impactOccurred()
					showMessageMenu = true
				}
			}
			.sheet(isPresented: $showMessageMenu) {
				ChatMessageMenuView(
					chatMessage: chatMessage,
					showReportDialog: $showReportDialog
				)
				.presentationDetents([.height(200)])
				.presentationDragIndicator(.visible)
			}
			.sheet(isPresented: $showReportDialog) {
				ReportChatMessageDrawer(
					chatMessage: chatMessage,
					onReport: { reportType, description in
						Task {
							await reportChatMessage(reportType: reportType, description: description)
						}
					}
				)
				.presentationDetents([.medium, .large])
				.presentationDragIndicator(.visible)
			}
		}

		private func reportChatMessage(reportType: ReportType, description: String) async {
			guard let currentUserId = userAuth.spawnUser?.id else { return }

			do {
				let reportingService = ReportingService()
				try await reportingService.reportChatMessage(
					reporterUserId: currentUserId,
					chatMessageId: chatMessage.id,
					reportType: reportType,
					description: description
				)
				print("Chat message reported successfully")
			} catch {
				print("Error reporting chat message: \(error)")
			}
		}
	}

	var chatBar: some View {
		HStack {
			TextField("Add a comment", text: $messageText)
				.padding(10)
				.background(universalBackgroundColor)
				.cornerRadius(10)
				.font(.caption)
				.foregroundColor(universalAccentColor)

			Button(action: {
				// Store the current message text in a local constant
				let currentMessage = messageText

				// Only try to send if message is not empty
				if !currentMessage.isEmpty {
					Task {
						// Use the stored message text
						await viewModel.sendMessage(message: currentMessage)

						// Clear the text field on the main thread after sending
						await MainActor.run {
							messageText = ""
						}
					}
				}
			}) {
				Image(systemName: "paperplane.fill")
					.foregroundColor(Color.black)
			}
			.padding(.horizontal, 10)
			.disabled(messageText.isEmpty)  // Disable button when text is empty
		}
		.padding(8)
		.background(universalBackgroundColor)
		.cornerRadius(universalRectangleCornerRadius)
		.padding(.horizontal, 15)
	}

	private func reportActivity(reportType: ReportType, description: String) async {
		guard let currentUserId = userAuth.spawnUser?.id else { return }

		await viewModel.reportActivity(
			reporterUserId: currentUserId,
			reportType: reportType,
			description: description
		)
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	ActivityDescriptionView(
		activity: FullFeedActivityDTO.mockDinnerActivity,
		users: BaseUserDTO.mockUsers,
		color: universalAccentColor,
		userId: UUID()
	).environmentObject(appCache)
}
