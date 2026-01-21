import PhotosUI
import SwiftUI
import UIKit
import UserNotifications

struct UserInfoInputView: View {
	@ObservedObject var userAuth = UserAuthViewModel.shared

	@State private var username: String = ""

	// Validation flags
	@State private var isNameValid: Bool = true
	@State private var isUsernameValid: Bool = true
	@State private var isFormValid: Bool = false
	@State private var isEmailValid: Bool = true
	@State private var isSubmitting: Bool = false

	// If not through Google:
	@State private var email: String = ""

	// uploading custom image:
	@State private var selectedImage: UIImage?
	@State private var showImagePicker: Bool = false
	@State private var showErrorAlert: Bool = false
	@State private var errorMessage: String = ""

	// Error states for input fields
	@State private var nameErrorState = InputFieldState()
	@State private var emailErrorState = InputFieldState()
	@State private var usernameErrorState = InputFieldState()

	fileprivate func ProfilePic() -> some View {
		Group {
			if let selectedImage = selectedImage {
				Image(uiImage: selectedImage)
					.resizable()
					.scaledToFill()
					.frame(width: 150, height: 150)
					.clipShape(Circle())
			} else if userAuth.isLoggedIn, let pfpUrl = userAuth.profilePicUrl, let userId = userAuth.spawnUser?.id {
				CachedProfileImage(
					userId: userId,
					url: URL(string: pfpUrl),
					imageType: .profilePage
				)
			} else if let defaultPfpUrl = userAuth.defaultPfpUrlString, let userId = userAuth.spawnUser?.id {
				CachedProfileImage(
					userId: userId,
					url: URL(string: defaultPfpUrl),
					imageType: .profilePage
				)
			} else {
				Circle()
					.fill(.gray)
					.frame(width: 150, height: 150)
					.overlay(
						Image(systemName: "person.fill")
							.resizable()
							.scaledToFit()
							.frame(width: 60, height: 60)
							.foregroundColor(.white.opacity(0.7))
					)
			}
		}
	}

	// MARK: - Subviews for better compilation

	private var backButtonView: some View {
		HStack {
			UnifiedBackButton {
				// Clear any error states when going back
				userAuth.clearAllErrors()
				userAuth.resetState()
			}
			Spacer()
		}
		.padding(.horizontal, 25)
		.padding(.vertical, 12)
	}

	private var titleView: some View {
		Text("Help your friends recognize you")
			.font(.system(size: 30, weight: .semibold))
			.foregroundColor(.white)
			.multilineTextAlignment(.center)
			.padding(.top, 20)
	}

	private var profilePictureSection: some View {
		ZStack {
			ProfilePic()

			Circle()
				.fill(Color.black)
				.frame(width: 38, height: 38)
				.overlay(
					Image(systemName: "plus")
						.foregroundColor(.white)
						.font(.system(size: 16, weight: .bold))
				)
				.offset(x: 55, y: 55)
				.shadow(radius: 3)
		}
		.onTapGesture {
			showImagePicker = true
		}
		.sheet(isPresented: $showImagePicker) {
			SwiftUIImagePicker(selectedImage: $selectedImage)
		}
	}

	private var inputFieldsSection: some View {
		VStack(spacing: 16) {
			ErrorInputField(
				placeholder: "Name",
				text: Binding(
					get: { userAuth.name ?? "" },
					set: { userAuth.name = $0 }
				),
				hasError: nameErrorState.hasError,
				errorMessage: nameErrorState.errorMessage
			)

			// Always show email field for Apple sign-ins
			if userAuth.authProvider == .apple {
				ErrorInputField(
					placeholder: "your@email.com",
					text: $email,
					hasError: emailErrorState.hasError,
					errorMessage: emailErrorState.errorMessage
				)
			}

			ErrorInputField(
				placeholder: "@username",
				text: $username,
				hasError: usernameErrorState.hasError,
				errorMessage: usernameErrorState.errorMessage
			)
			.onChange(of: username) { _, newValue in
				handleUsernameChange(newValue)
			}
		}
		.padding(.horizontal, 32)
	}

