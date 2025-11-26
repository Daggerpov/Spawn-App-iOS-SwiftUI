//
//  EnhancedActivityShareDrawer.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude AI on 2025-01-21.
//

import SwiftUI

struct EnhancedActivityShareDrawer: View {
	let activity: FullFeedActivityDTO
	@Environment(\.dismiss) private var dismiss
	@Environment(\.colorScheme) private var colorScheme
	@ObservedObject var themeService = ThemeService.shared
	@State private var showingContactPicker = false
	@State private var selectedContacts: [String] = []

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

	/// Returns the appropriate icon for the activity, prioritizing the activity's own icon over the activity type icon
	private var activityIcon: String {
		// First check if the activity has its own icon
		if let activityIcon = activity.icon, !activityIcon.isEmpty {
			return activityIcon
		}

		// Fall back to the activity type's icon if activityTypeId exists
		if let activityTypeId = activity.activityTypeId,
			let userId = UserAuthViewModel.shared.spawnUser?.id,
			let activityType = AppCache.shared.activityTypes[userId]?.first(where: { $0.id == activityTypeId }),
			!activityType.icon.isEmpty
		{
			return activityType.icon
		}

		// Final fallback to default star emoji
		return "⭐️"
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
				.padding(.bottom, 8)

			// Activity preview
			activityPreviewCard
				.padding(.horizontal, 16)
				.padding(.bottom, 24)

			// Share options
			VStack(spacing: 16) {
				// First row - primary sharing options
				HStack(spacing: 32) {
					// Enhanced SMS with contact picker
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .light)
						impactGenerator.impactOccurred()
						dismiss()
						shareViaSMSWithPicker()
					}) {
						shareButtonView(
							icon: "imessage_for_sharing",
							title: "Message",
							subtitle: "Custom invite"
						)
					}

					// Share via system
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .light)
						impactGenerator.impactOccurred()
						dismiss()
						shareViaSystem()
					}) {
						shareButtonView(
							systemIcon: "square.and.arrow.up",
							title: "Share via",
							subtitle: "More options"
						)
					}

					// Copy Link
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .light)
						impactGenerator.impactOccurred()
						shareViaLink()
						DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
							dismiss()
						}
					}) {
						shareButtonView(
							icon: "copy_link_button",
							title: "Copy Link",
							subtitle: "Share anywhere"
						)
					}
				}

				// Second row - social platforms
				HStack(spacing: 32) {
					// WhatsApp
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(style: .light)
						impactGenerator.impactOccurred()
						dismiss()
						shareViaWhatsApp()
					}) {
						shareButtonView(
							icon: "whatsapp_logo_for_sharing",
							title: "WhatsApp",
							subtitle: "Quick share"
						)
					}

					Spacer()
					Spacer()
				}
			}
			.padding(.horizontal, 16)
			.padding(.bottom, 24)

			Spacer()
		}
		.background(adaptiveBackgroundColor)
	}

	// MARK: - Activity Preview Card

	private var activityPreviewCard: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack {
				// Activity icon
				Text(activityIcon)
					.font(.title2)

				VStack(alignment: .leading, spacing: 2) {
					Text(activityTitle)
						.font(.onestSemiBold(size: 16))
						.foregroundColor(adaptiveTextColor)

					if let location = activity.location {
						Text(location.name)
							.font(.onestRegular(size: 14))
							.foregroundColor(.secondary)
					}

					if let startTime = activity.startTime {
						Text(FormatterService.shared.timeUntil(startTime))
							.font(.onestRegular(size: 14))
							.foregroundColor(.secondary)
					}
				}

				Spacer()

				// Creator info
				VStack(alignment: .trailing, spacing: 2) {
					Text("by \(FormatterService.shared.formatFirstName(user: activity.creatorUser))")
						.font(.onestRegular(size: 12))
						.foregroundColor(.secondary)

					if let participantCount = activity.participantUsers?.count, participantCount > 0 {
						Text("\(participantCount) spawning")
							.font(.onestRegular(size: 12))
							.foregroundColor(.secondary)
					}
				}
			}
		}
		.padding(12)
		.background(Color(.systemGray6))
		.cornerRadius(12)
	}

	// MARK: - Share Button View

	private func shareButtonView(
		icon: String? = nil,
		systemIcon: String? = nil,
		title: String,
		subtitle: String
	) -> some View {
		VStack(spacing: 8) {
			ZStack {
				Circle()
					.fill(adaptiveShareButtonBackgroundColor)
					.frame(width: 64, height: 64)

				if let icon = icon {
					Image(icon)
						.resizable()
						.aspectRatio(contentMode: .fit)
						.frame(width: 40, height: 40)
				} else if let systemIcon = systemIcon {
					Image(systemName: systemIcon)
						.font(.title2)
						.foregroundColor(adaptiveShareButtonTextColor)
				}
			}

			VStack(spacing: 2) {
				Text(title)
					.font(.system(size: 14, weight: .medium))
					.foregroundColor(adaptiveShareButtonTextColor)

				Text(subtitle)
					.font(.system(size: 11, weight: .regular))
					.foregroundColor(.secondary)
			}
		}
		.frame(width: 80)
	}

	// MARK: - Share Functions

	private func shareViaSMSWithPicker() {
		// Use the enhanced SMS sharing service
		SMSShareService.shared.shareActivity(activity)
	}

	private func shareViaSystem() {
		generateShareURL(for: activity) { activityURL in
			let creatorName = FormatterService.shared.formatFirstName(user: activity.creatorUser)
			let shareText = "\(creatorName) has invited you to \(activityTitle)! \(activityURL.absoluteString)"

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
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
			let creatorName = FormatterService.shared.formatFirstName(user: activity.creatorUser)
			let shareText = "\(creatorName) has invited you to \(activityTitle)! \(url.absoluteString)"

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

	private func generateShareURL(for activity: FullFeedActivityDTO, completion: @escaping (URL) -> Void) {
		// Use the centralized Constants for share URL generation with share codes
		ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
			completion(url ?? ServiceConstants.generateActivityShareURL(for: activity.id))
		}
	}
}

#Preview {
	EnhancedActivityShareDrawer(activity: .mockDinnerActivity)
}
