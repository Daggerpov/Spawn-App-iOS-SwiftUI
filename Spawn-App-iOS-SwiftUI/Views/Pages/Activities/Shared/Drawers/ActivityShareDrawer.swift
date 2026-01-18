import SwiftUI

struct ActivityShareDrawer: View {
	let activity: FullFeedActivityDTO
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme
	@ObservedObject var themeService = ThemeService.shared

	// MARK: - Adaptive Colors
	private var adaptiveBackgroundColor: Color {
		universalBackgroundColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveTitleColor: Color {
		universalAccentColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveHandleColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.56, green: 0.52, blue: 0.52)
		case .light: return Color(red: 0.56, green: 0.52, blue: 0.52)
		@unknown default: return Color(red: 0.56, green: 0.52, blue: 0.52)
		}
	}

	/// Button background color (tertiary background from Figma)
	private var adaptiveButtonBackgroundColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.35, green: 0.33, blue: 0.33)
		case .light: return Color(red: 0.88, green: 0.85, blue: 0.85)
		@unknown default: return Color(red: 0.88, green: 0.85, blue: 0.85)
		}
	}

	/// Button text color (secondary text from Figma)
	private var adaptiveButtonTextColor: Color {
		switch colorScheme {
		case .dark: return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light: return Color(red: 0.15, green: 0.14, blue: 0.14)
		@unknown default: return Color(red: 0.15, green: 0.14, blue: 0.14)
		}
	}

	private var activityTitle: String {
		return activity.title ?? "Activity"
	}

	var body: some View {
		VStack(spacing: 0) {
			// Pull-down handle
			RoundedRectangle(cornerRadius: 100)
				.fill(adaptiveHandleColor)
				.frame(width: 50, height: 4)
				.padding(.top, 12)

			// Title
			Text("Share this Spawn")
				.font(.custom("Onest", size: 20).weight(.semibold))
				.foregroundColor(adaptiveTitleColor)
				.frame(maxWidth: .infinity, alignment: .leading)
				.padding(.top, 17)
				.padding(.horizontal, 29)

			// Share options
			HStack(spacing: 0) {
				// Share via button
				shareButton(
					action: {
						triggerHaptic()
						dismiss()
						shareViaSystem()
					},
					icon: AnyView(
						ZStack {
							Circle()
								.fill(adaptiveButtonBackgroundColor)
								.frame(width: 64, height: 64)
							Image("share_via_button")
								.resizable()
								.renderingMode(.template)
								.foregroundColor(adaptiveButtonTextColor)
								.aspectRatio(contentMode: .fit)
								.frame(width: 24, height: 24)
						}
					),
					label: "Share via",
					width: 64
				)

				Spacer()

				// Copy Link button
				shareButton(
					action: {
						triggerHaptic()
						shareViaLink()
						Task { @MainActor in
							try? await Task.sleep(for: .seconds(0.1))
							dismiss()
						}
					},
					icon: AnyView(
						ZStack {
							Circle()
								.fill(adaptiveButtonBackgroundColor)
								.frame(width: 64, height: 64)
							Image("copy_link_button")
								.resizable()
								.renderingMode(.template)
								.foregroundColor(adaptiveButtonTextColor)
								.aspectRatio(contentMode: .fit)
								.frame(width: 24, height: 24)
						}
					),
					label: "Copy Link",
					width: 68
				)

				Spacer()

				// WhatsApp button
				shareButton(
					action: {
						triggerHaptic()
						dismiss()
						shareViaWhatsApp()
					},
					icon: AnyView(
						Image("whatsapp_logo_for_sharing")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 64, height: 64)
							.clipShape(Circle())
					),
					label: "WhatsApp",
					width: 72
				)

				Spacer()

				// iMessage button
				shareButton(
					action: {
						triggerHaptic()
						dismiss()
						shareViaSMS()
					},
					icon: AnyView(
						Image("imessage_for_sharing")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 64, height: 64)
							.clipShape(Circle())
					),
					label: "iMessage",
					width: 65
				)
			}
			.padding(.horizontal, 29)
			.padding(.top, 24)

			Spacer()

			// Home indicator
			RoundedRectangle(cornerRadius: 100)
				.fill(adaptiveHandleColor)
				.frame(width: 134, height: 5)
				.padding(.bottom, 8)
		}
		.background(adaptiveBackgroundColor)
	}

	// MARK: - Share Button Component
	private func shareButton(
		action: @escaping () -> Void,
		icon: AnyView,
		label: String,
		width: CGFloat
	) -> some View {
		Button(action: action) {
			VStack(spacing: 8) {
				icon
				Text(label)
					.font(.system(size: 16, weight: .regular))
					.foregroundColor(adaptiveButtonTextColor)
			}
			.frame(width: width)
		}
	}

	private func triggerHaptic() {
		let impactGenerator = UIImpactFeedbackGenerator(style: .light)
		impactGenerator.impactOccurred()
	}

	// MARK: - Share Functions
	private func shareViaSystem() {
		let title = activityTitle
		generateShareURL(for: activity) { activityURL in
			Task { @MainActor in
				let shareText = "Join me for \"\(title)\"! \(activityURL.absoluteString)"

				let activityVC = UIActivityViewController(
					activityItems: [shareText],
					applicationActivities: nil
				)

				if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
					let window = windowScene.windows.first
				{

					var topController = window.rootViewController
					while let presentedViewController = topController?.presentedViewController {
						topController = presentedViewController
					}

					if let popover = activityVC.popoverPresentationController {
						popover.sourceView = topController?.view
						popover.sourceRect = topController?.view.bounds ?? CGRect.zero
					}

					topController?.present(activityVC, animated: true, completion: nil)
				}
			}
		}
	}

	private func shareViaLink() {
		generateShareURL(for: activity) { url in
			UIPasteboard.general.string = url.absoluteString

			// Show success notification
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.2))
				InAppNotificationManager.shared.showNotification(
					title: "Link copied to clipboard",
					message: "Activity link has been copied to your clipboard",
					type: .success,
					duration: 5.0
				)
			}
		}
	}

	private func shareViaWhatsApp() {
		let title = activityTitle
		generateShareURL(for: activity) { url in
			Task { @MainActor in
				let shareText = "Join me for \"\(title)\"! \(url.absoluteString)"

				if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
					let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)")
				{

					if UIApplication.shared.canOpenURL(whatsappURL) {
						UIApplication.shared.open(whatsappURL)
					} else {
						print("WhatsApp not installed or URL scheme not supported")
					}
				}
			}
		}
	}

	private func shareViaSMS() {
		// Use the new SMS sharing service with enhanced messaging
		SMSShareService.shared.shareActivity(activity)
	}

	private func generateShareURL(for activity: FullFeedActivityDTO, completion: @Sendable @escaping (URL) -> Void) {
		// Use the centralized Constants for share URL generation with share codes
		ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
			completion(url ?? ServiceConstants.generateActivityShareURL(for: activity.id))
		}
	}
}

#Preview {
	ActivityShareDrawer(activity: .mockDinnerActivity)
}