	private var submitButtonView: some View {
		Button(action: {
			handleSubmitAction()
		}) {
			ZStack {
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color.white)
					.frame(height: 55)

				if isSubmitting {
					ProgressView()
						.progressViewStyle(CircularProgressViewStyle(tint: authPageBackgroundColor))
				} else {
					HStack {
						Text("Enter Spawn")
							.font(.system(size: 20, weight: .semibold))

						Image(systemName: "arrow.right")
							.resizable()
							.frame(width: 20, height: 20)
					}
					.foregroundColor(authPageBackgroundColor)
				}
			}
		}
		.disabled(isSubmitting || !isUsernameValid || username.isEmpty)
		.padding(.horizontal, 32)
		.padding(.top, 16)
	}

	var body: some View {
		NavigationStack {
			ZStack {
				authPageBackgroundColor
					.ignoresSafeArea()

				VStack {
					backButtonView

					ScrollView {
						VStack(spacing: 16) {
							Spacer()
							titleView
							Spacer()
							profilePictureSection
							Spacer()
							inputFieldsSection
							submitButtonView
							Spacer()
							Spacer()
						}
						.padding()
						.frame(minHeight: UIScreen.main.bounds.height - 100)
					}
				}
			}
			.onAppear {
				// Clear any previous error state when this view appears
				userAuth.clearAllErrors()
				userAuth.objectWillChange.send()
			}
			.task {
				await userAuth.spawnFetchUserIfAlreadyExists()
			}
			.alert(item: $userAuth.authAlert) { alertType in
				Alert(
					title: Text(alertType.title),
					message: Text(alertType.message),
					dismissButton: .default(Text("OK")) {
						if case .providerMismatch = alertType {
							userAuth.resetState()
						}
					}
				)
			}
			.onReceive(userAuth.$authAlert) { alert in
				handleAuthAlert(alert)
			}
			.alert("Error", isPresented: $showErrorAlert) {
				Button("OK", role: .cancel) {}
			} message: {
				Text(errorMessage)
			}
		}
	}

	// MARK: - Helper Methods

	private func handleUsernameChange(_ newValue: String) {
		// Remove @ prefix if user types it
		if newValue.hasPrefix("@") {
			username = String(newValue.dropFirst())
		}

		// Validate username format
		if !newValue.isEmpty {
			isUsernameValid = newValue.allSatisfy {
				$0.isLetter || $0.isNumber || $0 == "_" || $0 == "."
			}

			if !isUsernameValid {
				usernameErrorState.setError("Username can only contain letters, numbers, underscores, and periods")
			} else {
				usernameErrorState.clearError()
			}
		} else {
			usernameErrorState.clearError()
		}

		// Reset the username alert if username changes
		if userAuth.authAlert == .usernameAlreadyInUse {
			userAuth.authAlert = nil
		}
	}

	private func handleSubmitAction() {
		validateFields()
		if isFormValid {
			isSubmitting = true
			Task {
				print("Profile picture URL from provider: \(userAuth.profilePicUrl ?? "none")")

				await userAuth.spawnMakeUser(
					username: username,
					profilePicture: selectedImage,
					name: userAuth.name ?? "",
					email: userAuth.authProvider == .apple ? email : userAuth.email ?? ""
				)

				if userAuth.spawnUser != nil {
					requestNotificationPermission()
					userAuth.isFormValid = true
					userAuth.navigateTo(.userTermsOfService)
				} else {
					errorMessage = "Failed to create user. Please try again."
					showErrorAlert = true
				}

				isSubmitting = false
			}
		}
	}

	private var needsEmail: Bool {
		return userAuth.authProvider == .apple
	}

	private func validateFields() {
		// Check name
		isNameValid = !(userAuth.name ?? "").trimmingCharacters(
			in: .whitespacesAndNewlines
		).isEmpty

		if !isNameValid {
			nameErrorState.setError("Name is required")
		} else {
			nameErrorState.clearError()
		}

		// Check username
		let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
		isUsernameValid =
			!trimmedUsername.isEmpty
			&& trimmedUsername.allSatisfy {
				$0.isLetter || $0.isNumber || $0 == "_" || $0 == "."
			}

		if trimmedUsername.isEmpty {
			usernameErrorState.setError("Username is required")
		} else if !isUsernameValid {
			usernameErrorState.setError("Username can only contain letters, numbers, underscores, and periods")
		} else {
			usernameErrorState.clearError()
		}

		// Check email for Apple sign-ins
		if needsEmail {
			let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
			isEmailValid = email.range(of: emailRegex, options: .regularExpression) != nil

			if email.isEmpty {
				emailErrorState.setError("Email is required")
			} else if !isEmailValid {
				emailErrorState.setError("Please enter a valid email address")
			} else {
				emailErrorState.clearError()
			}
		}

		// Only set form as valid if all required fields are valid
		isFormValid = isNameValid && isUsernameValid && (!needsEmail || isEmailValid)
	}

	private func handleAuthAlert(_ alert: AuthAlertType?) {
		// Clear previous field errors when an auth alert occurs
		nameErrorState.clearError()
		emailErrorState.clearError()
		usernameErrorState.clearError()

		guard let alert = alert else { return }

		// Set field-specific errors based on the alert type
		switch alert {
		case .emailAlreadyInUse:
			if needsEmail {
				emailErrorState.setError("This email is already in use")
			}
		case .usernameAlreadyInUse:
			usernameErrorState.setError("This username is already taken")
		case .phoneNumberAlreadyInUse:
			// This would be handled in phone number view
			break
		default:
			// For other errors, we'll let the alert handle them
			break
		}
	}

	private func requestNotificationPermission() {
		Task {
			let granted = await NotificationService.shared.requestPermission()
			if granted {
				print("Notification permission granted")

				// Send a welcome notification using the NotificationDataBuilder
				NotificationService.shared.scheduleLocalNotification(
					title: "Welcome to Spawn!",
					body: "Thanks for joining. We'll keep you updated on activities and friends.",
					userInfo: NotificationDataBuilder.welcome()
				)
			} else {
				print("Notification permission denied")
			}
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	UserInfoInputView().environmentObject(appCache)
}
