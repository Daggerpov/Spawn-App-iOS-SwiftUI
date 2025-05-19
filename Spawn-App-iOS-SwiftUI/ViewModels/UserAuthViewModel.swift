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
import FirebaseMessaging

class UserAuthViewModel: NSObject, ObservableObject {
	static let shared: UserAuthViewModel = UserAuthViewModel(
		apiService: MockAPIService.isMocking ? MockAPIService() : APIService())  // Singleton instance
	@Published var errorMessage: String?

	@Published var authProvider: AuthProviderType? = nil  // Track the auth provider
	@Published var externalUserId: String?  // For both Google and Apple
	@Published var googleIdToken: String?  // Store Google ID token for authentication
	@Published var appleIdToken: String?   // Store Apple ID token for authentication
	@Published var isLoggedIn: Bool = false
	@Published var hasCheckedSpawnUserExistence: Bool = false
	@Published var spawnUser: BaseUserDTO? {
		didSet {
			if spawnUser != nil {
				shouldNavigateToFeedView = true
			}
		}
	}

	@Published var name: String?
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

	// Auth alerts for authentication-related errors
	@Published var authAlert: AuthAlertType?

	@Published var defaultPfpFetchError: Bool = false
	@Published var defaultPfpUrlString: String? = nil

	private init(apiService: IAPIService) {
        self.spawnUser = BaseUserDTO.danielAgapov
		self.apiService = apiService

		// Retrieve externalUserId from Keychain
		if let data = KeychainService.shared.load(key: "externalUserId"),
			let externalUserId = String(data: data, encoding: .utf8)
		{
			self.externalUserId = externalUserId
			self.isLoggedIn = true
			print("Retrieved externalUserId from Keychain: \(externalUserId)")
		}
		
		// Retrieve Google ID token from Keychain
		if let data = KeychainService.shared.load(key: "googleIdToken"),
		   let googleIdToken = String(data: data, encoding: .utf8)
		{
			self.googleIdToken = googleIdToken
			print("Retrieved Google ID token from Keychain")
		}

		super.init()  // Call super.init() before using `self`

		// Only attempt to restore Google sign-in state if we have an externalUserId
		if self.externalUserId != nil {
			checkStatus()
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
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
                print(self.errorMessage as Any)
                
            }
            if GIDSignIn.sharedInstance.currentUser != nil {
                let user = GIDSignIn.sharedInstance.currentUser
                guard let user = user else { return }
                self.name = user.profile?.name
                self.email = user.profile?.email
                self.profilePicUrl =
                user.profile?.imageURL(withDimension: 100)?.absoluteString
                self.isLoggedIn = true
                self.externalUserId = user.userID  // Google's externalUserId
                
                // Refresh token if needed to get valid ID token
                user.refreshTokensIfNeeded { user, error in
                    guard error == nil else { 
                        print("Error refreshing token: \(error?.localizedDescription ?? "Unknown error")")
                        return 
                    }
                    guard let user = user else { return }
                    
                    self.googleIdToken = user.idToken?.tokenString
                    
                    // Save ID token to keychain
                    if let idToken = self.googleIdToken, let data = idToken.data(using: .utf8) {
                        let success = KeychainService.shared.save(key: "googleIdToken", data: data)
                        if !success {
                            print("Error saving googleIdToken to Keychain")
                        }
                    }
                }
                
                // If we have a spawnUser already, post the login notification
                if self.spawnUser != nil {
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                }
            } else {
                self.resetState()
            }
        }
	}

	func resetState() {
		// Reset user state
		self.errorMessage = nil
		self.authProvider = nil
		self.externalUserId = nil
		self.googleIdToken = nil
		self.appleIdToken = nil
		self.isLoggedIn = false
		self.hasCheckedSpawnUserExistence = false
		self.spawnUser = nil

		self.name = nil
		self.email = nil
		self.profilePicUrl = nil

		self.isFormValid = false

		self.shouldProceedToFeed = false
		self.shouldNavigateToFeedView = false
		self.shouldNavigateToUserInfoInputView = false
		self.activeAlert = nil
		self.authAlert = nil

		self.defaultPfpFetchError = false
		self.defaultPfpUrlString = nil
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
				if let givenName = appleIDCredential.fullName?.givenName,
                   let familyName = appleIDCredential.fullName?.familyName {
                    self.name = "\(givenName) \(familyName)"
                } else if let givenName = appleIDCredential.fullName?.givenName {
                    self.name = givenName
                }
				
				// Get identity token
				if let identityTokenData = appleIDCredential.identityToken,
				   let identityToken = String(data: identityTokenData, encoding: .utf8) {
					self.appleIdToken = identityToken
					
					// Save Apple ID token to keychain
					let success = KeychainService.shared.save(key: "appleIdToken", data: identityTokenData)
					if !success {
						print("Error saving appleIdToken to Keychain")
					} else {
						print("Successfully saved appleIdToken to Keychain")
					}
				}
				
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
				clientID: "822760465266-1dunhm4jgrcg17137rfjo2idu5qefchk.apps.googleusercontent.com"
			)

			GIDSignIn.sharedInstance.signIn(
				withPresenting: presentingViewController
			) { [weak self] signInResult, error in
				guard let self = self else { return }
				if let error = error {
					print(error.localizedDescription)
					return
				}

				guard let signInResult = signInResult else { return }
				guard let user = signInResult.user else { return }
				// Request a higher resolution image (400px instead of 100px)
				self.profilePicUrl =
					user.profile?.imageURL(withDimension: 400)?.absoluteString
					?? ""
				self.name = user.profile?.name
				self.email = user.profile?.email
				self.isLoggedIn = true
				self.externalUserId = user.userID
				self.authProvider = .google
				
				// Get ID token
				user.refreshTokensIfNeeded { [weak self] user, error in
					guard let self = self else { return }
					guard error == nil else { 
						print("Error refreshing token: \(error?.localizedDescription ?? "Unknown error")")
						return 
					}
					guard let user = user else { return }
					
					self.googleIdToken = user.idToken?.tokenString
					
					// Save ID token to keychain
					if let idToken = self.googleIdToken, let data = idToken.data(using: .utf8) {
						let success = KeychainService.shared.save(key: "googleIdToken", data: data)
						if !success {
							print("Error saving googleIdToken to Keychain")
						}
					}
					
					Task { [weak self] in
						guard let self = self else { return }
						await self.spawnFetchUserIfAlreadyExists()
					}
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
					// The user not found. Clear local state.
					print("User not found in Apple ID system.")
				default:
					break
				}
			}
		}
		
		// Unregister device token from backend
		Task {
			// Use the NotificationService to unregister the token
			await NotificationService.shared.unregisterDeviceToken()
		}

		// Clear externalUserId from Keychain
		var success = KeychainService.shared.delete(key: "externalUserId")
		if !success {
			print("Failed to delete externalUserId from Keychain")
		}
		success = KeychainService.shared.delete(key: "accessToken")
		if !success {
			print("Failed to delete accessToken from Keychain")
		}
		success = KeychainService.shared.delete(key: "refreshToken")
		if !success {
			print("Failed to delete refreshToken from Keychain")
		}
		success = KeychainService.shared.delete(key: "appleIdToken")
		if !success {
			print("Failed to delete appleIdToken from Keychain")
		}

		resetState()
	}

	func spawnFetchUserIfAlreadyExists() async {
		// For Google auth, use ID token if available, otherwise fall back to external user ID
		// For Apple auth, use ID token if available, otherwise fall back to external user ID
		let authIdentifier: String
		let isGoogleAuth = self.authProvider == .google
		let isAppleAuth = self.authProvider == .apple
		
		if isGoogleAuth, let unwrappedIdToken = self.googleIdToken {
			authIdentifier = unwrappedIdToken
		} else if isAppleAuth, let unwrappedIdToken = self.appleIdToken {
			authIdentifier = unwrappedIdToken
		} else if let unwrappedExternalUserId = self.externalUserId {
			authIdentifier = unwrappedExternalUserId
		} else {
			await MainActor.run {
				self.errorMessage = "Authentication identifier is missing."
				print(self.errorMessage as Any)
			}
			return
		}
		
		// Only proceed with API call if we have email or it's not Apple auth
		let emailToUse = self.email ?? ""
		
		if let url = URL(string: APIService.baseURL + "auth/sign-in") {
				// First, try to decode as a single user object
				do {
					let parameters: [String: String]
					if isGoogleAuth {
						parameters = ["idToken": authIdentifier, "email": emailToUse, "provider": "google"]
					} else if isAppleAuth {
						parameters = ["idToken": authIdentifier, "email": emailToUse, "provider": "apple"]
					} else {
						parameters = ["externalUserId": authIdentifier, "email": emailToUse]
					}
					
					let fetchedSpawnUser: BaseUserDTO = try await self.apiService
						.fetchData(
							from: url,
							parameters: parameters
						)
							
					// Save authentication identifier to keychain
					if isGoogleAuth, let idToken = self.googleIdToken, let data = idToken.data(using: .utf8) {
						print("Saving googleIdToken to Keychain")
						let success = KeychainService.shared.save(key: "googleIdToken", data: data)
						if !success {
							print("Error saving googleIdToken to Keychain")
						}
					} else if isAppleAuth, let idToken = self.appleIdToken, let data = idToken.data(using: .utf8) {
						print("Saving appleIdToken to Keychain")
						let success = KeychainService.shared.save(key: "appleIdToken", data: data)
						if !success {
							print("Error saving appleIdToken to Keychain")
						}
					} else if let data = authIdentifier.data(using: .utf8) {
						print("Saving externalUserId to Keychain")
						let success = KeychainService.shared.save(key: "externalUserId", data: data)
						if !success {
							print("Error saving externalUserId to Keychain")
						}
					}
                    
					await MainActor.run {
						self.spawnUser = fetchedSpawnUser
                        print("user id: \(fetchedSpawnUser.id)")
						self.shouldNavigateToUserInfoInputView = false
						self.isFormValid = true
						self.setShouldNavigateToFeedView()
                        
						// Post notification that user did login successfully
						NotificationCenter.default.post(name: .userDidLogin, object: nil)
					}
				} catch let error as APIError {
					// If decoding as a single user fails, try to decode as an array
					print("Failed to decode response as a single user, trying as an array: \(error.localizedDescription)")
					
					do {
						let parameters: [String: String]
						if isGoogleAuth {
							parameters = ["idToken": authIdentifier, "email": emailToUse, "provider": "google"]
						} else if isAppleAuth {
							parameters = ["idToken": authIdentifier, "email": emailToUse, "provider": "apple"] 
						} else {
							parameters = ["externalUserId": authIdentifier, "email": emailToUse]
						}
							
						let fetchedUsers: [BaseUserDTO] = try await self.apiService
							.fetchData(
								from: url,
								parameters: parameters
							)
						
						// Use the first user if array is not empty
						if let firstUser = fetchedUsers.first {
							await MainActor.run {
								self.spawnUser = firstUser
								self.shouldNavigateToUserInfoInputView = false
								self.isFormValid = true
								self.setShouldNavigateToFeedView()
								
								// Post notification that user did login successfully
								NotificationCenter.default.post(name: .userDidLogin, object: nil)
							}
						} else {
							// Handle empty array - user doesn't exist
							await MainActor.run {
								self.spawnUser = nil
								self.shouldNavigateToUserInfoInputView = true
								print("No users found in array response")
							}
						}
					} catch let arrayError as APIError {
						// Handle API errors, like 404
						await MainActor.run {
							self.handleApiError(arrayError)
						}
					} catch {
						// Handle other errors
						await MainActor.run {
							self.spawnUser = nil
							self.shouldNavigateToUserInfoInputView = true
							print("Error fetching user data: \(error.localizedDescription)")
						}
					}
				} catch {
					await MainActor.run {
						self.spawnUser = nil
						self.shouldNavigateToUserInfoInputView = true
						print("Error fetching user data: \(error.localizedDescription)")
					}
				}
			
			await MainActor.run {
				self.hasCheckedSpawnUserExistence = true
			}
		}
	}
	
	// Helper method to handle API errors consistently
	private func handleApiError(_ error: APIError) {
		// For 404 errors (user doesn't exist), just direct to user info input without showing an error
		if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
			self.spawnUser = nil
			self.shouldNavigateToUserInfoInputView = true
			print("User does not exist yet in Spawn database - directing to user info input")
		} else {
			self.spawnUser = nil
			self.shouldNavigateToUserInfoInputView = true
			self.errorMessage = "Failed to fetch user: \(error.localizedDescription)"
			print(self.errorMessage as Any)
		}
	}

	func spawnMakeUser(
		username: String,
		profilePicture: UIImage?,
		name: String,
		email: String
	) async {
		// Reset any previous navigation flags to prevent automatic navigation
		await MainActor.run {
			self.shouldNavigateToFeedView = false
			self.isFormValid = false
		}
		
		// Create the DTO
		let userDTO = UserCreateDTO(
			username: username,
			name: name,
			email: email
		)

		// Prepare parameters
		var parameters: [String: String] = [:]
		// For Google and Apple, use ID token instead of external user ID
		if self.authProvider == .google, let unwrappedIdToken = googleIdToken {
			parameters["idToken"] = unwrappedIdToken
		} else if self.authProvider == .apple, let unwrappedIdToken = appleIdToken {
			parameters["idToken"] = unwrappedIdToken
		} else if let unwrappedExternalUserId = externalUserId {
			parameters["externalUserId"] = unwrappedExternalUserId
		}
		
		if let authProvider = self.authProvider {
			parameters["provider"] = authProvider.rawValue
		}
		
		// If we have a profile picture URL from the provider (Google/Apple) and no selected image,
		// include it in the parameters so it can be used
		if profilePicture == nil, let profilePicUrl = self.profilePicUrl, !profilePicUrl.isEmpty {
			parameters["profilePicUrl"] = profilePicUrl
			print("Including provider picture URL in parameters: \(profilePicUrl)")
		}

		do {
			// Use the new createUser method
			let fetchedUser: BaseUserDTO = try await (apiService as! APIService)
				.createUser(
					userDTO: userDTO,
					profilePicture: profilePicture,
					parameters: parameters
				)

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
			
			// Only set user and navigate after successful account creation
			await MainActor.run {
				self.spawnUser = fetchedUser
				self.shouldNavigateToUserInfoInputView = false
				// Don't automatically set navigation flags - leave that to the view
				
				// Post notification that user did login
				NotificationCenter.default.post(name: .userDidLogin, object: nil)
			}

		} catch let error as APIError {
			await MainActor.run {
				if case .invalidStatusCode(let statusCode) = error, statusCode == 409 {
					// Check if the error is due to email or username conflict
					// MySQL error 1062 for duplicate key involves username
					if let errorMessage = self.errorMessage, errorMessage.contains("username") || errorMessage.contains("Duplicate") {
						print("Username is already taken: \(username)")
						self.authAlert = .usernameAlreadyInUse
					} else {
						// Default to email conflict if we can't determine the exact cause
						print("Email is already in use: \(email)")
						self.authAlert = .emailAlreadyInUse
					}
				} else {
					print("Error creating the user: \(error)")
					self.authAlert = .createError
				}
			}
		} catch {
			await MainActor.run {
				print("Error creating the user: \(error)")
				self.authAlert = .createError
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
                await NotificationService.shared.unregisterDeviceToken()

                try await self.apiService.deleteData(from: url, parameters: nil, object: EmptyObject())
				var success = KeychainService.shared.delete(
					key: "externalUserId")
				if !success {
					print("Failed to delete externalUserId from Keychain")
				}
                success = KeychainService.shared.delete(key: "accessToken")
                if !success {
                    print("Failed to delete accessToken from Keychain")
                }
                success = KeychainService.shared.delete(key: "refreshToken")
                if !success {
                    print("Failed to delete refreshToken from Keychain")
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

	func spawnFetchDefaultProfilePic() async {
		if let url = URL(string: APIService.baseURL + "users/default-pfp") {
			do {
				let fetchedDefaultPfpUrlString: String = try await self.apiService
					.fetchData(
						from: url,
						parameters: nil
					)

				await MainActor.run {
					self.defaultPfpUrlString = fetchedDefaultPfpUrlString
				}
			} catch {
				await MainActor.run {
					self.defaultPfpFetchError = true
				}
			}
		}
	}

	func updateProfilePicture(_ image: UIImage) async {
		guard let userId = spawnUser?.id else {
			print("Cannot update profile picture: No user ID found")
			return
		}
		
		// Convert image to data with higher quality
		guard let imageData = image.jpegData(compressionQuality: 0.95) else {
			print("Failed to convert image to JPEG data")
			return
		}
		
		if let user = spawnUser {
			print("Starting profile picture update for user \(userId) (username: \(user.username), name: \(user.name ?? "")) with image data size: \(imageData.count) bytes")
		} else {
			print("Starting profile picture update for user \(userId) with image data size: \(imageData.count) bytes")
		}
		
		// Use our new dedicated method for profile picture updates
		do {
			// Try to use the new method which has better error handling
			if let apiService = apiService as? APIService {
				let updatedUser = try await apiService.updateProfilePicture(imageData, userId: userId)
				
				await MainActor.run {
					self.spawnUser = updatedUser
					// Force a UI update
					self.objectWillChange.send()
					print("Profile successfully updated with new picture: \(updatedUser.profilePicture ?? "nil")")
				}
				return
			}
			
			// Fallback to the old method if needed (only for mock implementation)
			if let url = URL(string: APIService.baseURL + "users/update-pfp/\(userId)") {
				// Create a URLRequest with PATCH method
				var request = URLRequest(url: url)
				request.httpMethod = "PATCH"
				request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
				request.httpBody = imageData
				
				print("Fallback: Sending profile picture update request to: \(url)")
				
				// Perform the request
				let (data, response) = try await URLSession.shared.data(for: request)
				
				// Check the HTTP response
				guard let httpResponse = response as? HTTPURLResponse, 
					  (200...299).contains(httpResponse.statusCode) else {
					let httpResponse = response as? HTTPURLResponse
					print("Error updating profile picture: Invalid HTTP response code: \(httpResponse?.statusCode ?? 0)")
					return
				}
				
				// Decode the response
				let decoder = JSONDecoder()
				if let updatedUser = try? decoder.decode(BaseUserDTO.self, from: data) {
					await MainActor.run {
						self.spawnUser = updatedUser
						self.objectWillChange.send()
						print("Fallback: Profile picture updated successfully with URL: \(updatedUser.profilePicture ?? "nil")")
					}
				} else {
					print("Failed to decode user data after profile picture update")
				}
			}
		} catch {
			print("Error updating profile picture: \(error.localizedDescription)")
		}
	}

	func spawnEditProfile(username: String, name: String) async {
		guard let userId = spawnUser?.id else {
			print("Cannot edit profile: No user ID found")
			return
		}
		
		// Log user details
		if let user = spawnUser {
			print("Editing profile for user \(userId) (username: \(user.username), name: \(user.name ?? ""))")
		}

		if let url = URL(string: APIService.baseURL + "users/update/\(userId)") {
			do {
				let updateDTO = UserUpdateDTO(
					username: username,
					name: name
				)

				print("Updating profile with: username=\(username), name=\(name)")
				
				let updatedUser: BaseUserDTO = try await self.apiService.patchData(
					from: url,
					with: updateDTO
				)

				await MainActor.run {
					// Update the current user object
					self.spawnUser = updatedUser
					
					// Ensure UI updates with the latest values
					self.objectWillChange.send()
					
					print("Profile updated successfully: \(updatedUser.username)")
				}
			} catch {
				print("Error updating profile: \(error.localizedDescription)")
			}
		}
	}

	// Add a method to fetch the latest user data from the backend
	func fetchUserData() async {
		guard let userId = spawnUser?.id else {
			print("Cannot fetch user data: No user ID found")
			return
		}
		
		if let url = URL(string: APIService.baseURL + "users/\(userId)") {
			do {
				let updatedUser: BaseUserDTO = try await self.apiService.fetchData(
					from: url,
					parameters: nil
				)
				
				await MainActor.run {
					// Update the current user object with fresh data
					self.spawnUser = updatedUser
					
					// Force UI to update
					self.objectWillChange.send()
					
					print("User data refreshed: \(updatedUser.username), \(updatedUser.name ?? "")")
				}
			} catch {
				print("Error fetching user data: \(error.localizedDescription)")
			}
		}
	}

	func changePassword(currentPassword: String, newPassword: String) async throws {
		guard let userId = spawnUser?.id else {
			throw NSError(domain: "UserAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "User ID not found"])
		}
		
		if let url = URL(string: APIService.baseURL + "auth/change-password") {
			let changePasswordDTO = ChangePasswordDTO(
				userId: userId.uuidString,
				currentPassword: currentPassword,
				newPassword: newPassword
			)
			
			do {
                let result: Bool = ((try await self.apiService.sendData(changePasswordDTO,
                                                                        to: url,
                                                                        parameters: nil
                                                                       )) != nil)
				
				if !result {
					throw NSError(domain: "UserAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Password change failed"])
				}
				
				print("Password changed successfully for user \(userId)")
			} catch {
				print("Error changing password: \(error.localizedDescription)")
				throw error
			}
		} else {
			throw NSError(domain: "UserAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
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

// Add ChangePasswordDTO struct
struct ChangePasswordDTO: Codable {
	let userId: String
	let currentPassword: String
	let newPassword: String
}

