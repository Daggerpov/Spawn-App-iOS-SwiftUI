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
	@Published var spawnUser: BaseUserDTO? {
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
			print("Retrieved externalUserId from Keychain: \(externalUserId)")
		}

		super.init()  // Call super.init() before using `self`

		// Only attempt to restore Google sign-in state if we have an externalUserId
		if self.externalUserId != nil {
			check()
		}
		
		// Try to fetch user data using stored externalUserId
		Task { [weak self] in
			guard let self = self else { return }
			
			if self.externalUserId != nil {
				print("Attempting to fetch user with stored externalUserId")
				await self.spawnFetchUserIfAlreadyExists()
			}
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
		self.activeAlert = nil
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
				if let email = appleIDCredential.email {
					self.email = email
				}

				// Set user details
				self.givenName = appleIDCredential.fullName?.givenName
				self.familyName = appleIDCredential.fullName?.familyName
				self.isLoggedIn = true
				self.externalUserId = userIdentifier

				// Check user existence AFTER setting credentials
				Task { [weak self] in
					guard let self = self else { return }
					await self.spawnFetchUserIfAlreadyExists()
				}
			}
		case .failure(let error):
			self.errorMessage =
				"Apple Sign-In failed: \(error.localizedDescription)"
			print(self.errorMessage as Any)
			// Check user existence AFTER setting credentials
			Task { [weak self] in
				guard let self = self else { return }
				await self.spawnFetchUserIfAlreadyExists()
			}
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
				print(self.errorMessage as Any)
				return
			}

			_ = GIDConfiguration(
				clientID:
					"822760465266-hl53d2rku66uk4cljschig9ld0ur57na.apps.googleusercontent.com"
			)

			GIDSignIn.sharedInstance.signIn(
				withPresenting: presentingViewController
			) { [weak self] signInResult, error in
				guard let self = self else { return }
				if let error = error {
					print(error.localizedDescription)
					return
				}

				guard let user = signInResult?.user else { return }
				// Request a higher resolution image (400px instead of 100px)
				self.profilePicUrl =
					user.profile?.imageURL(withDimension: 400)?.absoluteString
					?? ""
				print("Google profile picture URL: \(self.profilePicUrl ?? "none")")
				self.fullName = user.profile?.name
				self.givenName = user.profile?.givenName
				self.familyName = user.profile?.familyName
				self.email = user.profile?.email
				self.isLoggedIn = true
				self.externalUserId = user.userID
				self.authProvider = .google

				Task { [weak self] in
					guard let self = self else { return }
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
		
		// For Apple Sign In, if email is nil, we should direct to UserInfoInputView
		if self.authProvider == .apple && self.email == nil {
			await MainActor.run {
				self.spawnUser = nil
				self.shouldNavigateToUserInfoInputView = true
				self.hasCheckedSpawnUserExistence = true
			}
			return
		}

		// Only proceed with API call if we have email or it's not Apple auth
		let emailToUse = self.email ?? ""
		
		print("Fetching user with externalUserId: \(unwrappedExternalUserId), email: \(emailToUse)")

		if let url = URL(string: APIService.baseURL + "auth/sign-in") {
			do {
				let fetchedSpawnUser: BaseUserDTO = try await self.apiService
					.fetchData(
						from: url,
						parameters: [
							"externalUserId": unwrappedExternalUserId,
							"email": emailToUse,
						]
					)

				await MainActor.run {
					print("Successfully fetched user: \(fetchedSpawnUser.username)")
					self.spawnUser = fetchedSpawnUser
					self.shouldNavigateToUserInfoInputView = false  // User exists, no need to navigate to UserInfoInputView
					self.isFormValid = true  // Auto-validate the form since we have a valid user
					self.setShouldNavigateToFeedView() // Check if we should navigate to feed
				}
			} catch {
				await MainActor.run {
					self.spawnUser = nil
					self.shouldNavigateToUserInfoInputView = true  // User does not exist, navigate to UserInfoInputView
					self.errorMessage =
						"Failed to fetch user: \(error.localizedDescription)"
					print(self.errorMessage as Any)
				}
			}
			await MainActor.run {
				self.hasCheckedSpawnUserExistence = true
			}
		}
	}

	func spawnMakeUser(
		username: String,
		profilePicture: UIImage?,
		firstName: String,
		lastName: String,
		email: String
	) async {
		// Create the DTO
		let userDTO = UserCreateDTO(
			username: username,
			firstName: firstName,
			lastName: lastName,
			bio: "",
			email: email
		)

		// Prepare parameters
		var parameters: [String: String] = [:]
		if let unwrappedExternalUserId = externalUserId {
			parameters["externalUserId"] = unwrappedExternalUserId
		}
		if let authProvider = self.authProvider {
			parameters["provider"] = authProvider.rawValue
		}
		
		// If we have a profile picture URL from the provider (Google/Apple) and no selected image,
		// include it in the parameters so it can be used
		if profilePicture == nil, let profilePicUrl = self.profilePicUrl, !profilePicUrl.isEmpty {
			parameters["profilePicUrl"] = profilePicUrl
			print("Including provider profile picture URL in parameters: \(profilePicUrl)")
		}

		do {
			// Use the new createUser method
			let fetchedUser: BaseUserDTO = try await (apiService as! APIService)
				.createUser(
					userDTO: userDTO,
					profilePicture: profilePicture,
					parameters: parameters
				)

			await MainActor.run {
				self.spawnUser = fetchedUser
				self.shouldNavigateToUserInfoInputView = false
			}

			// Save externalUserId to Keychain
			if let externalUserId = self.externalUserId,
				let data = externalUserId.data(using: .utf8)
			{
				let success = KeychainService.shared.save(
					key: "externalUserId", data: data)
				if !success {
					print("Failed to save externalUserId to Keychain")
				} else {
					print("Successfully saved externalUserId to Keychain: \(externalUserId)")
				}
			}

			print("User created successfully: \(fetchedUser.username)")
			if let profilePic = fetchedUser.profilePicture {
				print("Profile picture set: \(profilePic)")
			} else {
				print("No profile picture set in created user")
			}

		} catch {
			print("Error creating the user: \(error)")
			if let apiError = error as? APIError {
				print("API Error: \(apiError.localizedDescription)")
			}
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
				let success = KeychainService.shared.delete(
					key: "externalUserId")
				if !success {
					print("Failed to delete externalUserId from Keychain")
				}

				await MainActor.run {
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

struct UserCreateDTO: Codable {
	let username: String
	let firstName: String
	let lastName: String
	let bio: String
	let email: String
}
