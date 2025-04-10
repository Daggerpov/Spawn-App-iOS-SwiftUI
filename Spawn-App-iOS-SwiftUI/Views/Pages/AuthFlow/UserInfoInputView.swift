import SwiftUI
import PhotosUI
import UIKit
import UserNotifications

struct UserInfoInputView: View {
	@StateObject var userAuth = UserAuthViewModel.shared

	@State private var username: String = ""

	// Validation flags
	@State private var isFirstNameValid: Bool = true
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

	fileprivate func ProfilePic() -> some View {
		Group {
			if let selectedImage = selectedImage {
				Image(uiImage: selectedImage)
					.resizable()
					.scaledToFill()
					.frame(width: 150, height: 150)
					.clipShape(Circle())
			} else if userAuth.isLoggedIn, let pfpUrl = userAuth.profilePicUrl {
				AsyncImage(url: URL(string: pfpUrl)) { image in
					image
						.ProfileImageModifier(imageType: .profilePage)
				} placeholder: {
					Circle()
						.fill(Color.gray)
						.frame(width: 150, height: 150)
						.overlay(
							ProgressView()
								.progressViewStyle(CircularProgressViewStyle(tint: .white))
						)
				}
			} else if let defaultPfpUrl = userAuth.defaultPfpUrlString {
				AsyncImage(url: URL(string: defaultPfpUrl)) { image in
					image
						.ProfileImageModifier(imageType: .profilePage)
				} placeholder: {
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

	var body: some View {
		NavigationStack {
			ZStack {
				// Background color
				authPageBackgroundColor
					.ignoresSafeArea()

				VStack {
					// Back button at the top, but respecting safe area
					HStack {
						Button(action: {
							// Reset auth state and navigate back to LaunchView
							userAuth.resetState()
						}) {
							HStack {
								Image(systemName: "arrow.left")
									.font(.system(size: 20, weight: .bold))
								Text("Back")
									.font(.system(size: 16, weight: .semibold))
							}
							.foregroundColor(.white)
							.padding(.leading, 16)
						}
						Spacer()
					}
					.padding(.top, 8)

					// Main content
					ScrollView {
						VStack(spacing: 16) {
							Spacer()

							Text("Help your friends recognize you")
								.font(.system(size: 30, weight: .semibold))
								.foregroundColor(.white)
								.multilineTextAlignment(.center)
								.padding(.top, 20)

							Spacer()

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

							Spacer()

							VStack(spacing: 16) {
								HStack {
									InputFieldView(
										label: "First Name",
										text: Binding(
											get: { userAuth.givenName ?? "" },
											set: { userAuth.givenName = $0 }
										),
										isValid: $isFirstNameValid,
										placeholder: "First name"
									)
									InputFieldView(
										label: "Last Name",
										text: Binding(
											get: { userAuth.familyName ?? "" },
											set: { userAuth.familyName = $0 }
										),
										isValid: .constant(true),
										placeholder: "Last name"
									)
								}

								// Always show email field for Apple sign-ins
								if userAuth.authProvider == .apple {
									InputFieldView(
										label: "Email",
										text: $email,
										isValid: $isEmailValid,
										placeholder: "your@email.com"
									)
								}

								InputFieldView(
									label: "Username",
									text: $username,
									isValid: $isUsernameValid,
									placeholder: "@username"
								)
								.onChange(of: username) { newValue in
									// Remove @ prefix if user types it
									if newValue.hasPrefix("@") {
										username = String(newValue.dropFirst())
									}

									// Validate username format
									if !newValue.isEmpty {
										isUsernameValid = newValue.allSatisfy {
											$0.isLetter || $0.isNumber || $0 == "_" || $0 == "."
										}
									}
									
									// Reset the username alert if username changes
									if userAuth.authAlert == .usernameAlreadyInUse {
										userAuth.authAlert = nil
									}
								}

								if !isUsernameValid && !username.isEmpty {
									Text("Username can only contain letters, numbers, underscores, and periods")
										.font(.caption)
										.foregroundColor(.red)
										.padding(.horizontal)
										.transition(.opacity)
								}
							}
							.padding(.horizontal, 32)

							Button(action: {
								validateFields()
								if isFormValid {
									isSubmitting = true
									Task {
										// If no image is selected but we have a profile picture URL from Google/Apple,
										// we'll pass nil for profilePicture and let the backend use the URL
										print("Profile picture URL from provider: \(userAuth.profilePicUrl ?? "none")")

										await userAuth.spawnMakeUser(
											username: username,
											profilePicture: selectedImage, // Pass the selected image or nil
											firstName: userAuth.givenName ?? "",
											lastName: userAuth.familyName ?? "",
											email: userAuth.authProvider == .apple ? email : userAuth.email ?? ""
										)

										// Show notification permission request after account creation
										if userAuth.spawnUser != nil {
											requestNotificationPermission()
											// Only set navigation flag here after successful account creation
											userAuth.isFormValid = true
											userAuth.setShouldNavigateToFeedView()
										} else {
											errorMessage = "Failed to create user. Please try again."
											showErrorAlert = true
										}

										isSubmitting = false
									}
								}
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

							Spacer()
							Spacer()
						}
						.padding()
						.frame(minHeight: UIScreen.main.bounds.height - 100)
					}
				}
			}
			.navigationDestination(isPresented: $userAuth.shouldNavigateToFeedView) {
				if let unwrappedSpawnUser = userAuth.spawnUser {
					FeedView(user: unwrappedSpawnUser)
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}
			}
			.onAppear {
				userAuth.objectWillChange.send()  // Trigger initial UI update
				Task {
					await userAuth.spawnFetchUserIfAlreadyExists()
				}
			}
			.alert(item: $userAuth.authAlert) { alertType in
				Alert(
					title: Text(alertType.title),
					message: Text(alertType.message),
					dismissButton: .default(Text("OK")) {
						// If provider mismatch, go back to launch view
						if case .providerMismatch = alertType {
							userAuth.resetState()
						}
					}
				)
			}
			.alert("Error", isPresented: $showErrorAlert) {
				Button("OK", role: .cancel) { }
			} message: {
				Text(errorMessage)
			}
		}
	}

	private var needsEmail: Bool {
		return userAuth.authProvider == .apple
	}

	private func validateFields() {
		// Check first name
		isFirstNameValid = !(userAuth.givenName ?? "").trimmingCharacters(
			in: .whitespaces
		).isEmpty

		// Check username
		let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
		isUsernameValid = !trimmedUsername.isEmpty &&
		trimmedUsername.allSatisfy {
			$0.isLetter || $0.isNumber || $0 == "_" || $0 == "."
		}

		// Check email for Apple sign-ins
		if needsEmail {
			let emailRegex = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
			isEmailValid = email.range(of: emailRegex, options: .regularExpression) != nil
		}

		// Only set form as valid if all required fields are valid
		isFormValid = isFirstNameValid && isUsernameValid && (!needsEmail || isEmailValid)
	}

	private func requestNotificationPermission() {
		Task {
			let granted = await NotificationService.shared.requestPermission()
			if granted {
				print("Notification permission granted")
				
				// Send a welcome notification using the NotificationDataBuilder
				NotificationService.shared.scheduleLocalNotification(
					title: "Welcome to Spawn!",
					body: "Thanks for joining. We'll keep you updated on events and friends.",
					userInfo: NotificationDataBuilder.welcome()
				)
			} else {
				print("Notification permission denied")
			}
		}
	}
}

struct InputFieldView: View {
	var label: String
	@Binding var text: String
	@Binding var isValid: Bool
	var placeholder: String

	init(label: String, text: Binding<String>, isValid: Binding<Bool>, placeholder: String = "") {
		self.label = label
		self._text = text
		self._isValid = isValid
		self.placeholder = placeholder
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(label)
					.font(.system(size: 18))
					.foregroundColor(.white)

				if !isValid {
					Image(systemName: "exclamationmark.circle.fill")
						.foregroundColor(.red)
						.font(.system(size: 12))
				}
			}

			TextField(placeholder, text: $text)
				.padding()
				.background(.white)
				.cornerRadius(universalRectangleCornerRadius)
				.foregroundColor(.black)
				.autocapitalization(.none)
				.autocorrectionDisabled(true)
				.overlay(
					RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
						.stroke(isValid ? Color.clear : Color.red, lineWidth: 1)
				)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	UserInfoInputView()
}
