import SwiftUI

// MARK: - Standalone Participants View (for sheets/full screen presentation)
struct ActivityParticipantsView: View {
	let activity: FullFeedActivityDTO
	let onDismiss: () -> Void
	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				// Background overlay
				(colorScheme == .dark ? Color.black.opacity(0.60) : Color.black.opacity(0.40))
					.ignoresSafeArea()
					.onTapGesture {
						onDismiss()
					}

				// Main participants container
				VStack(spacing: 0) {
					ParticipantsHeaderView(onBack: onDismiss)

					// Participants content that takes remaining space
					ScrollView {
						SharedParticipantsContent(activity: activity)
							.padding(.horizontal, 24)
							.padding(.bottom, 20)
					}

					bottomHandle
				}
				.background(Color(red: 0.33, green: 0.42, blue: 0.93).opacity(0.80))
				.cornerRadius(20)
				.padding(.horizontal, 20)
				.padding(.top, geometry.safeAreaInsets.top + 16)  // Dynamic safe area + extra padding
				.padding(.bottom, geometry.safeAreaInsets.bottom + 16)  // Dynamic safe area + extra padding
			}
		}
		.navigationBarBackButtonHidden(true)
	}

	// MARK: - View Components

	private var bottomHandle: some View {
		RoundedRectangle(cornerRadius: 2.5)
			.fill(Color.gray.opacity(0.6))
			.frame(width: 134, height: 5)
			.padding(.bottom, 8)
	}
}

#Preview {
	ActivityParticipantsView(
		activity: FullFeedActivityDTO.mockDinnerActivity,
		onDismiss: {}
	)
}
