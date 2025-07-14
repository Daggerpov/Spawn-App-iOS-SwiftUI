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
	@Published var idToken: String?  // ID token for authentication
	@Published var isLoggedIn: Bool = false
	@Published var hasCheckedSpawnUserExistence: Bool = false
	@Published var spawnUser: BaseUserDTO? {
		didSet {
			if spawnUser != nil {
				// Only set navigation to feed view if user has completed onboarding
				// For new users going through onboarding, this will be handled separately
				if hasCompletedOnboarding {
					shouldNavigateToFeedView = true
				}
				isLoggedIn = true
			}
		}
	}
	
	// Minimum loading time for animation
	private var minimumLoadingCompleted: Bool = false
	private var authCheckCompleted: Bool = false
	
	// Track whether this is the first launch or a logout
	@Published var isFirstLaunch: Bool = true
	
	// Track onboarding completion
	@Published var hasCompletedOnboarding: Bool = false {
		didSet {
			print("🔄 DEBUG: hasCompletedOnboarding changed to: \(hasCompletedOnboarding)")
		}
	}

	@Published var name: String?
	@Published var email: String?
	@Published var profilePicUrl: String?

	@Published var isFormValid: Bool = false
    
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
    
    @Published var shouldNavigateToPhoneNumberView: Bool = false
    @Published var shouldNavigateToVerificationCodeView: Bool = false
    @Published var shouldNavigateToUserDetailsView: Bool = false
    @Published var secondsUntilNextVerificationAttempt: Int = 30
    
    @Published var shouldNavigateToUserOptionalDetailsInputView: Bool = false
    
    @Published var shouldNavigateToUserToS: Bool = false
    
    private var isOnboarding: Bool = false
    
    @Published var shouldSkipAhead: Bool = false
    @Published var skipDestination: SkipDestination = .none

	private init(apiService: IAPIService) {
		print("🔄 DEBUG: UserAuthViewModel.init() called")
        self.spawnUser = nil
		self.apiService = apiService

		super.init()  // Call super.init() before using `self`
		
		// Determine if this is truly a first launch
		let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
		if !hasLaunchedBefore {
			// This is a genuine first launch
			self.isFirstLaunch = true
			UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
			print("🔄 DEBUG: First launch detected, marking hasLaunchedBefore as true")
		} else {
			// This is an app restart or upgrade
			self.isFirstLaunch = false
			print("🔄 DEBUG: App has launched before, setting isFirstLaunch to false")
		}
		
		// Load onboarding completion status from UserDefaults
		self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
		print("🔄 DEBUG: Loaded hasCompletedOnboarding from UserDefaults: \(self.hasCompletedOnboarding)")

        // Start minimum loading timer
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                print("🔄 DEBUG: Minimum loading timer completed")
                self.minimumLoadingCompleted = true
                self.checkLoadingCompletion()
            }
        }
        
        // Attempt quick login
        Task {
            print("🔄 DEBUG: Starting quick login attempt")
            if MockAPIService.isMocking {
                await setMockUser()
            } else {
                await quickSignIn()
            }
            await MainActor.run {
                print("🔄 DEBUG: Quick login attempt completed, setting authCheckCompleted = true")
                self.authCheckCompleted = true
                self.checkLoadingCompletion()
            }
        }
	}

	// Helper method to check if both auth and minimum loading time are completed
	private func checkLoadingCompletion() {
		print("🔄 DEBUG: checkLoadingCompletion called - minimumLoadingCompleted: \(minimumLoadingCompleted), authCheckCompleted: \(authCheckCompleted)")
		if minimumLoadingCompleted && authCheckCompleted {
			hasCheckedSpawnUserExistence = true
			print("🔄 DEBUG: Setting hasCheckedSpawnUserExistence to true")
		}
	}
	
	func resetState() {
		Task { @MainActor in
			// Reset user state
			self.errorMessage = nil
			self.authProvider = nil
			self.externalUserId = nil
			self.idToken = nil
			self.isLoggedIn = false
			self.spawnUser = nil

			self.name = nil
			self.email = nil
			self.profilePicUrl = nil

			self.isFormValid = false

			self.shouldNavigateToFeedView = false
			self.shouldNavigateToUserInfoInputView = false
			self.shouldNavigateToPhoneNumberView = false
			self.shouldNavigateToVerificationCodeView = false
			        self.shouldNavigateToUserDetailsView = false
        self.secondsUntilNextVerificationAttempt = 30
			self.activeAlert = nil
			self.authAlert = nil

			self.defaultPfpFetchError = false
			self.defaultPfpUrlString = nil
			
			// Reset loading state but mark as not first launch
			self.minimumLoadingCompleted = false
			self.authCheckCompleted = false
			self.hasCheckedSpawnUserExistence = false
			self.isFirstLaunch = false // This is no longer first launch
			
			// Reset onboarding state on logout so user can see onboarding again
			self.hasCompletedOnboarding = false
			UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
			
			// Don't reset hasLaunchedBefore - app has already launched before
			// This prevents the loading screen from showing again unnecessarily
		}
	}
	
	// Mark onboarding as completed
	func markOnboardingCompleted() {
		Task { @MainActor in
			hasCompletedOnboarding = true
			UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
		}
	}
	
	// Reset onboarding state for testing/debugging purposes
	func resetOnboardingState() {
		Task { @MainActor in
			hasCompletedOnboarding = false
			UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
		}
	}
	
	// Reset launch state for testing/debugging purposes
	func resetLaunchState() {
		Task { @MainActor in
			isFirstLaunch = true
			UserDefaults.standard.set(false, forKey: "hasLaunchedBefore")
			print("🔄 DEBUG: Reset launch state - will show loading screen on next restart")
		}
	}

	func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
		switch result {
		case .success(let authorization):
			if let appleIDCredential = authorization.credential
				as? ASAuthorizationAppleIDCredential
			{
                if isOnboarding {
                    Task {
                        if let idToken = appleIDCredential.identityToken {
                            let idTokenString: String? = String(data: idToken, encoding: .utf8)
                            await self.registerWithOAuth(
                                idToken: idTokenString ?? "",
                                provider: .apple,
                                email: appleIDCredential.email,
                                name: appleIDCredential.fullName?.givenName != nil ? "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")" : nil,
                                profilePictureUrl: nil
                            )
                        }
                    }
                    return
                }
                
				// Set user details
                let userIdentifier = appleIDCredential.user
                Task { @MainActor in
                    if let email = appleIDCredential.email {
                        self.email = email
                    }
                    if let givenName = appleIDCredential.fullName?.givenName,
                       let familyName = appleIDCredential.fullName?.familyName {
                        self.name = "\(givenName) \(familyName)"
                    } else if let givenName = appleIDCredential.fullName?.givenName {
                        self.name = givenName
                    }
                    self.isLoggedIn = true
                    self.externalUserId = userIdentifier
                    guard let idTokenData = appleIDCredential.identityToken else {
                        print("Error fetching ID Token from Apple ID Credential")
                        return
                    }
                    self.idToken = String(data: idTokenData, encoding: .utf8)
                    self.authProvider = .apple
                    
                    // Check user existence AFTER setting credentials
                    await self.spawnFetchUserIfAlreadyExists()
                }
			}
		case .failure(let error):
			Task { @MainActor in
				self.errorMessage =
					"Apple Sign-In failed: \(error.localizedDescription)"
				print(self.errorMessage as Any)
			}
		}
	}
    
    func loginWithGoogle() async {
        self.isOnboarding = false
        await signInWithGoogle()
    }

	private func signInWithGoogle() async {
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
				
				// Get ID token
                signInResult.user.refreshTokensIfNeeded { [weak self] user, error in
					guard let self = self else { return }
					guard error == nil else { 
						print("Error refreshing token: \(error?.localizedDescription ?? "Unknown error")")
						return 
					}
					guard let user = user else { return }
                    
                    if isOnboarding {
                        Task {
                            await self.registerWithOAuth(
                                idToken: user.idToken?.tokenString ?? "",
                                provider: .google,
                                email: user.profile?.email,
                                name: user.profile?.name,
                                profilePictureUrl: user.profile?.imageURL(withDimension: 400)?.absoluteString
                            )
                        }
                        return
                    }
                    
                    // Request a higher resolution image (400px instead of 100px)
                    Task { @MainActor in
                        self.profilePicUrl = user.profile?.imageURL(withDimension: 400)?.absoluteString ?? ""
                        self.name = user.profile?.name
                        self.email = user.profile?.email
                        self.isLoggedIn = true
                        self.externalUserId = user.userID
                        self.authProvider = .google
                        self.idToken = user.idToken?.tokenString
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
        self.isOnboarding = false
        
		let appleIDProvider = ASAuthorizationAppleIDProvider()
		let request = appleIDProvider.createRequest()
		request.requestedScopes = [.fullName, .email]

		let authorizationController = ASAuthorizationController(
			authorizationRequests: [request]
		)
		authorizationController.delegate = self  // Ensure delegate is set
		authorizationController.performRequests()

		Task { @MainActor in
			self.authProvider = .apple
		}
	}

	func signOut() {
		// Sign out of Google
		GIDSignIn.sharedInstance.signOut()

		// Clear Apple Sign-In state
		if let externalUserId = self.externalUserId, authProvider == .apple {
			// Invalidate Apple ID credential state (optional but recommended)
			let appleIDProvider = ASAuthorizationAppleIDProvider()
			appleIDProvider.getCredentialState(forUserID: externalUserId) {
				credentialState, error in
				if let error = error {
					print("ℹ️ Apple ID credential state check failed: \(error.localizedDescription)")
					// This is not critical for sign-out, so we don't need to handle it
					return
				}
				switch credentialState {
				case .authorized:
					print("ℹ️ User is still authorized with Apple ID.")
				case .revoked:
					print("ℹ️ User has revoked Apple ID access.")
				case .notFound:
					print("ℹ️ User not found in Apple ID system.")
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

		// Clear Keychain
		let accessTokenDeleted = KeychainService.shared.delete(key: "accessToken")
		let refreshTokenDeleted = KeychainService.shared.delete(key: "refreshToken")
		
		if accessTokenDeleted && refreshTokenDeleted {
			print("✅ Successfully cleared auth tokens from Keychain")
		} else {
			print("ℹ️ Some tokens were not found in Keychain (this is normal if user wasn't fully authenticated)")
		}

		resetState()
	}

    func spawnFetchUserIfAlreadyExists() async {
		
        guard let unwrappedIdToken = self.idToken else {
            await MainActor.run {
                self.errorMessage = "ID Token is missing."
                print(self.errorMessage as Any)
            }
            return
        }
        
        guard let unwrappedProvider = self.authProvider else {
            await MainActor.run {
                print("Auth provider is missing.")
            }
            return
        }
		
		// Only proceed with API call if we have email or it's not Apple auth
		let emailToUse = self.email ?? ""
		
		if let url = URL(string: APIService.baseURL + "auth/sign-in") {
				// First, try to decode as a single user object
				do {
                    let parameters: [String: String] = ["idToken": unwrappedIdToken, "email": emailToUse, "provider": unwrappedProvider.rawValue]
						
					let authResponse: AuthResponseDTO = try await self.apiService
						.fetchData(
							from: url,
							parameters: parameters
						)
						
					await MainActor.run {
						self.spawnUser = authResponse.user
                        self.isLoggedIn = true
						
						// Navigate based on user status from AuthResponseDTO
						self.navigateBasedOnUserStatus(authResponse: authResponse)
                        
						// Post notification that user did login successfully
						NotificationCenter.default.post(name: .userDidLogin, object: nil)
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
		// For Google, use ID token instead of external user ID
		if let unwrappedIdToken = idToken {
			parameters["idToken"] = unwrappedIdToken
        } else {
            print("Error: Missing Id Token")
            return
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
			let fetchedUser: BaseUserDTO = try await apiService
				.createUser(
					userDTO: userDTO,
					profilePicture: profilePicture,
					parameters: parameters
				)

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
				self.handleAccountCreationError(error)
			}
		} catch {
			await MainActor.run {
				print("Error creating the user: \(error)")
				self.authAlert = .unknownError(error.localizedDescription)
			}
		}
	}

	func setShouldNavigateToFeedView() {
		Task { @MainActor in
			shouldNavigateToFeedView = isLoggedIn && spawnUser != nil && isFormValid
		}
	}
	
	private func navigateBasedOnUserStatus(authResponse: AuthResponseDTO) {
		// Reset all navigation flags
		shouldNavigateToUserInfoInputView = false
		shouldNavigateToUserDetailsView = false
		shouldNavigateToUserToS = false
		shouldNavigateToFeedView = false
		isFormValid = false
		
		guard let status = authResponse.status else {
			// No status means legacy active user
            print("Error: User has no status")
			return
		}
		
		switch status {
		case .emailVerified:
			// Needs to input username, phone number, and password
			shouldNavigateToUserDetailsView = true
			print("📍 User status: emailVerified - navigating to user details input")
		case .usernameAndPhoneNumber:
			// Only needs to accept Terms of Service
			shouldNavigateToUserOptionalDetailsInputView = true
			print("📍 User status: usernameAndPhoneNumber - navigating to Terms of Service")
        case .nameAndPhoto:
            shouldNavigateToUserToS = true
		case .active:
			// Fully onboarded user - go to feed
			isFormValid = true
            isLoggedIn = true
			setShouldNavigateToFeedView()
			print("📍 User status: active - navigating to feed")
		}
	}
    
    private func determineSkipDestination(authResponse: AuthResponseDTO) {
        print("Determining skip destination")
        guard let status = authResponse.status else {
            // No status means legacy active user
            print("Error: User has no status")
            return
        }
        
        if status != .active {
            shouldSkipAhead = true
        }
        
        switch status {
        case .emailVerified:
            // Needs to input username, phone number, and password
            shouldNavigateToUserDetailsView = true
            skipDestination = .userDetailsInput
            print("📍 User status: emailVerified - navigating to user details input")
            
        case .usernameAndPhoneNumber:
            // Only needs to accept Terms of Service
            shouldNavigateToUserOptionalDetailsInputView = true
            skipDestination = .userOptionalDetailsInput
            print("📍 User status: usernameAndPhoneNumber - navigating to Terms of Service")
        
        case .nameAndPhoto:
            shouldNavigateToUserToS = true
            skipDestination = .userToS
        case .active:
            // Fully onboarded user - go to feed
            shouldSkipAhead = true
            isFormValid = true
            isLoggedIn = true
            setShouldNavigateToFeedView()
			// Mark onboarding as completed for active users
			if !hasCompletedOnboarding {
				markOnboardingCompleted()
			}
            print("📍 User status: active - navigating to feed")
        }
    }
    
    
    func acceptTermsOfService() async {
        guard let userId = spawnUser?.id else {
            print("Error: No user ID available for TOS acceptance")
            return
        }
        
        guard let url = URL(string: APIService.baseURL + "auth/accept-tos/\(userId)") else {
            print("Error: Failed to create URL for TOS acceptance")
            return
        }
        
        do {
            let updatedUser: BaseUserDTO? = try await apiService.sendData(EmptyBody(), to: url, parameters: nil)
            
            guard let updatedUser = updatedUser else {
                await MainActor.run {
                    print("Error: No user data returned from TOS acceptance")
                    self.errorMessage = "Failed to accept Terms of Service. Please try again."
                }
                return
            }
            
            await MainActor.run {
                self.spawnUser = updatedUser
                self.shouldNavigateToFeedView = true
                self.isLoggedIn = true
                // Mark onboarding as completed when user accepts Terms of Service
                self.markOnboardingCompleted()
                print("Successfully accepted Terms of Service for user: \(updatedUser.username)")
                print("🔄 DEBUG: Onboarding completed after accepting Terms of Service")
            }
        } catch {
            await MainActor.run {
                print("Error accepting Terms of Service: \(error)")
                self.errorMessage = "Failed to accept Terms of Service. Please try again."
            }
        }
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
                // Try to unregister device token, but don't let it fail the account deletion
                do {
                    await NotificationService.shared.unregisterDeviceToken()
                } catch {
                    print("Failed to unregister device token during account deletion (continuing with deletion): \(error.localizedDescription)")
                }

                try await self.apiService.deleteData(from: url, parameters: nil, object: EmptyBody())
				
                // Clear tokens after successful account deletion
                var success = KeychainService.shared.delete(key: "accessToken")
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
				
				// Check if this is an authentication error (missing/invalid refresh token)
				if let apiError = error as? APIError {
					switch apiError {
					case .failedTokenSaving(tokenType: "refreshToken"):
						// Authentication failed due to missing refresh token
						// Clear local data and log user out
						print("Account deletion failed due to missing refresh token - clearing local data")
						await clearLocalDataAndLogout()
						await MainActor.run {
							activeAlert = .deleteSuccess
						}
						return
					case .invalidStatusCode(statusCode: 401):
						// Authentication failed due to invalid/expired token
						// Clear local data and log user out
						print("Account deletion failed due to authentication error (401) - clearing local data")
						await clearLocalDataAndLogout()
						await MainActor.run {
							activeAlert = .deleteSuccess
						}
						return
					default:
						break
					}
				}
				
				await MainActor.run {
					activeAlert = .deleteError
				}
			}
		}
	}
	
	private func clearLocalDataAndLogout() async {
		// Clear tokens
		var success = KeychainService.shared.delete(key: "accessToken")
		if !success {
			print("Failed to delete accessToken from Keychain")
		}
		success = KeychainService.shared.delete(key: "refreshToken")
		if !success {
			print("Failed to delete refreshToken from Keychain")
		}
		
		// Clear user data
		await MainActor.run {
			self.spawnUser = nil
			self.isLoggedIn = false
			self.hasCompletedOnboarding = false
			
			// Clear any cached data
			AppCache.shared.clearAllCaches()
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
					// Invalidate the cached profile picture since we have a new one
					ProfilePictureCache.shared.removeCachedImage(for: userId)
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
					// Invalidate the cached profile picture since we have a new one
					ProfilePictureCache.shared.removeCachedImage(for: userId)
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
    
    // Attempts a "quick" sign-in which sends access/refresh tokens to server to verify whether a user is logged in
    func quickSignIn() async {
        print("🔄 DEBUG: quickSignIn() called - attempting quick sign-in")
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/quick-sign-in") {
                let authResponse: AuthResponseDTO = try await self.apiService.fetchData(from: url, parameters: nil)
                
                print("🔄 DEBUG: quickSignIn() - Quick sign-in successful")
                await MainActor.run {
                    self.spawnUser = authResponse.user
                    // For existing users with quick sign-in, mark onboarding as completed
                    if !self.hasCompletedOnboarding {
                        self.markOnboardingCompleted()
                    }
                    self.determineSkipDestination(authResponse: authResponse)
                    // Don't set hasCheckedSpawnUserExistence directly - let checkLoadingCompletion() handle it
                    // This ensures the minimum loading time is respected
                }
            }
        } catch {
            print("🔄 DEBUG: quickSignIn() - Error performing quick-login. Re-login is required")
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
                self.shouldNavigateToFeedView = false
                self.shouldNavigateToUserInfoInputView = false
                // Don't set hasCheckedSpawnUserExistence directly - let checkLoadingCompletion() handle it
                // This ensures the minimum loading time is respected
            }
        }
    }
    
    // The username argument could be an email as well
    func signInWithEmailOrUsername(usernameOrEmail: String, password: String) async {
        print("Attempting email/username sign-in")
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/login") {
                let response: BaseUserDTO? = try await self.apiService.sendData(LoginDTO(usernameOrEmail: usernameOrEmail, password: password), to: url, parameters: nil)
                
                guard let user: BaseUserDTO = response else {
                    print("Failed to login with email/username")
                    return
                }
                print("Email/username login successful")
                await MainActor.run {
                    self.spawnUser = user
                    // For existing users with email/username sign-in, mark onboarding as completed
                    if !self.hasCompletedOnboarding {
                        self.markOnboardingCompleted()
                    }
                    self.shouldNavigateToFeedView = true
                    self.isLoggedIn = true
                }
            }
        } catch {
            print("Failed to login with email/username")
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
                self.shouldNavigateToFeedView = false
                self.shouldNavigateToUserInfoInputView = false
                self.errorMessage = "Incorrect email/username or password"
            }
        }
    }

    @MainActor
    func setMockUser() async {
        // Set mock user details
        self.name = "Daniel Agapov"
        self.email = "daniel.agapov@gmail.com"
        self.isLoggedIn = true
        self.externalUserId = "mock_user_id"
        self.authProvider = .google
        self.idToken = "mock_id_token"
        
        // Set the mock user directly
        self.spawnUser = BaseUserDTO.danielAgapov
        self.hasCheckedSpawnUserExistence = true
        
        // For mock users, mark onboarding as completed
        if !self.hasCompletedOnboarding {
            self.markOnboardingCompleted()
        }
    }
    
    func googleRegister() async {
        self.isOnboarding = true
        await signInWithGoogle()
    }
    
    func appleRegister() {
        self.isOnboarding = true
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(
            authorizationRequests: [request]
        )
        authorizationController.delegate = self  // Ensure delegate is set
        authorizationController.performRequests()
    }
    
    
    func register(email: String?, idToken: String?, provider: AuthProviderType?) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/registration") {
                let registration: RegistrationDTO = RegistrationDTO(email: email, idToken: idToken, provider: provider?.rawValue)
                let response: BaseUserDTO? = try await self.apiService.sendData(registration, to: url, parameters: nil)
                guard let user: BaseUserDTO = response else {
                    print("Failed to register account")
                    return
                }
                
                await MainActor.run {
                    self.shouldNavigateToPhoneNumberView = true
                    self.spawnUser = user
                    self.email = user.email
                }
            }
            
        } catch {
            print("Error registering user")
            self.shouldNavigateToPhoneNumberView = false
        }
    }
    
    
    // New method for sending email verification
    func sendEmailVerification(email: String) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/register/verification/send") {
                let emailVerificationDTO = EmailVerificationSendDTO(email: email)
                let response: EmailVerificationResponseDTO? = try await self.apiService.sendData(emailVerificationDTO, to: url, parameters: nil)
                
                await MainActor.run {
                    if let response = response {
                        // Success - navigate to verification code view
                        self.shouldNavigateToVerificationCodeView = true
                        self.email = email
                        // Store the seconds until next attempt for the timer
                        self.secondsUntilNextVerificationAttempt = response.secondsUntilNextAttempt
                        self.errorMessage = nil
                    } else {
                        // Handle error
                        self.errorMessage = "Failed to send verification email"
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                // Handle specific API errors
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Invalid email address"
                    case 409:
                        self.errorMessage = "Email already registered"
                    default:
                        self.errorMessage = "Failed to send verification email"
                    }
                } else {
                    self.errorMessage = "Failed to send verification email"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to send verification email"
            }
        }
    }
    
    // New method for OAuth registration
    func registerWithOAuth(idToken: String, provider: AuthProviderType, email: String?, name: String?, profilePictureUrl: String?) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/register/oauth") {
                let oauthRegistrationDTO = OAuthRegistrationDTO(
                    idToken: idToken,
                    provider: provider.rawValue,
                    email: email,
                    name: name,
                    profilePictureUrl: profilePictureUrl
                )
                
            let response: AuthResponseDTO? = try await self.apiService.sendData(oauthRegistrationDTO, to: url, parameters: nil)
            
            await MainActor.run {
                if let authResponse = response {
                    // Success - use status-based navigation for OAuth users
                    self.spawnUser = authResponse.user
					self.navigateBasedOnUserStatus(authResponse: authResponse)
                    self.email = authResponse.user.email
                    self.errorMessage = nil
                } else {
                    // Handle error
                    self.errorMessage = "Failed to register with OAuth"
                }
            }
            }
        } catch let error as APIError {
            await MainActor.run {
                // Handle specific API errors
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Invalid OAuth credentials"
                    case 409:
                        self.errorMessage = "Account already exists"
                    default:
                        self.errorMessage = "Failed to register with OAuth"
                    }
                } else {
                    self.errorMessage = "Failed to register with OAuth"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to register with OAuth"
            }
        }
    }
    
    // New method for verifying email verification code
    func verifyEmailCode(email: String, code: String) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/register/verification/check") {
                let verificationDTO = EmailVerificationVerifyDTO(email: email, verificationCode: code)
                let response: BaseUserDTO? = try await self.apiService.sendData(verificationDTO, to: url, parameters: nil)
                
                await MainActor.run {
                    if let user = response {
                        // Success - navigate to user details view
                        self.spawnUser = user
                        self.shouldNavigateToUserDetailsView = true
                        self.email = user.email
                        self.errorMessage = nil
                    } else {
                        // Handle error
                        self.errorMessage = "Invalid verification code"
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                // Handle specific API errors
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Invalid verification code"
                    case 404:
                        self.errorMessage = "Verification code not found"
                    default:
                        self.errorMessage = "Failed to verify code"
                    }
                } else {
                    self.errorMessage = "Failed to verify code"
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to verify code"
            }
        }
    }
    
    // Update user details after registration
    func updateUserDetails(id: String, username: String, phoneNumber: String, password: String?) async {
        do {
            let dto = UpdateUserDetailsDTO(id: id, username: username, phoneNumber: phoneNumber, password: password)
            if let url = URL(string: APIService.baseURL + "auth/user/details") {
                let response: BaseUserDTO? = try await self.apiService.sendData(dto, to: url, parameters: nil)
                await MainActor.run {
                    if let user = response {
                        self.spawnUser = user
                        self.shouldNavigateToUserOptionalDetailsInputView = true
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Failed to update user details."
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .failedHTTPRequest(let description):
                    self.errorMessage = description
                case .invalidStatusCode(let statusCode):
                    self.errorMessage = "Server error (\(statusCode))."
                default:
                    self.errorMessage = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update user details."
            }
        }
    }
    
    // Update optional user details (name and profile picture)
    func updateOptionalDetails(id: String, name: String, profileImage: UIImage?) async {
        do {
            // Convert UIImage to Data if provided
            var imageData: Data? = nil
            if let image = profileImage {
                imageData = image.jpegData(compressionQuality: 0.8)
            }
            
            let dto = OptionalDetailsDTO(name: name, profilePictureData: imageData)
            if let url = URL(string: APIService.baseURL + "users/\(id)/optional-details") {
                let response: BaseUserDTO? = try await self.apiService.sendData(dto, to: url, parameters: nil)
                await MainActor.run {
                    if let user = response {
                        self.spawnUser = user
                        self.shouldNavigateToUserToS = true
                        self.errorMessage = nil
                    } else {
                        self.errorMessage = "Failed to update optional details."
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .failedHTTPRequest(let description):
                    self.errorMessage = description
                case .invalidStatusCode(let statusCode):
                    self.errorMessage = "Server error (\(statusCode))."
                default:
                    self.errorMessage = error.localizedDescription
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to update optional details."
            }
        }
    }
    
	// MARK: - Error Handling Methods
	
	private func handleAccountCreationError(_ error: APIError) {
		if case .invalidStatusCode(let statusCode) = error {
			switch statusCode {
			case 409:
				// Conflict - field already exists
				self.authAlert = parseConflictError()
			case 400:
				// Bad request - typically email verification issues
				self.authAlert = parseEmailVerificationError()
			case 401:
				// Unauthorized - token issues
				self.authAlert = parseTokenError()
			case 503:
				// Service unavailable - OAuth provider issues
				self.authAlert = .providerUnavailable
			default:
				// Network or other errors
				if statusCode >= 500 {
					self.authAlert = .networkError
				} else {
					self.authAlert = .unknownError(apiService.errorMessage ?? "An error occurred during account creation")
				}
			}
		} else {
			// Handle other APIError types
			self.authAlert = .networkError
		}
	}
	
	private func parseConflictError() -> AuthAlertType {
		guard let errorMessage = apiService.errorMessage else {
			return .createError
		}
		
		let message = errorMessage.lowercased()
		if message.contains("username") || message.contains("duplicate") {
			return .usernameAlreadyInUse
		} else if message.contains("email") {
			return .emailAlreadyInUse
		} else if message.contains("phone") {
			return .phoneNumberAlreadyInUse
		} else if message.contains("provider") {
			return .providerMismatch
		} else {
			return .createError
		}
	}
	
	private func parseEmailVerificationError() -> AuthAlertType {
		guard let errorMessage = apiService.errorMessage else {
			return .createError
		}
		
		let message = errorMessage.lowercased()
		if message.contains("verification") || message.contains("code") {
			return .emailVerificationFailed
		} else {
			return .createError
		}
	}
	
	private func parseTokenError() -> AuthAlertType {
		guard let errorMessage = apiService.errorMessage else {
			return .invalidToken
		}
		
		let message = errorMessage.lowercased()
		if message.contains("expired") || message.contains("expire") {
			return .tokenExpired
		} else {
			return .invalidToken
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

