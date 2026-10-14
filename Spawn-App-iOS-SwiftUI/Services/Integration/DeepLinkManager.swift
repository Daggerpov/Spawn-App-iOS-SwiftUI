import Foundation
import SwiftUI

// MARK: - Deep Link Types
enum DeepLinkType {
	case activity(UUID)
	case profile(UUID)
	case unknown
}

// MARK: - Deep Link Manager
@MainActor
final class DeepLinkManager: ObservableObject {
	static let shared = DeepLinkManager()

	@Published var pendingDeepLink: DeepLinkType?
	@Published var shouldShowActivity = false
	@Published var activityToShow: UUID?
	@Published var shouldShowProfile = false
	@Published var profileToShow: UUID?

	private init() {}

	// MARK: - URL Handling
	func handleURL(_ url: URL) {
		AppLog.debug("🔗 DeepLinkManager: Handling incoming URL: \(url.absoluteString)", category: "DeepLink")

		// Handle both custom URL schemes (spawn://) and Universal Links (https://)
		guard url.scheme == "spawn" || (url.scheme == "https" && url.host == "getspawn.com") else {
			AppLog.warning(
				"❌ DeepLinkManager: Invalid URL scheme or host: \(url.scheme ?? "nil")://\(url.host ?? "nil")",
				category: "DeepLink")
			return
		}

		let deepLink = parseURL(url)
		processPendingDeepLink(deepLink)
	}

	// MARK: - URL Parsing
	private func parseURL(_ url: URL) -> DeepLinkType {
		let host = url.host ?? ""
		let pathComponents = url.pathComponents.filter { $0 != "/" }

		AppLog.debug(
			"🔗 DeepLinkManager: Parsing URL - Scheme: \(url.scheme ?? "nil"), Host: \(host), Path components: \(pathComponents)",
			category: "DeepLink"
		)

		// Handle Universal Links: https://getspawn.com/activity/{activityId} or https://getspawn.com/profile/{profileId}
		if url.scheme == "https" && host == "getspawn.com" {
			return parseUniversalLink(pathComponents: pathComponents)
		}

		// Handle custom URL schemes: spawn://activity/{activityId} or spawn://profile/{profileId}
		if url.scheme == "spawn" {
			return parseCustomURLScheme(host: host, pathComponents: pathComponents)
		}

		AppLog.warning("❌ DeepLinkManager: Unknown URL format", category: "DeepLink")
		return .unknown
	}

	// MARK: - Universal Link Parsing
	private func parseUniversalLink(pathComponents: [String]) -> DeepLinkType {
		AppLog.debug(
			"🔗 DeepLinkManager: Parsing Universal Link with path components: \(pathComponents)", category: "DeepLink")

		// Universal Link format: https://getspawn.com/activity/{activityId} or https://getspawn.com/profile/{profileId}
		// Share code format: https://getspawn.com/activity/{shareCode} or https://getspawn.com/profile/{shareCode}

		guard pathComponents.count >= 2 else {
			AppLog.warning(
				"❌ DeepLinkManager: Invalid Universal Link - not enough path components", category: "DeepLink")
			return .unknown
		}

		let type = pathComponents[0]
		let identifier = pathComponents[1]

		if type == "activity" {
			// Check if it's a UUID (legacy format) or share code (new format)
			if let activityId = UUID(uuidString: identifier) {
				return .activity(activityId)
			} else {
				// New share code format: https://getspawn.com/activity/{shareCode}
				AppLog.debug("🔗 DeepLinkManager: Detected activity share code: \(identifier)", category: "DeepLink")
				resolveActivityShareCode(shareCode: identifier)
				return .unknown  // Return unknown for now, will be handled by resolution
			}
		} else if type == "profile" {
			// Check if it's a UUID (legacy format) or share code (new format)
			if let profileId = UUID(uuidString: identifier) {
				return .profile(profileId)
			} else {
				// New share code format: https://getspawn.com/profile/{shareCode}
				AppLog.debug("🔗 DeepLinkManager: Detected profile share code: \(identifier)", category: "DeepLink")
				resolveProfileShareCode(shareCode: identifier)
				return .unknown  // Return unknown for now, will be handled by resolution
			}
		} else {
			AppLog.warning("❌ DeepLinkManager: Unknown Universal Link type: \(type)", category: "DeepLink")
		}

		return .unknown
	}

