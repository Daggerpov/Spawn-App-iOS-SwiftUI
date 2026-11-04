import SwiftUI

struct NotificationSettingsView: View {
	@ObservedObject private var notificationService = NotificationService.shared
	@State private var isShowingPermissionAlert = false
	@Environment(\.presentationMode) var presentationMode

	var body: some View {
		VStack(spacing: 0) {
			// Header
			HStack {
				UnifiedBackButton {
					presentationMode.wrappedValue.dismiss()
				}

				Spacer()

				Text("Notifications")
					.font(.onestSemiBold(size: 20))
					.foregroundColor(universalAccentColor)

				Spacer()

				// Invisible chevron to balance the back button
				Image(systemName: "chevron.left")
					.font(.system(size: 20, weight: .semibold))
					.foregroundColor(.clear)
			}
			.padding(.horizontal, 25)
			.padding(.vertical, 12)

			// Settings sections
			ScrollView {
				VStack(spacing: 24) {
					SettingsSection(title: "Notification Status") {
						HStack {
							Image(
								systemName: notificationService.isNotificationsEnabled ? "bell.fill" : "bell.slash.fill"
							)
							.font(.system(size: 18))
							.foregroundColor(notificationService.isNotificationsEnabled ? .green : .red)
							.frame(width: 24, height: 24)

							VStack(alignment: .leading, spacing: 2) {
								Text(
									notificationService.isNotificationsEnabled
										? "Notifications Enabled" : "Notifications Disabled"
								)
								.font(.body)
								.foregroundColor(universalAccentColor)

								Text(
									notificationService.isNotificationsEnabled
										? "You will receive notifications from Spawn"
										: "Enable notifications in your device settings"
								)
								.font(.caption)
								.foregroundColor(.gray)
							}

							Spacer()
						}
						.padding(.horizontal)
						.padding(.vertical, 10)

						if !notificationService.isNotificationsEnabled {
							SettingsRow(icon: "bell.badge", title: "Enable Notifications") {
								requestPermission()
							}
						}
					}

					if notificationService.isNotificationsEnabled {
						SettingsSection(title: "Notification Types") {
							if notificationService.isLoadingPreferences {
								ProgressView()
									.frame(maxWidth: .infinity)
									.frame(height: 44)
							} else {
								SettingsToggleRow(
									icon: "person.badge.plus", title: "Friend Requests",
									isOn: $notificationService.friendRequestsEnabled
								)
								.onChange(of: notificationService.friendRequestsEnabled) {
									updatePreferences()
								}

								SettingsToggleRow(
									icon: "envelope", title: "Activity Invites",
									isOn: $notificationService.activityInvitesEnabled
								)
								.onChange(of: notificationService.activityInvitesEnabled) {
									updatePreferences()
								}

								SettingsToggleRow(
									icon: "calendar", title: "Activity Updates",
									isOn: $notificationService.activityUpdatesEnabled
								)
								.onChange(of: notificationService.activityUpdatesEnabled) {
									updatePreferences()
								}

								SettingsToggleRow(
									icon: "message", title: "Chat Messages",
									isOn: $notificationService.chatMessagesEnabled
								)
								.onChange(of: notificationService.chatMessagesEnabled) {
									updatePreferences()
								}
							}
						}

						#if DEBUG
							SettingsSection(title: "Test Notifications") {
								SettingsRow(icon: "app.badge", title: "Test In-App Notification") {
									testInAppNotification()
								}

								SettingsRow(icon: "bell.badge", title: "Test Push Notification (Local)") {
									testPushNotification()
								}
							}
						#endif
					}
				}
				.padding(.horizontal)
				.padding(.top, 12)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
			.task {
				notificationService.checkNotificationStatus()
				await notificationService.fetchNotificationPreferences()
			}
			.refreshable {
				Task {
					await notificationService.fetchNotificationPreferences()
				}
			}
		}
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
		.background(universalBackgroundColor)
		.navigationBarHidden(true)
		.alert(isPresented: $isShowingPermissionAlert) {
			Alert(
				title: Text("Notification Permissions"),
				message: Text(
					"Please enable notifications for Spawn in your device settings to receive updates about activities and friends."
				),
				primaryButton: .default(
					Text("Open Settings"),
					action: {
						openSettings()
					}),
				secondaryButton: .cancel()
			)
		}
	}

	private func requestPermission() {
		Task {
			let granted = await notificationService.requestPermission()
			if !granted {
				isShowingPermissionAlert = true
			}
		}
	}

	private func openSettings() {
		if let url = URL(string: UIApplication.openSettingsURLString) {
			UIApplication.shared.open(url)
		}
	}

	private func updatePreferences() {
		Task {
			await notificationService.updateNotificationPreferences()
		}
	}

	#if DEBUG
		private func testInAppNotification() {
			// Test the in-app notification directly
			InAppNotificationManager.shared.showNotification(
				title: "Test Notification",
				message: "This is a test in-app notification to verify the fix works!",
				type: .success,
				duration: 5.0
			)
		}

		private func testPushNotification() {
			// Test by simulating a push notification payload
			let testPayload: [AnyHashable: Any] = [
				"type": "friend-request",
				"senderName": "Test User",
				"senderId": UUID().uuidString,
				"requestId": UUID().uuidString,
			]

			// Simulate what happens when a push notification is received while app is in foreground
			InAppNotificationManager.shared.showNotificationFromPushData(testPayload)
		}
	#endif
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	NavigationView {
		NotificationSettingsView()
	}.environmentObject(appCache)
}
