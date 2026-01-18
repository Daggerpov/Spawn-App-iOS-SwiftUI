import SwiftUI

struct UserSetupView: View {
	@Environment(\.dismiss) private var dismiss
	@State private var isNavigating: Bool = false
	@ObservedObject var themeService = ThemeService.shared
	@Environment(\.colorScheme) var colorScheme

	var body: some View {
		VStack(spacing: 0) {
			// Navigation Bar - matches activity creation flow positioning
			HStack {
				UnifiedBackButton {
					dismiss()
				}
				Spacer()
			}
			.padding(.horizontal, 25)
			.padding(.top, 16)

			Spacer()

			// Onboarding graphic
			Image("onboarding_activity_cal")
				.resizable()
				.scaledToFit()
				.frame(maxWidth: 300)
				.padding(.bottom, 40)

			// Title and subtitle at the bottom
			VStack(spacing: 16) {
				Text("Let's Get You Set Up")
					.font(heading1)
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
					.multilineTextAlignment(.center)
				Text("It only takes a minute. We'll\npersonalize your experience.")
					.font(.onestRegular(size: 18))
					.foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
					.multilineTextAlignment(.center)
			}
			.padding(.bottom, 60)

			Spacer()

			// Start button
			Button(action: {
				// Haptic feedback
				let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
				impactGenerator.impactOccurred()

				// Execute action with slight delay for animation
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(0.1))
					isNavigating = true
				}
			}) {
				OnboardingButtonCoreView("Start") { figmaIndigo }
			}
			.buttonStyle(PlainButtonStyle())
			.padding(.bottom, 40)
		}
		.background(universalBackgroundColor(from: themeService, environment: colorScheme).ignoresSafeArea())
		.navigationBarHidden(true)
	}
}

#Preview {
	UserSetupView()
}
