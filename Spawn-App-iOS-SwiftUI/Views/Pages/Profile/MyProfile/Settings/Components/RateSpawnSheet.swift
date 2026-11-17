import SwiftUI

/// Small sheet shown from Settings > Rate Spawn. Asks for a 1-5 star rating before
/// deciding whether to request an App Store review or route the user to feedback.
struct RateSpawnSheet: View {
	/// Called once with the chosen rating (1...5) after the stars fill in.
	let onRate: (Int) -> Void
	let onDismiss: () -> Void

	@State private var selectedRating: Int = 0

	private static let starCount = 5

	var body: some View {
		VStack(spacing: 20) {
			VStack(spacing: 8) {
				Text("Enjoying Spawn?")
					.font(.onestSemiBold(size: 20))
					.foregroundColor(universalAccentColor)

				Text("Tap a star to rate your experience.")
					.font(.onestRegular(size: 15))
					.foregroundColor(universalSecondaryTextColor)
					.multilineTextAlignment(.center)
			}

			HStack(spacing: 14) {
				ForEach(1...Self.starCount, id: \.self) { star in
					Button {
						select(star)
					} label: {
						Image(systemName: star <= selectedRating ? "star.fill" : "star")
							.font(.system(size: 34, weight: .medium))
							.foregroundColor(
								star <= selectedRating ? universalSecondaryColor : universalPlaceHolderTextColor
							)
							.frame(width: 44, height: 44)
							.contentShape(Rectangle())
					}
					.buttonStyle(.plain)
					.disabled(selectedRating > 0)
					.accessibilityLabel("\(star) star\(star == 1 ? "" : "s")")
				}
			}

			Button(action: onDismiss) {
				Text("Not now")
					.font(.onestMedium(size: 16))
					.foregroundColor(universalSecondaryTextColor)
					.frame(maxWidth: .infinity)
					.padding(.vertical, 12)
					.contentShape(Rectangle())
			}
			.buttonStyle(.plain)
		}
		.padding(.horizontal, 24)
		.padding(.top, 28)
		.padding(.bottom, 12)
		.frame(maxWidth: .infinity)
		.background(universalBackgroundColor)
		.presentationBackground(universalBackgroundColor)
		.presentationDetents([.height(250)])
		.presentationDragIndicator(.visible)
	}

	private func select(_ rating: Int) {
		guard selectedRating == 0 else { return }
		withAnimation(.easeOut(duration: 0.15)) {
			selectedRating = rating
		}
		// Let the filled stars register before the sheet goes away.
		Task {
			try? await Task.sleep(for: .milliseconds(300))
			onRate(rating)
		}
	}
}

@available(iOS 17, *)
#Preview {
	Color.clear
		.sheet(isPresented: .constant(true)) {
			RateSpawnSheet(onRate: { _ in }, onDismiss: {})
		}
}
