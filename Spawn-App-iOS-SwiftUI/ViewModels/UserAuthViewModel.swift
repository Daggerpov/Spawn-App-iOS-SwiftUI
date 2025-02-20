//
//  UserAuthViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import AuthenticationServices
import GoogleSignIn
import SwiftUI
import UIKit

class UserAuthViewModel: NSObject, ObservableObject {
	static let shared: UserAuthViewModel = UserAuthViewModel(
		apiService: MockAPIService.isMocking ? MockAPIService() : APIService())  // Singleton instance
	@Published var errorMessage: String?

	@Published var authProvider: AuthProviderType? = nil  // Track the auth provider
	@Published var externalUserId: String?  // For both Google and Apple
	@Published var isLoggedIn: Bool = false
	@Published var hasCheckedSpawnUserExistence: Bool = false
	@Published var spawnUser: User? {
		didSet {
			if spawnUser != nil {
				shouldNavigateToFeedView = true
			}
		}
	}

	@Published var givenName: String?
	@Published var fullName: String?
	@Published var familyName: String?
	@Published var email: String?
	@Published var profilePicUrl: String?

	@Published var isFormValid: Bool = false

	@Published var shouldProceedToFeed: Bool = false
	@Published var shouldNavigateToFeedView: Bool = false
	@Published var shouldNavigateToUserInfoInputView: Bool = false  // New property for navigation

	@Published var isLoading: Bool = false

	private var apiService: IAPIService

	// delete account:

	@Published var activeAlert: DeleteAccountAlertType?

	private init(apiService: IAPIService) {
		self.apiService = apiService

		// Retrieve externalUserId from Keychain
		if let data = KeychainService.shared.load(key: "externalUserId"),
			let externalUserId = String(data: data, encoding: .utf8)
		{
			self.externalUserId = externalUserId
			self.isLoggedIn = true
		}

		super.init()  // Call super.init() before using `self`

		check()
		Task {
			await spawnFetchUserIfAlreadyExists()
		}
	}

	func checkStatus() {
		if GIDSignIn.sharedInstance.currentUser != nil {
			let user = GIDSignIn.sharedInstance.currentUser
			guard let user = user else { return }
			self.fullName = user.profile?.name
			self.givenName = user.profile?.givenName
			self.familyName = user.profile?.familyName
			self.email = user.profile?.email
			self.profilePicUrl =
				user.profile?.imageURL(withDimension: 100)?.absoluteString
			self.isLoggedIn = true
			self.externalUserId = user.userID  // Google's externalUserId
		} else {
			resetState()
		}
	}

	func resetState() {
		// Reset user state
		self.errorMessage = nil
		self.authProvider = nil
		self.externalUserId = nil
		self.isLoggedIn = false
		self.hasCheckedSpawnUserExistence = false
		self.spawnUser = nil

		self.givenName = ""
		self.fullName = nil
		self.familyName = nil
		self.email = nil
		self.profilePicUrl = nil

		self.isFormValid = false

		self.shouldProceedToFeed = false
		self.shouldNavigateToFeedView = false
		self.shouldNavigateToUserInfoInputView = false
	}

