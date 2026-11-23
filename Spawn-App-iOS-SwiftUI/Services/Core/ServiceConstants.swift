import Foundation

struct ServiceConstants {
	// MARK: - App Configuration
	struct URLs {
		// Base URL for API calls
		static let apiBase = "https://spawn-app-back-end-production.up.railway.app/api/v1/"

		// Base URL for sharing activities - updated to match deployed web app
		static let shareBase = "https://getspawn.com"

		/// Privacy Policy — open in browser from Settings → Legal → Privacy Policy and from terms (Section 5).
		static let privacyPolicy =
			"https://doc-hosting.flycricket.io/spawn-privacy-policy/8f254bc3-3403-4928-8353-f1f787ed6eec/privacy"
	}

	// MARK: - Share URL Generation
	static func generateActivityShareURL(for activityId: UUID) -> URL {
		// First try to get a share code from the backend
		// For now, fall back to UUID-based sharing until share codes are implemented
		guard let url = URL(string: "\(URLs.shareBase)/activity/\(activityId.uuidString)") else {
			return URL(string: "https://spawnapp.com")!
		}
		return url
	}

	static func generateProfileShareURL(for userId: UUID) -> URL {
		// First try to get a share code from the backend
		// For now, fall back to UUID-based sharing until share codes are implemented
		guard let url = URL(string: "\(URLs.shareBase)/profile/\(userId.uuidString)") else {
			return URL(string: "https://spawnapp.com")!
		}
		return url
	}

	// MARK: - Share Code Generation
	// Share codes come from an authenticated endpoint, so the request goes through APIService (which adds
	// the signed-in user's token). A plain URLSession call got a 401 and fell back to UUID links, which
	// getspawn.com can't open for people without the app (#197).
	static func generateActivityShareCodeURL(for activityId: UUID, completion: @Sendable @escaping (URL?) -> Void) {
		generateShareCodeURL(kind: "activity", id: activityId, completion: completion)
	}

	static func generateProfileShareCodeURL(for userId: UUID, completion: @Sendable @escaping (URL?) -> Void) {
		generateShareCodeURL(kind: "profile", id: userId, completion: completion)
	}

	private static func generateShareCodeURL(
		kind: String, id: UUID, completion: @Sendable @escaping (URL?) -> Void
	) {
		let fallbackUrl = URL(string: "\(URLs.shareBase)/\(kind)/\(id.uuidString)")
		guard let url = URL(string: "\(URLs.apiBase)share/\(kind)/\(id.uuidString)") else {
			completion(fallbackUrl)
			return
		}

		Task {
			do {
				let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()
				let response: [String: String]? = try await apiService.sendData(
					EmptyRequestBody(), to: url, parameters: nil)
				if let shareCode = response?["shareCode"], !shareCode.isEmpty,
					let shareUrl = URL(string: "\(URLs.shareBase)/\(kind)/\(shareCode)")
				{
					completion(shareUrl)
					return
				}
				AppLog.warning("Share code response had no code for \(kind) \(id)", category: "API")
			} catch {
				AppLog.warning("Share code generation failed for \(kind) \(id): \(error)", category: "API")
			}
			completion(fallbackUrl)
		}
	}
}