	private func parseCustomURLScheme(host: String, pathComponents: [String]) -> DeepLinkType {
		AppLog.debug(
			"🔗 DeepLinkManager: Parsing custom URL scheme with host: \(host), path components: \(pathComponents)",
			category: "DeepLink")

		// Custom URL scheme format: spawn://activity/{activityId} or spawn://profile/{profileId}
		if host == "activity" {
			// Host-based format: spawn://activity/{activityId}
			let activityIdString = pathComponents.first

			if let activityIdString = activityIdString,
				let activityId = UUID(uuidString: activityIdString)
			{
				return .activity(activityId)
			} else {
				AppLog.warning(
					"❌ DeepLinkManager: Failed to parse custom URL scheme activity ID from: \(activityIdString ?? "nil")",
					category: "DeepLink"
				)
			}
		} else if host == "profile" {
			// Host-based format: spawn://profile/{profileId}
			let profileIdString = pathComponents.first

			if let profileIdString = profileIdString,
				let profileId = UUID(uuidString: profileIdString)
			{
				return .profile(profileId)
			} else {
				AppLog.warning(
					"❌ DeepLinkManager: Failed to parse custom URL scheme profile ID from: \(profileIdString ?? "nil")",
					category: "DeepLink"
				)
			}
		} else if pathComponents.count >= 2 {
			let type = pathComponents[0]
			let idString = pathComponents[1]

			if type == "activity" {
				if let activityId = UUID(uuidString: idString) {
					return .activity(activityId)
				} else {
					AppLog.warning(
						"❌ DeepLinkManager: Failed to parse custom URL scheme path activity ID from: \(idString)",
						category: "DeepLink")
				}
			} else if type == "profile" {
				if let profileId = UUID(uuidString: idString) {
					return .profile(profileId)
				} else {
					AppLog.warning(
						"❌ DeepLinkManager: Failed to parse custom URL scheme path profile ID from: \(idString)",
						category: "DeepLink")
				}
			}
		}

		AppLog.warning(
			"❌ DeepLinkManager: Invalid custom URL scheme format - expected spawn://activity/{activityId} or spawn://profile/{profileId}",
			category: "DeepLink"
		)
		return .unknown
	}

	// MARK: - Deep Link Processing
	private func processPendingDeepLink(_ deepLink: DeepLinkType) {
		switch deepLink {
		case .activity(let activityId):
			AppLog.debug("🎯 DeepLinkManager: Processing activity deep link: \(activityId)", category: "DeepLink")
			pendingDeepLink = deepLink
			activityToShow = activityId
			shouldShowActivity = true

			// Check if user is authenticated to determine behavior
			handleActivityDeepLink(activityId)

			// Post notification for other parts of the app to listen to
			NotificationCenter.default.post(
				name: .deepLinkActivityReceived,
				object: nil,
				userInfo: ["activityId": activityId]
			)

		case .profile(let profileId):
			AppLog.debug("🎯 DeepLinkManager: Processing profile deep link: \(profileId)", category: "DeepLink")
			pendingDeepLink = deepLink
			profileToShow = profileId
			shouldShowProfile = true

			// Check if user is authenticated to determine behavior
			handleProfileDeepLink(profileId)

			// Post notification for other parts of the app to listen to
			NotificationCenter.default.post(
				name: .deepLinkProfileReceived,
				object: nil,
				userInfo: ["profileId": profileId]
			)

		case .unknown:
			AppLog.warning("❌ DeepLinkManager: Unknown deep link type, ignoring", category: "DeepLink")
			pendingDeepLink = nil
			activityToShow = nil
			shouldShowActivity = false
			profileToShow = nil
			shouldShowProfile = false
		}
	}

	// MARK: - Deep Link Handlers