	func check() {
		GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
			if let error = error {
				self.errorMessage = "error: \(error.localizedDescription)"
				print(self.errorMessage as Any)

			}
			self.checkStatus()
		}
	}

	func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
		switch result {
		case .success(let authorization):
			if let appleIDCredential = authorization.credential
				as? ASAuthorizationAppleIDCredential
			{
				let userIdentifier = appleIDCredential.user
				let email = appleIDCredential.email ?? "No email provided"
		case .success(let authorization):
			if let appleIDCredential = authorization.credential
				as? ASAuthorizationAppleIDCredential
			{
				let userIdentifier = appleIDCredential.user
				let email = appleIDCredential.email ?? "No email provided"

				// Set user details
				self.email = email
				self.givenName = appleIDCredential.fullName?.givenName
				self.familyName = appleIDCredential.fullName?.familyName
				self.isLoggedIn = true
				self.externalUserId = userIdentifier
				// Set user details
				self.email = email
				self.givenName = appleIDCredential.fullName?.givenName
				self.familyName = appleIDCredential.fullName?.familyName
				self.isLoggedIn = true
				self.externalUserId = userIdentifier

				// Check user existence AFTER setting credentials
				Task {
					await self.spawnFetchUserIfAlreadyExists()
				}
			}
		case .failure(let error):
			self.errorMessage =
				"Apple Sign-In failed: \(error.localizedDescription)"
			print(self.errorMessage as Any)
				// Check user existence AFTER setting credentials
				Task {
					await self.spawnFetchUserIfAlreadyExists()
				}
			}
		case .failure(let error):
			self.errorMessage =
				"Apple Sign-In failed: \(error.localizedDescription)"
			print(self.errorMessage as Any)
		}
	}

	func signInWithGoogle() async {
		await MainActor.run {
			guard
				let windowScene = UIApplication.shared.connectedScenes.first
					as? UIWindowScene,
				let presentingViewController = windowScene.windows.first?
					.rootViewController
			else {
				self.errorMessage =
					"Error: Unable to get the presenting view controller."
			guard
				let windowScene = UIApplication.shared.connectedScenes.first
					as? UIWindowScene,
				let presentingViewController = windowScene.windows.first?
					.rootViewController
			else {
				self.errorMessage =
					"Error: Unable to get the presenting view controller."
				print(self.errorMessage as Any)
				return
			}

			GIDConfiguration(
				clientID:
					"822760465266-hl53d2rku66uk4cljschig9ld0ur57na.apps.googleusercontent.com"
				clientID:
					"822760465266-hl53d2rku66uk4cljschig9ld0ur57na.apps.googleusercontent.com"
			)

			GIDSignIn.sharedInstance.signIn(
				withPresenting: presentingViewController
			) { signInResult, error in
			GIDSignIn.sharedInstance.signIn(
				withPresenting: presentingViewController
			) { signInResult, error in
				if let error = error {
					self.errorMessage = "Error: \(error.localizedDescription)"
					print(self.errorMessage as Any)
					return
				}

				guard let user = signInResult?.user else { return }
				self.profilePicUrl =
					user.profile?.imageURL(withDimension: 100)?.absoluteString
					?? ""
				self.profilePicUrl =
					user.profile?.imageURL(withDimension: 100)?.absoluteString
					?? ""
				self.fullName = user.profile?.name
				self.givenName = user.profile?.givenName
				self.familyName = user.profile?.familyName
				self.email = user.profile?.email
				self.isLoggedIn = true
				self.externalUserId = user.userID
				self.authProvider = .google

				Task {
					await self.spawnFetchUserIfAlreadyExists()
				}
			}
		}
	}

	func signInWithApple() {
		let appleIDProvider = ASAuthorizationAppleIDProvider()
		let request = appleIDProvider.createRequest()
		request.requestedScopes = [.fullName, .email]

		let authorizationController = ASAuthorizationController(
			authorizationRequests: [request]
		)
		authorizationController.delegate = self  // Ensure delegate is set
		authorizationController.delegate = self  // Ensure delegate is set
		authorizationController.performRequests()

		self.authProvider = .apple
	}

	func signOut() {
		// Sign out of Google
		GIDSignIn.sharedInstance.signOut()

		// Clear Apple Sign-In state
		if let externalUserId = self.externalUserId {
			// Invalidate Apple ID credential state (optional but recommended)
			let appleIDProvider = ASAuthorizationAppleIDProvider()
			appleIDProvider.getCredentialState(forUserID: externalUserId) {
				credentialState, error in
				if let error = error {
					print(
						"Failed to get Apple ID credential state: \(error.localizedDescription)"
					)
					return
				}
				switch credentialState {
				case .authorized:
					// The user is still authorized. You can optionally revoke the token.
					print("User is still authorized with Apple ID.")
				case .revoked:
					// The user has revoked access. Clear local state.
					print("User has revoked Apple ID access.")
				case .notFound:
					// The user is not found. Clear local state.
					print("User not found in Apple ID system.")
				default:
					break
				}
			}
		}

		// Clear externalUserId from Keychain
		let success = KeychainService.shared.delete(key: "externalUserId")
		if !success {
			print("Failed to delete externalUserId from Keychain")
		}

		resetState()
	}

	func spawnFetchUserIfAlreadyExists() async {
		guard let unwrappedExternalUserId = self.externalUserId else {
			await MainActor.run {
				self.errorMessage = "External User ID is missing."
				print(self.errorMessage as Any)
			}
			return
		}

		guard let unwrappedEmail = self.email else {
			await MainActor.run {
				self.errorMessage = "Email is missing or invalid."
				print(self.errorMessage as Any)
				self.shouldNavigateToUserInfoInputView = true
			}
			return
		}

		if let url = URL(string: APIService.baseURL + "oauth/sign-in") {
			do {
				let fetchedSpawnUser: User = try await self.apiService
					.fetchData(
						from: url,
						parameters: [
							"externalUserId": unwrappedExternalUserId,
							"email": unwrappedEmail,
						]
					)

				await MainActor.run {
					self.spawnUser = fetchedSpawnUser
					self.shouldNavigateToUserInfoInputView = false  // User exists, no need to navigate to UserInfoInputView
				}
			} catch {
				await MainActor.run {
					self.spawnUser = nil
					self.shouldNavigateToUserInfoInputView = true  // User does not exist, navigate to UserInfoInputView
					self.errorMessage =
						"Failed to fetch user: \(error.localizedDescription)"
					print(self.errorMessage as Any)
				}
				print(apiService.errorMessage ?? "")
			}
			await MainActor.run {
				self.hasCheckedSpawnUserExistence = true
			}
		}
	}

	func spawnMakeUser(
		username: String, profilePicture: UIImage?, firstName: String,
		lastName: String, email: String
	) async {
		// Convert UIImage to byte array (JPEG format)
		var profilePictureData: Data? = nil
		if let image = profilePicture {
			profilePictureData = image.jpegData(compressionQuality: 0.8)
		}

		// Create the User object
		let newUser = User(
			id: UUID(),
			username: username,
			profilePicture: nil,  // This will be set by the backend
			firstName: firstName,
			lastName: lastName,
			bio: "",
			email: email
		)

		// Prepare the URL with query parameters
		var urlComponents = URLComponents(
			string: APIService.baseURL + "oauth/make-user")!
		var queryItems: [URLQueryItem] = []

		if let unwrappedExternalUserId = externalUserId {
			queryItems.append(
				URLQueryItem(
					name: "externalUserId", value: unwrappedExternalUserId))
		}

		if let authProvider = self.authProvider {
			queryItems.append(
				URLQueryItem(name: "provider", value: authProvider.rawValue))
		}

		urlComponents.queryItems = queryItems

		guard let url = urlComponents.url else {
			print("Invalid URL for user creation.")
			return
		}

		// Create the request
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		// Add the UserDTO to the request body
		do {
			let userData = try JSONEncoder().encode(newUser)
			request.httpBody = userData
		} catch {
			print("Failed to encode user data: \(error.localizedDescription)")
			return
		}

		// Add the profile picture as multipart form data if it exists
		if let imageData = profilePictureData {
			let boundary = "Boundary-\(UUID().uuidString)"
			request.setValue(
				"multipart/form-data; boundary=\(boundary)",
				forHTTPHeaderField: "Content-Type")

			var body = Data()

			// Add UserDTO as JSON part
			body.append("--\(boundary)\r\n".data(using: .utf8)!)
			body.append(
				"Content-Disposition: form-data; name=\"userDTO\"\r\n".data(
					using: .utf8)!)
			body.append(
				"Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
			if let userData = try? JSONEncoder().encode(newUser) {
				body.append(userData)
			}
			body.append("\r\n".data(using: .utf8)!)

			// Add profile picture as binary part
			body.append("--\(boundary)\r\n".data(using: .utf8)!)
			body.append(
				"Content-Disposition: form-data; name=\"profilePicture\"; filename=\"profile.jpg\"\r\n"
					.data(using: .utf8)!)
			body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
			body.append(imageData)
			body.append("\r\n".data(using: .utf8)!)
			body.append("--\(boundary)--\r\n".data(using: .utf8)!)

			request.httpBody = body
		}

		// Send the request
		do {
			let (data, _) = try await URLSession.shared.data(for: request)
			let fetchedUser = try JSONDecoder().decode(User.self, from: data)

			await MainActor.run {
				self.spawnUser = fetchedUser
				self.shouldNavigateToUserInfoInputView = false
			}

			// Save externalUserId to Keychain after account creation
			if let externalUserId = self.externalUserId,
				let data = externalUserId.data(using: .utf8)
			{
				let success = KeychainService.shared.save(
					key: "externalUserId", data: data)
				if !success {
					print("Failed to save externalUserId to Keychain")
				}
			}

			print("User created successfully.")
		} catch {
			print("Error creating the user: \(error.localizedDescription)")
		}
	}

	func setShouldNavigateToFeedView() {
		shouldNavigateToFeedView = isLoggedIn && spawnUser != nil && isFormValid
	}

	func deleteAccount() async {
		guard let userId = spawnUser?.id else {
			await MainActor.run {
				activeAlert = .deleteError
			}
			return
		}

		if let url = URL(string: APIService.baseURL + "users/\(userId)") {
			do {
				try await self.apiService.deleteData(from: url)
				let success = KeychainService.shared.delete(key: "externalUserId")
				if !success {
					print("Failed to delete externalUserId from Keychain")
				}

				await MainActor.run {
					resetState()
					activeAlert = .deleteSuccess
				}
			} catch {
				print("Error deleting account: \(error.localizedDescription)")
				await MainActor.run {
					activeAlert = .deleteError
				}
			}
		}
	}
}

// Conform to ASAuthorizationControllerDelegate
extension UserAuthViewModel: ASAuthorizationControllerDelegate {
	func authorizationController(
		controller: ASAuthorizationController,
		didCompleteWithAuthorization authorization: ASAuthorization
	) {
		handleAppleSignInResult(.success(authorization))
	}

	func authorizationController(
		controller: ASAuthorizationController, didCompleteWithError error: Error
	) {
		handleAppleSignInResult(.failure(error))
	}

}
