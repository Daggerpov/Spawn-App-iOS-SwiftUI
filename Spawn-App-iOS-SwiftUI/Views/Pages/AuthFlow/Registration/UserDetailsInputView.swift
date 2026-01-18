//
//  UserDetailsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 2025-07-11.
//

import SwiftUI

struct UserDetailsInputView: View {
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var viewModel: UserAuthViewModel = .shared
	@State private var username: String = ""
	@State private var phoneNumber: String = ""
	@State private var password: String = ""
	@State private var confirmPassword: String = ""
	@State private var usernameError: String? = nil
	@State private var passwordError: String? = nil
	@State private var phoneError: String? = nil
	@State private var isUsernameTaken: Bool = false
	@State private var isPasswordMismatch: Bool = false
	@State private var isPhoneNumberTaken: Bool = false
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	// New: Indicate if this is an OAuth user (passed in or set from view model)
	var isOAuthUser: Bool = false

	private var isFormValid: Bool {
		let usernameValid = !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isUsernameTaken
		let phoneValid = !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
		if isOAuthUser {
			return usernameValid && phoneValid
		} else {
			return usernameValid && phoneValid && !password.isEmpty && !confirmPassword.isEmpty
				&& password == confirmPassword
		}
	}

	// Phone number formatter (US style: (XXX) XXX-XXXX)
	private func formatPhoneNumber(_ number: String) -> String {
		let digits = number.filter { $0.isNumber }
		var result = ""
		let count = digits.count
		if count == 0 { return "" }
		if count < 4 {
			result = digits
		} else if count < 7 {
			let area = digits.prefix(3)
			let prefix = digits.suffix(count - 3)
			result = "(\(area)) \(prefix)"
		} else {
			let area = digits.prefix(3)
			let prefix = digits.dropFirst(3).prefix(3)
			let line = digits.dropFirst(6).prefix(4)
			result = "(\(area)) \(prefix)-\(line)"
		}
		return result
	}

