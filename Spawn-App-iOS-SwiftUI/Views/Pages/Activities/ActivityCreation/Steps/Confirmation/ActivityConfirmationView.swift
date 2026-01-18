import SwiftUI

struct ActivityConfirmationView: View {
	var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
	@ObservedObject var themeService = ThemeService.shared
	@Binding var showShareSheet: Bool
	@Environment(\.colorScheme) private var colorScheme
	let onClose: () -> Void
	let onBack: (() -> Void)?

	// MARK: - Adaptive Colors
	private var adaptiveBackgroundColor: Color {
		universalBackgroundColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveTextColor: Color {
		universalAccentColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveSecondaryTextColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		case .light:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		@unknown default:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		}
	}

	private var adaptiveButtonBorderColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light:
			return Color(hex: colorsGray700)
		@unknown default:
			return Color(hex: colorsGray700)
		}
	}

	private var adaptiveReturnButtonTextColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light:
			return Color(hex: colorsGray700)
		@unknown default:
			return Color(hex: colorsGray700)
		}
	}

	private var activityTitle: String {
		return viewModel.activity.title?.isEmpty == false
			? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Activity")
	}

	/// Converts the ActivityDTO to FullFeedActivityDTO for sharing
	private var fullActivityForSharing: FullFeedActivityDTO {
		let activity = viewModel.activity
		return FullFeedActivityDTO(
			id: activity.id,
			title: activity.title,
			startTime: activity.startTime,
			endTime: activity.endTime,
			location: activity.location,
			activityTypeId: activity.activityTypeId,
			note: activity.note,
			icon: activity.icon,
			participantLimit: activity.participantLimit,
			creatorUser: UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov,
			createdAt: activity.createdAt
		)
	}

	var body: some View {
		ZStack {
			VStack(spacing: 0) {
				// Header with back button and title
				headerView

				// Main content
				VStack(spacing: 0) {
					Spacer()

					VStack(spacing: 12) {
						Image("success-check")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 144, height: 144)

						Text("Success!")
							.font(Font.custom("Onest", size: 32).weight(.semibold))
							.foregroundColor(adaptiveTextColor)
						Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
							.font(Font.custom("Onest", size: 16).weight(.medium))
							.foregroundColor(adaptiveSecondaryTextColor)
							.multilineTextAlignment(.center)
							.padding(.horizontal, 32)

					}
					.padding(.bottom, 30)

					// Share with your network button
					Button(action: {
						// Add haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
						impactGenerator.impactOccurred()
						showShareSheet = true
					}) {
						HStack(spacing: 8) {
							Image(systemName: "square.and.arrow.up")
								.font(.system(size: 24, weight: .bold))
								.foregroundColor(.white)

							Text("Share with your network")
								.font(Font.custom("Onest", size: 20).weight(.semibold))
								.foregroundColor(.white)
						}
						.padding(.horizontal, 24)
						.padding(.vertical, 12)
						.frame(maxWidth: 324)
						.background(
							LinearGradient(
								colors: [Color(hex: "04F0D0"), Color(hex: "4360FF")],
								startPoint: .leading,
								endPoint: .trailing
							)
							.frame(width: 400, height: 400)
							.rotationEffect(Angle(degrees: -40))
						)
						.cornerRadius(100)
						.mask(Rectangle())  // keeps only this region visible
						.shadow(
							color: Color(hex: "000000").opacity(0.25),
							radius: 4,
							x: 0,
							y: 2
						)
					}
					.padding(.bottom, 22)

					// Return to Home button
					Button(action: {
						// Add haptic feedback
						let impactGenerator = UIImpactFeedbackGenerator(style: .light)
						impactGenerator.impactOccurred()
						onClose()
					}) {
						HStack(spacing: 8) {
							Text("Return to Home")
								.font(Font.custom("Onest", size: 16).weight(.medium))
								.foregroundColor(adaptiveReturnButtonTextColor)
						}
						.padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
						.frame(height: 43)
						.cornerRadius(100)
						.overlay(
							RoundedRectangle(cornerRadius: 100)
								.inset(by: 1)
								.stroke(adaptiveButtonBorderColor, lineWidth: 1)
						)
					}
					.shadow(
						color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
					)
					Spacer()

				}
			}

			// Share drawer overlay - uses unified ActivityShareDrawer component
			ActivityShareDrawer(
				activity: fullActivityForSharing,
				showShareSheet: $showShareSheet
			)
		}
		.background(adaptiveBackgroundColor)
	}

	// MARK: - Header View
	private var headerView: some View {
		HStack {
			// Back button
			if let onBack = onBack {
				ActivityBackButton {
					onBack()
				}
			}

			Spacer()

			// Title
			Text("Confirm")
				.font(.onestSemiBold(size: 20))
				.foregroundColor(adaptiveTextColor)

			Spacer()

			// Invisible chevron to balance the back button
			Image(systemName: "chevron.left")
				.font(.system(size: 20, weight: .semibold))
				.foregroundColor(.clear)
		}
		.padding(.horizontal, 25)
		.padding(.vertical, 12)
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @State var showShareSheet: Bool = false
	@Previewable @ObservedObject var appCache = AppCache.shared

	ActivityConfirmationView(
		showShareSheet: $showShareSheet,
		onClose: {
			print("Close tapped")
		},
		onBack: {
			print("Back tapped")
		}
	)
	.environmentObject(appCache)
}
