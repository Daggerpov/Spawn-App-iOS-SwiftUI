import Foundation

/// Data transfer object for registering a device token with the backend
struct DeviceTokenDTO: Codable, Sendable {
	/// The device token from APNS
	let token: String

	/// The platform (iOS, Android, etc.)
	let deviceType: String

	/// The user ID associated with this device token
	let userId: UUID
}