	var body: some View {
		VStack(spacing: 0) {
			// Navigation Bar - matches activity creation flow positioning
			HStack {
				UnifiedBackButton {
					// Clear any error states when going back
					viewModel.clearAllErrors()
					dismiss()
				}
				Spacer()
			}
			.padding(.horizontal, 25)
			.padding(.top, 16)

			Spacer()

			// Main Content
			VStack(spacing: 32) {
				// Title and Subtitle
				VStack(spacing: 16) {
					Text(isOAuthUser ? "Complete Your Profile" : "Create Your Account")
						.font(heading1)
						.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
					Text(
						isOAuthUser
							? "Add a username and phone number to complete your account."
							: "Just a few details to get started."
					)
					.font(.onestRegular(size: 16))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
					.multilineTextAlignment(.center)
				}
				.padding(.horizontal, 40)

				// Form Fields
				VStack(spacing: 24) {
					// Username Field
					VStack(alignment: .leading, spacing: 8) {
						Text("Username")
							.font(.onestRegular(size: 16))
							.foregroundColor(.primary)
						TextField("Create a unique nickname", text: $username)
							.textFieldStyle(ErrorTextFieldStyle(hasError: isUsernameTaken))
							.autocapitalization(.none)
							.textContentType(.username)
							.disableAutocorrection(true)
							.onChange(of: username) { _, newValue in
								// Simulate username taken error for demo (replace with real check)
								if newValue == "dagapov" {
									isUsernameTaken = true
									usernameError = "This username is taken. Existing users need to Sign In."
								} else {
									isUsernameTaken = false
									usernameError = nil
								}
							}
					}
					// Phone Number Field
					PhoneNumberInputField(
						phoneNumber: $phoneNumber,
						hasError: isPhoneNumberTaken,
						errorMessage: phoneError
					)
					.onChange(of: phoneNumber) { _, newValue in
						let formatted = formatPhoneNumber(newValue)
						if formatted != newValue {
							phoneNumber = formatted
						}
						// Check for taken phone number (demo scenario)
						if formatted == "(778) 100-1000" {
							isPhoneNumberTaken = true
							phoneError = "This phone number has already been used. Try signing in instead."
						} else {
							isPhoneNumberTaken = false
							phoneError = nil
						}
					}
					// Password Fields (only if not OAuth)
					if !isOAuthUser {
						VStack(alignment: .leading, spacing: 8) {
							Text("Password")
								.font(.onestRegular(size: 16))
								.foregroundColor(.primary)
							SecureField("Enter a strong password", text: $password)
								.textFieldStyle(ErrorSecureFieldStyle(hasError: isPasswordMismatch))
								.autocapitalization(.none)
								.textContentType(.newPassword)
						}
						VStack(alignment: .leading, spacing: 8) {
							Text("Confirm Password")
								.font(.onestRegular(size: 16))
								.foregroundColor(.primary)
							SecureField("Re-enter password", text: $confirmPassword)
								.textFieldStyle(ErrorSecureFieldStyle(hasError: isPasswordMismatch))
								.onChange(of: confirmPassword) { _, newValue in
									isPasswordMismatch = password != newValue
									passwordError =
										isPasswordMismatch ? "Please ensure that your passwords match." : nil
								}
								.onChange(of: password) { _, newValue in
									isPasswordMismatch = confirmPassword != newValue
									passwordError =
										isPasswordMismatch ? "Please ensure that your passwords match." : nil
								}
								.autocapitalization(.none)
								.textContentType(.newPassword)
						}
					}
					// Error Messages
					if usernameError != nil, isUsernameTaken {
						Text("This username is taken. Existing users need to sign in.")
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
							.padding(.top, -16)
					}
					if let phoneError = phoneError, isPhoneNumberTaken {
						Text(phoneError)
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
							.padding(.top, -16)
					}
					if let passwordError = passwordError, isPasswordMismatch && !isOAuthUser {
						Text(passwordError)
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
							.padding(.top, -16)
					}
					if let error = viewModel.errorMessage {
						Text(error)
							.font(Font.custom("Onest", size: 14).weight(.medium))
							.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
							.padding(.top, -16)
					}
					// Continue Button
					Button(action: {
						// Haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()

						// Execute action with slight delay for animation
						Task { @MainActor in
							try? await Task.sleep(for: .seconds(0.1))
							if isOAuthUser {
								// For OAuth users who don't exist yet, register them first
								if viewModel.spawnUser == nil {
									// First create the OAuth user with EMAIL_VERIFIED status
									let userCreated = await viewModel.createOAuthUserOnly(
										idToken: viewModel.idToken ?? "",
										provider: viewModel.authProvider ?? .google,
										email: viewModel.email,
										name: viewModel.name,
										profilePictureUrl: viewModel.profilePicUrl
									)

									// Then update with username and phone number if user was created successfully
									if userCreated, let user = viewModel.spawnUser {
										await viewModel.updateUserDetails(
											id: user.id.uuidString,
											username: username,
											phoneNumber: phoneNumber,
											password: nil
										)
									}
								} else {
									// For existing OAuth users, just update details
									await viewModel.updateUserDetails(
										id: viewModel.spawnUser!.id.uuidString,
										username: username,
										phoneNumber: phoneNumber,
										password: nil
									)
								}
							} else {
								// For email users, they should already exist at this point
								guard let user = viewModel.spawnUser else { return }
								await viewModel.updateUserDetails(
									id: user.id.uuidString,
									username: username,
									phoneNumber: phoneNumber,
									password: password
								)
							}
						}
					}) {
						OnboardingButtonCoreView("Continue") {
							isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
						}
					}
					.buttonStyle(PlainButtonStyle())
					.padding(.top, -16)
					.padding(.bottom, -30)
					.padding(.horizontal, -22)
					.disabled(!isFormValid)
				}
				.padding(.horizontal, 40)
			}
			Spacer()
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme).ignoresSafeArea())
		.navigationBarHidden(true)
		.onTapGesture {
			// Dismiss keyboard when tapping outside
			UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
		}
		.onAppear {
			// Clear any previous error state when this view appears
			viewModel.clearAllErrors()
		}
	}
}

#Preview {
	UserDetailsInputView()
}
