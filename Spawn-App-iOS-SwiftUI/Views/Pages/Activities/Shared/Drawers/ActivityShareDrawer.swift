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

	private var adaptiveTextColor: Color {
		universalAccentColor(from: themeService, environment: colorScheme)
	}

	private var adaptiveShareButtonBackgroundColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		case .light:
			return Color(red: 0.85, green: 0.82, blue: 0.82)
		@unknown default:
			return Color(red: 0.85, green: 0.82, blue: 0.82)
		}
	}

	private var adaptiveShareButtonTextColor: Color {
		switch colorScheme {
		case .dark:
			return Color(red: 0.82, green: 0.80, blue: 0.80)
		case .light:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		@unknown default:
			return Color(red: 0.52, green: 0.49, blue: 0.49)
		}
	}

	private var activityTitle: String {
		return activity.title ?? "Activity"
	}

	var body: some View {
		VStack(spacing: 0) {
			// Handle bar
			RoundedRectangle(cornerRadius: 2)
				.fill(Color(.systemGray4))
				.frame(width: 36, height: 4)
				.padding(.top, 8)
				.padding(.bottom, 16)

			// Title
			Text("Share this Spawn")
				.font(.onestSemiBold(size: 20))
				.foregroundColor(adaptiveTextColor)
				.padding(.bottom, 24)

			// Share options
			HStack(spacing: 32) {
				// Share via button
				Button(action: {
					let impactGenerator = UIImpactFeedbackGenerator(style: .light)
					impactGenerator.impactOccurred()
					dismiss()
					shareViaSystem()
				}) {
					VStack(spacing: 8) {
						ZStack {
							Circle()
								.fill(adaptiveShareButtonBackgroundColor)
								.frame(width: 64, height: 64)
							Image("share_via_button")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 40, height: 40)
						}
						Text("Share via")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(adaptiveShareButtonTextColor)
					}
					.frame(width: 64)
				}

				// Copy Link button
				Button(action: {
					let impactGenerator = UIImpactFeedbackGenerator(style: .light)
					impactGenerator.impactOccurred()
					shareViaLink()
					// Delay dismissing to show notification
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(0.1))
						dismiss()
					}
				}) {
					VStack(spacing: 8) {
						ZStack {
							Circle()
								.fill(adaptiveShareButtonBackgroundColor)
								.frame(width: 64, height: 64)
							Image("copy_link_button")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 40, height: 40)
						}
						Text("Copy Link")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(adaptiveShareButtonTextColor)
					}
					.frame(width: 68)
				}

				// WhatsApp button
				Button(action: {
					let impactGenerator = UIImpactFeedbackGenerator(style: .light)
					impactGenerator.impactOccurred()
					dismiss()
					shareViaWhatsApp()
				}) {
					VStack(spacing: 8) {
						Image("whatsapp_logo_for_sharing")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 64, height: 64)
						Text("WhatsApp")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(adaptiveShareButtonTextColor)
					}
					.frame(width: 72)
				}

				// iMessage button
				Button(action: {
					let impactGenerator = UIImpactFeedbackGenerator(style: .light)
					impactGenerator.impactOccurred()
					dismiss()
					shareViaSMS()
				}) {
					VStack(spacing: 8) {
						Image("imessage_for_sharing")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: 64, height: 64)
						Text("Message")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(adaptiveShareButtonTextColor)
					}
					.frame(width: 65)
				}
			}
			.padding(.horizontal, 16)
			.padding(.bottom, 24)

			Spacer()
		}
		.background(adaptiveBackgroundColor)
	}

	// MARK: - Share Functions
	private func shareViaSystem() {
		generateShareURL(for: activity) { activityURL in
			let shareText = "Join me for \"\(activityTitle)\"! \(activityURL.absoluteString)"

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
		generateShareURL(for: activity) { url in
			let shareText = "Join me for \"\(activityTitle)\"! \(url.absoluteString)"

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

	private func shareViaSMS() {
		// Use the new SMS sharing service with enhanced messaging
		SMSShareService.shared.shareActivity(activity)
	}

	private func generateShareURL(for activity: FullFeedActivityDTO, completion: @escaping (URL) -> Void) {
		// Use the centralized Constants for share URL generation with share codes
		ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
			completion(url ?? ServiceConstants.generateActivityShareURL(for: activity.id))
		}
	}
}

#Preview {
	ActivityShareDrawer(activity: .mockDinnerActivity)
}
