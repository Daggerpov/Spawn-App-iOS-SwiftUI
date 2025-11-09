import SwiftUI

struct OnboardingContinuationView: View {
	@ObservedObject private var userAuth = UserAuthViewModel.shared
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	// Add state to prevent multiple button taps
	@State private var isProcessing: Bool = false

	var body: some View {
		ZStack {
			// Logo
			VStack(spacing: 30) {
				Image("logo_no_text")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 80, height: 80)
			}
			.offset(x: 0, y: -150)

			// Main content text
			VStack(spacing: 20) {
				Text("Welcome back!")
					.font(Font.custom("Onest", size: 32).weight(.bold))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))

				Text("Continue where you left off?")
					.font(Font.custom("Onest", size: 20))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
			}
			.frame(width: 364)
			.offset(x: 0, y: 6.50)

			// Action buttons
			VStack(spacing: 27) {
				Button(action: {
					// Prevent multiple taps
					guard !isProcessing else { return }

					isProcessing = true
					let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
					impactGenerator.impactOccurred()

					// Add a small delay to prevent rapid taps
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						// Navigation is now handled directly, no need for continuation popup
						userAuth.navigateOnStatus()

						// Reset processing state after a delay
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
							isProcessing = false
						}
					}
				}) {
					OnboardingButtonCoreView("Continue")
				}
				.buttonStyle(PlainButtonStyle())
				.disabled(isProcessing)

				Button(action: {
					// Prevent multiple taps
					guard !isProcessing else { return }

					isProcessing = true
					let impactGenerator = UIImpactFeedbackGenerator(style: .light)
					impactGenerator.impactOccurred()

					// Add a small delay to prevent rapid taps
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						userAuth.resetAuthFlow()
						userAuth.navigateTo(.signIn)

						// Reset processing state after a delay
						DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
							isProcessing = false
						}
					}
				}) {
					Text("Return to Login")
						.font(Font.custom("Onest", size: 17).weight(.medium))
						.underline()
						.foregroundColor(Color(red: 0.33, green: 0.42, blue: 0.93))
				}
				.buttonStyle(PlainButtonStyle())
				.disabled(isProcessing)
			}
			.padding(.horizontal, 22)
			.offset(x: 0, y: 124)
		}
		.frame(width: 428, height: 926)
		.background(universalBackgroundColor(from: themeService, environment: colorScheme))
		.ignoresSafeArea(.all)
		.navigationBarHidden(true)
	}
}

#Preview {
	OnboardingContinuationView()
}
