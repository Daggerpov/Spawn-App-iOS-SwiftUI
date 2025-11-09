import SwiftUI

struct VerificationCodeView: View {
	@ObservedObject var userAuthViewModel: UserAuthViewModel
	@StateObject private var viewModel: VerificationCodeViewModel
	@FocusState private var focusedIndex: Int?
	@Environment(\.dismiss) var dismiss
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	init(userAuthViewModel: UserAuthViewModel) {
		self.userAuthViewModel = userAuthViewModel
		self._viewModel = StateObject(wrappedValue: VerificationCodeViewModel(userAuthViewModel: userAuthViewModel))
	}

	private var inputBackgroundColor: Color {
		if userAuthViewModel.errorMessage != nil {
			return Color.red.opacity(0.1)
		}
		return colorScheme == .dark ? Color(hex: "#2C2C2C") : Color(hex: colorsGrayInput)
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Button(action: {
					// Clear any error states when going back
					userAuthViewModel.clearAllErrors()
					dismiss()
				}) {
					Image(systemName: "chevron.left")
						.font(.title2)
						.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
				}
				Spacer()
			}
			.padding(.leading, 80)
			.padding(.top, 10)
			Spacer()
			mainContent
			Spacer()
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.onAppear {
			viewModel.initialize()
			focusedIndex = viewModel.focusedIndex
			// Clear any previous error state when this view appears
			userAuthViewModel.clearAllErrors()
		}
		.onDisappear {
			viewModel.stopTimer()
		}
		.navigationBarHidden(true)
	}

	private var navigationBar: some View {
		HStack {
			Button(action: {
				// Go back one step in the onboarding flow
				dismiss()
			}) {
				Image(systemName: "chevron.left")
					.font(.title2)
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			}
			Spacer()
		}
		.padding(.horizontal, 20)
		.padding(.top, 20)
		.padding(.bottom, 10)
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.zIndex(1)
	}

	private var mainContent: some View {
		VStack(spacing: 32) {
			titleSection
			formSection
			resendSection
			errorSection
		}
		.padding(.horizontal, 40)
	}

	private var titleSection: some View {
		VStack(spacing: 16) {
			Text("Verify Your Email")
				.font(heading1)
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			Text("We've sent a 6-digit code to " + (userAuthViewModel.email ?? "your email"))
				.font(.onestRegular(size: 16))
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
				.multilineTextAlignment(.center)
		}
		.padding(.horizontal, 40)
	}

	private var formSection: some View {
		VStack(spacing: 24) {
			verificationCodeInput
			verifyButton
		}
		.padding(.horizontal, 40)
	}

	private var verificationCodeInput: some View {
		VStack(alignment: .leading, spacing: 8) {
			Text("Verification Code")
				.font(.onestRegular(size: 16))
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			HStack(spacing: 12) {
				ForEach(0..<6, id: \.self) { idx in
					codeInputField(at: idx)
				}
			}
		}
	}

	private func codeInputField(at index: Int) -> some View {
		ZStack {
			Rectangle()
				.fill(inputBackgroundColor)
				.frame(width: 48, height: 56)
				.cornerRadius(12)
				.overlay(
					RoundedRectangle(cornerRadius: 12)
						.stroke(userAuthViewModel.errorMessage != nil ? Color.red : Color.clear, lineWidth: 2)
				)
			BackspaceDetectingTextField(
				text: createBinding(for: index),
				onBackspace: {
					viewModel.handleBackspace(at: index)
					focusedIndex = viewModel.focusedIndex
				},
				onPaste: { pastedText in
					viewModel.handlePaste(pastedText: pastedText, startingAt: index)
					focusedIndex = viewModel.focusedIndex
				},
				keyboardType: .numberPad,
				textAlignment: .center,
				font: UIFont(name: "Onest-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24),
				textColor: UIColor(universalAccentColor(from: themeService, environment: colorScheme))
			)
			.frame(width: 48, height: 56)
			.focused($focusedIndex, equals: index)
			.onChange(of: viewModel.code[index]) { _, newValue in
				viewModel.handleTextFieldChange(at: index, oldValue: viewModel.previousCode[index], newValue: newValue)
				viewModel.previousCode[index] = newValue
				focusedIndex = viewModel.focusedIndex
			}

		}
		.onTapGesture {
			focusedIndex = index
			viewModel.focusedIndex = index
		}
	}

	private func createBinding(for index: Int) -> Binding<String> {
		Binding(
			get: { viewModel.code[index] },
			set: { newValue in
				// The custom text field handles validation, so just update the value
				viewModel.code[index] = newValue
			}
		)
	}

	private var verifyButton: some View {
		Button(action: {
			Task {
				await viewModel.verifyCode()
			}
		}) {
			OnboardingButtonCoreView("Verify") {
				viewModel.isFormValid ? figmaIndigo : Color.gray.opacity(0.6)
			}
		}
		.padding(.top, -16)
		.padding(.bottom, -30)
		.padding(.horizontal, -22)
		.disabled(!viewModel.isFormValid)
	}

	private var resendSection: some View {
		HStack(spacing: 4) {
			Text("Didn't get it?")
				.font(.onestRegular(size: 16))
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			Button(action: {
				Task {
					await viewModel.resendCode()
				}
			}) {
				Text("Resend code")
					.underline()
					.font(.onestRegular(size: 16))
					.foregroundColor(
						viewModel.isResendEnabled
							? figmaIndigo
							: universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
			}
			.disabled(!viewModel.isResendEnabled)
			Text("in \(String(format: "%02d", viewModel.secondsRemaining))")
				.font(.onestRegular(size: 16))
				.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme).opacity(0.7))
				.opacity(viewModel.isResendEnabled ? 0 : 1)
		}
		.padding(.top, 8)
	}

	@ViewBuilder
	private var errorSection: some View {
		if userAuthViewModel.errorMessage != nil {
			Text("Invalid code. Try again.")
				.font(Font.custom("Onest", size: 14).weight(.medium))
				.foregroundColor(Color(red: 0.92, green: 0.26, blue: 0.21))
				.padding(.top, 8)
		}
	}
}

#Preview {
	VerificationCodeView(userAuthViewModel: UserAuthViewModel.shared)
}