	private func handleActivityDeepLink(_ activityId: UUID) {
		// If user has the app and is authenticated, open activity in-app
		if UserAuthViewModel.shared.isLoggedIn {
			AppLog.debug("🎯 DeepLinkManager: User authenticated - opening activity in-app", category: "DeepLink")
			// The activity will be opened by the ContentView listening to notifications
			// The deep link will register the user as invited to this activity
			// and show the activity popup in the UI
		} else {
			AppLog.debug(
				"🎯 DeepLinkManager: User not authenticated - will show activity invite page", category: "DeepLink")
			// If not authenticated, the app will show the activity invite page
			// where users can see activity details and join/install the app
		}
	}

	private func handleProfileDeepLink(_ profileId: UUID) {
		// If user has the app and is authenticated, open profile in Friends page
		if UserAuthViewModel.shared.isLoggedIn {
			AppLog.debug(
				"🎯 DeepLinkManager: User authenticated - opening profile in Friends page", category: "DeepLink")
			// The profile will be opened in the Friends tab by ContentView
		} else {
			AppLog.debug(
				"🎯 DeepLinkManager: User not authenticated - will show profile invite page", category: "DeepLink")
			// If not authenticated, show a profile preview/invite page
		}
	}

	// MARK: - Share Code Resolution
	private func resolveActivityShareCode(shareCode: String) {
		AppLog.debug("🔗 DeepLinkManager: Resolving activity share code: \(shareCode)", category: "DeepLink")

		let urlString = "\(ServiceConstants.URLs.apiBase)share/activity/\(shareCode)"
		guard let url = URL(string: urlString) else {
			AppLog.warning("❌ DeepLinkManager: Invalid URL for activity share code: \(shareCode)", category: "DeepLink")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		Task { [weak self] in
			do {
				let (data, _) = try await URLSession.shared.data(for: request)
				guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
					let activityIdString = json["id"] as? String,
					let activityId = UUID(uuidString: activityIdString)
				else {
					AppLog.warning(
						"❌ DeepLinkManager: Failed to resolve activity share code: \(shareCode)", category: "DeepLink")
					return
				}
				self?.processPendingDeepLink(.activity(activityId))
			} catch {
				AppLog.warning(
					"❌ DeepLinkManager: Network error resolving activity share code: \(error)", category: "DeepLink")
			}
		}
	}

	private func resolveProfileShareCode(shareCode: String) {
		AppLog.debug("🔗 DeepLinkManager: Resolving profile share code: \(shareCode)", category: "DeepLink")

		let urlString = "\(ServiceConstants.URLs.apiBase)share/profile/\(shareCode)"
		guard let url = URL(string: urlString) else {
			AppLog.warning("❌ DeepLinkManager: Invalid URL for profile share code: \(shareCode)", category: "DeepLink")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		Task { [weak self] in
			do {
				let (data, _) = try await URLSession.shared.data(for: request)
				guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
					let profileIdString = json["id"] as? String,
					let profileId = UUID(uuidString: profileIdString)
				else {
					AppLog.warning(
						"❌ DeepLinkManager: Failed to resolve profile share code: \(shareCode)", category: "DeepLink")
					return
				}
				self?.processPendingDeepLink(.profile(profileId))
			} catch {
				AppLog.warning(
					"❌ DeepLinkManager: Network error resolving profile share code: \(error)", category: "DeepLink")
			}
		}
	}

	// MARK: - State Management
	func clearPendingDeepLink() {
		AppLog.debug("🔗 DeepLinkManager: Clearing pending deep link", category: "DeepLink")
		pendingDeepLink = nil
		activityToShow = nil
		shouldShowActivity = false
		profileToShow = nil
		shouldShowProfile = false
	}

	func hasPendingDeepLink() -> Bool {
		return pendingDeepLink != nil
	}
}

// MARK: - Notification Names
extension Notification.Name {
	static let deepLinkActivityReceived = Notification.Name("deepLinkActivityReceived")
	static let deepLinkProfileReceived = Notification.Name("deepLinkProfileReceived")
}
