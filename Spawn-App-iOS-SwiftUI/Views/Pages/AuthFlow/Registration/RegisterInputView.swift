//
//  RegisterInputView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 7/2/25.
//

import SwiftUI

struct RegisterInputView: View {
	@ObservedObject var viewModel: UserAuthViewModel = .shared
	@State private var emailInput: String = ""
	@State private var emailError: String? = nil
	@State private var isEmailTaken: Bool = false
	var placeholder: String = "yourname@email.com"
	private var isFormValid: Bool {
		!emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(spacing: 0) {
			// Navigation Bar - matches activity creation flow positioning
			HStack {
				UnifiedBackButton {
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
					Text("Create Your Account")
						.font(heading1)
						.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
						.multilineTextAlignment(.center)

					Text("Choose how you'd like to set up your account.")
						.font(.onestRegular(size: 16))
						.foregroundColor(
							universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7)
						)
						.multilineTextAlignment(.center)
						.lineLimit(2)
				}
				.padding(.horizontal, 40)

				// Form Fields
				VStack(spacing: 24) {
					// Email Field
					VStack(alignment: .leading, spacing: 8) {
						Text("Email")
							.font(.onestRegular(size: 16))
							.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))

						TextField(placeholder, text: $emailInput)
							.textFieldStyle(ErrorTextFieldStyle(hasError: isEmailTaken))
							.textContentType(.emailAddress)
							.textInputAutocapitalization(.never)
							.onChange(of: emailInput) { _, newValue in
								// Simulate email taken error for demo (replace with real check)
								if newValue.lowercased() == "user@example.com" {
									isEmailTaken = true
									emailError = "This email has already been used. Try signing in instead."
								} else {
									isEmailTaken = false
									emailError = nil
								}
							}
					}

					// Email Error Message
					if let emailError = emailError, isEmailTaken {
						ZStack {
							Text(emailError)
								.font(Font.custom("Onest", size: 14).weight(.medium))
								.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
						}
						.frame(width: 363, height: 38)
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
							await viewModel.sendEmailVerification(email: emailInput)
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

				// Error Message
				if let error = viewModel.errorMessage {
					HStack(spacing: 6) {
						Image(systemName: "exclamationmark.circle.fill")
							.foregroundColor(.red)
						Text(error)
							.font(.onestRegular(size: 16))
							.foregroundColor(.red)
					}
					.padding(.top, 8)
					.padding(.horizontal, 40)
				}

				// Divider with "or"
				HStack {
					Rectangle()
						.fill(Color.gray.opacity(0.3))
						.frame(height: 1)

					Text("or")
						.font(.system(size: 16))
						.foregroundColor(
							universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7)
						)
						.padding(.horizontal, 16)

					Rectangle()
						.fill(Color.gray.opacity(0.3))
						.frame(height: 1)
				}
				.padding(.horizontal, 40)

				// External Login Buttons or Auto Sign-In State
				if !viewModel.isAutoSigningIn {
					VStack(spacing: 16) {
						// Continue with Apple
						Button(action: {
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()

							viewModel.appleRegister()
						}) {
							AuthProviderButtonView(.apple)
						}
						.buttonStyle(AuthProviderButtonStyle())

						// Continue with Google
						Button(action: {
							// Haptic feedback
							let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
							impactGenerator.impactOccurred()

							Task {
								await viewModel.googleRegister()
							}
						}) {
							AuthProviderButtonView(.google)
						}
						.buttonStyle(AuthProviderButtonStyle())
					}
					.padding(.horizontal, 40)
				} else {
					// Auto Sign-In Loading State
					VStack(spacing: 16) {
						ProgressView()
							.progressViewStyle(
								CircularProgressViewStyle(
									tint: universalAccentColor(from: themeService, environment: colorScheme))
							)
							.scaleEffect(1.2)

						Text("Account found! Signing you in...")
							.font(.onestMedium(size: 16))
							.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
							.multilineTextAlignment(.center)
					}
					.padding(.horizontal, 40)
					.transition(.opacity)
				}
			}

			Spacer()
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.navigationBarHidden(true)
		.onAppear {
			// Clear any previous error state when this view appears
			viewModel.clearAllErrors()
		}
	}
}

#Preview {
	RegisterInputView(viewModel: UserAuthViewModel.shared)
}
