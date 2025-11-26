//
//  SMSShareService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude AI on 2025-01-21.
//

import Foundation
import MessageUI
import SwiftUI

class SMSShareService: NSObject, ObservableObject {
	static let shared = SMSShareService()

	private override init() {
		super.init()
	}

	// MARK: - Activity Sharing

	/// Shares an activity via SMS with the custom message format and app install CTA
	func shareActivity(
		_ activity: FullFeedActivityDTO,
		to phoneNumbers: [String]? = nil,
		from viewController: UIViewController? = nil
	) {
		guard MFMessageComposeViewController.canSendText() else {
			print("❌ SMS sharing not available on this device")
			fallbackToSystemSMS(activity: activity, phoneNumbers: phoneNumbers)
			return
		}

		// Generate the share URL first
		ServiceConstants.generateActivityShareCodeURL(for: activity.id) { [weak self] url in
			DispatchQueue.main.async {
				let shareURL = url ?? ServiceConstants.generateActivityShareURL(for: activity.id)
				let message = self?.generateActivitySMSMessage(activity: activity, shareURL: shareURL) ?? ""

				self?.presentMessageComposer(
					message: message,
					phoneNumbers: phoneNumbers,
					from: viewController
				)
			}
		}
	}

	/// Generates the custom SMS message for activity sharing
	func generateActivitySMSMessage(activity: FullFeedActivityDTO, shareURL: URL) -> String {
		let creatorFirstName = FormatterService.shared.formatFirstName(user: activity.creatorUser)
		let activityTitle = activity.title ?? "an activity"
		let locationName = activity.location?.name ?? "a location"
		let timeUntil = FormatterService.shared.timeUntil(activity.startTime)

		// Main invitation message (removed "Reply '1'..." sentence)
		let invitationMessage =
			"\(creatorFirstName) has invited you to \(activityTitle) \(timeUntil.lowercased()) @ \(locationName)."

		// App install CTA with App Store link instead of activity link
		let appInstallCTA =
			"See this activity and its chats on Spawn to stay in the loop. \n\nIt's never been easier to be spontaneous. Join your friends today!"

		return "\(AppStoreLinks.appStoreURL)\n\n\(invitationMessage)\n\n\(appInstallCTA)"
	}

	// MARK: - Message Composition

	private func presentMessageComposer(
		message: String,
		phoneNumbers: [String]?,
		from viewController: UIViewController?
	) {
		let messageComposer = MFMessageComposeViewController()
		messageComposer.messageComposeDelegate = self
		messageComposer.body = message

		if let phoneNumbers = phoneNumbers, !phoneNumbers.isEmpty {
			messageComposer.recipients = phoneNumbers
		}

		// Find the appropriate view controller to present from
		let presentingViewController = viewController ?? findTopViewController()

		guard let presenter = presentingViewController else {
			print("❌ Could not find view controller to present SMS composer")
			fallbackToSystemSMS(activity: nil, phoneNumbers: phoneNumbers, message: message)
			return
		}

		presenter.present(messageComposer, animated: true)
	}

	private func findTopViewController() -> UIViewController? {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			let window = windowScene.windows.first
		else {
			return nil
		}

		var topController = window.rootViewController
		while let presentedViewController = topController?.presentedViewController {
			topController = presentedViewController
		}

		return topController
	}

	// MARK: - Fallback Methods

	private func fallbackToSystemSMS(
		activity: FullFeedActivityDTO? = nil,
		phoneNumbers: [String]? = nil,
		message: String? = nil
	) {
		var smsMessage = message

		if smsMessage == nil, let activity = activity {
			ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
				let shareURL = url ?? ServiceConstants.generateActivityShareURL(for: activity.id)
				smsMessage = self.generateActivitySMSMessage(activity: activity, shareURL: shareURL)
				self.openSystemSMS(message: smsMessage!, phoneNumbers: phoneNumbers)
			}
		} else if let message = smsMessage {
			openSystemSMS(message: message, phoneNumbers: phoneNumbers)
		}
	}

	private func openSystemSMS(message: String, phoneNumbers: [String]?) {
		var smsURLString = "sms:"

		if let phoneNumbers = phoneNumbers, !phoneNumbers.isEmpty {
			smsURLString += phoneNumbers.joined(separator: ",")
		}

		if let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
			smsURLString += "?body=\(encodedMessage)"
		}

		if let smsURL = URL(string: smsURLString) {
			if UIApplication.shared.canOpenURL(smsURL) {
				UIApplication.shared.open(smsURL)
			} else {
				print("❌ System SMS not available")
			}
		}
	}
}

// MARK: - MFMessageComposeViewControllerDelegate

extension SMSShareService: MFMessageComposeViewControllerDelegate {
	func messageComposeViewController(
		_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult
	) {
		controller.dismiss(animated: true) {
			switch result {
			case .cancelled:
				print("📱 SMS sharing cancelled")
			case .sent:
				// Show success notification
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					InAppNotificationManager.shared.showNotification(
						title: "Invitation sent!",
						message: "Your activity invitation has been sent via SMS",
						type: .success,
						duration: 3.0
					)
				}
			case .failed:
				print("❌ SMS sending failed")
				// Show error notification
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					InAppNotificationManager.shared.showNotification(
						title: "Message failed",
						message: "Failed to send SMS invitation. Please try again.",
						type: .error,
						duration: 4.0
					)
				}
			@unknown default:
				print("❓ Unknown SMS result")
			}
		}
	}
}

// MARK: - App Store Constants

extension SMSShareService {
	struct AppStoreLinks {
		static let appStoreURL = "https://apps.apple.com/ca/app/spawn/id6738635871"
		static let appName = "Spawn"
		static let appStoreText = "Download \(appName) on the App Store: \(appStoreURL)"
	}
}
