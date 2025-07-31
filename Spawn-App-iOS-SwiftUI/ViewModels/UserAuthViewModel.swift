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
	
	// Add separate OAuth credential storage for account completion
	private var storedOAuthProvider: AuthProviderType?
	private var storedIdToken: String?
	private var storedEmail: String?
	
	// Add flag to prevent multiple concurrent re-authentication attempts
	private var isReauthenticating: Bool = false
	
	@Published var spawnUser: BaseUserDTO? {
		didSet {
			if spawnUser != nil {
				// Only set navigation to feed view if user has completed onboarding
				// For new users going through onboarding, this will be handled separately
				if hasCompletedOnboarding {
					navigationState = .feedView
				}
				// Only set isLoggedIn for fully active users, not for users still in onboarding
				// The isLoggedIn flag will be set explicitly in navigation logic for active users
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
    
	// Replace all individual navigation flags with a single navigation state
	@Published var navigationState: NavigationState = .none
	
	@Published var isLoading: Bool = false

	private var apiService: IAPIService

	// delete account:

	@Published var activeAlert: DeleteAccountAlertType?

	// Auth alerts for authentication-related errors
	@Published var authAlert: AuthAlertType?

	// Track whether user is being automatically signed in after trying to register with existing account
	@Published var isAutoSigningIn: Bool = false
	
	// For handling terms of service acceptance
	@Published var defaultPfpFetchError: Bool = false
	@Published var defaultPfpUrlString: String? = nil
    
    @Published var secondsUntilNextVerificationAttempt: Int = 30
    
    private var isOnboarding: Bool = false
    
    // Add flag to prevent multiple concurrent navigation updates
    private var isNavigating: Bool = false
    
    // MARK: - Navigation Helper Methods
    
        /// Safely navigate to a new state with proper debouncing and protection
    func navigateTo(_ state: NavigationState, delay: TimeInterval = 0.1) {
        // Prevent multiple concurrent navigation attempts
        guard !isNavigating else {
            print("🚫 DEBUG: Navigation already in progress, ignoring navigateTo(\(state.description)) call")
            return
        }
        
        Task { @MainActor in
            self.isNavigating = true
            
            // Small delay to ensure UI state is settled
            if delay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            print("📍 Navigating to: \(state.description)")
            self.navigationState = state
            
            // Reset the navigation lock after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.isNavigating = false
            }
        }
    }

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
			print("🔄 DEBUG: Resetting authentication state")
			
			// Clear all cached data for current user before clearing user data
			if let currentUserId = self.spawnUser?.id {
				AppCache.shared.clearAllDataForUser(currentUserId)
			}

			// Clear tokens from Keychain
			let accessTokenDeleted = KeychainService.shared.delete(key: "accessToken")
			let refreshTokenDeleted = KeychainService.shared.delete(key: "refreshToken")

			if accessTokenDeleted && refreshTokenDeleted {
				print("✅ Successfully cleared auth tokens from Keychain")
			} else {
				print("ℹ️ Some tokens were not found in Keychain (this is normal if user wasn't fully authenticated)")
			}
			
			// Preserve OAuth credentials during onboarding logout
			let wasOnboarding = !self.hasCompletedOnboarding && self.spawnUser != nil
			if wasOnboarding {
				print("🔄 Preserving OAuth credentials during onboarding reset")
				self.storedOAuthProvider = self.authProvider
				self.storedIdToken = self.idToken
				self.storedEmail = self.email
			}

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

		self.navigationState = .none
			
			self.secondsUntilNextVerificationAttempt = 30
			self.activeAlert = nil
			
			self.defaultPfpFetchError = false
			self.defaultPfpUrlString = nil
			
			// Restore OAuth credentials if this was an onboarding reset
			if wasOnboarding {
				print("🔄 Restoring OAuth credentials after onboarding reset")
				self.authProvider = self.storedOAuthProvider
				self.idToken = self.storedIdToken
				self.email = self.storedEmail
			}
			
			// Reset loading state but mark as not first launch
			self.hasCheckedSpawnUserExistence = true
			self.isFirstLaunch = false // This is no longer first launch
			
			// Don't reset onboarding state on logout - users who have completed onboarding
			// should stay marked as having completed onboarding
		}
	}
	
	// Clear all error states - use this when navigating between auth screens
	func clearAllErrors() {
		Task { @MainActor in
			self.errorMessage = nil
			self.authAlert = nil
			self.isAutoSigningIn = false
		}
	}
	
	// Reset authentication flow state when navigating back during onboarding
	func resetAuthFlow() {
		Task { @MainActor in
			print("🔄 DEBUG: Resetting auth flow state for back navigation")
			
			// Log current state for debugging
			if let user = self.spawnUser {
				print("🔄 DEBUG: Clearing incomplete user state - ID: \(user.id), Email: \(user.email ?? "nil")")
			}
			
			// Clear all error states first
			self.errorMessage = nil
			self.authAlert = nil
			self.isAutoSigningIn = false
			
			// Reset user authentication data
			self.authProvider = nil
			self.externalUserId = nil
			self.idToken = nil
			self.isLoggedIn = false
			self.spawnUser = nil
			
			self.name = nil
			self.email = nil
			self.profilePicUrl = nil
			
			self.isFormValid = false
			
					// Reset all navigation flags
		self.navigationState = .none
			
			self.secondsUntilNextVerificationAttempt = 30
			self.activeAlert = nil
			
			self.defaultPfpFetchError = false
			self.defaultPfpUrlString = nil
			
			// Reset navigation lock
			self.isNavigating = false
			
			// Keep hasCheckedSpawnUserExistence true to avoid showing loading screen again
			// Keep isFirstLaunch and hasCompletedOnboarding as they were
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
        // Clear any stale tokens before OAuth attempt to prevent interference
        await clearStaleTokensIfNeeded()
        
        self.isOnboarding = false
        await signInWithGoogle()
    }
    
    // Clear stale tokens that might interfere with OAuth authentication
    private func clearStaleTokensIfNeeded() async {
        // Only clear tokens if we're not in an active session
        guard !isLoggedIn || spawnUser == nil else {
            return
        }
        
        // Check if we have cached tokens
        let hasAccessToken = KeychainService.shared.load(key: "accessToken") != nil
        let hasRefreshToken = KeychainService.shared.load(key: "refreshToken") != nil
        
        if hasAccessToken || hasRefreshToken {
            print("🔄 DEBUG: Clearing potentially stale cached tokens before OAuth attempt")
            
            // Clear the tokens from keychain
            let accessTokenDeleted = KeychainService.shared.delete(key: "accessToken")
            let refreshTokenDeleted = KeychainService.shared.delete(key: "refreshToken")
            
            if accessTokenDeleted || refreshTokenDeleted {
                print("✅ Cleared stale tokens from Keychain before OAuth")
            }
            
            // Reset any authentication state that might interfere
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
                self.errorMessage = nil
            }
        }
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
        // Clear any stale tokens before OAuth attempt to prevent interference
        Task {
            await clearStaleTokensIfNeeded()
        }
        
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
		
		// Clear stored OAuth credentials for complete logout
		self.storedOAuthProvider = nil
		self.storedIdToken = nil
		self.storedEmail = nil
		print("🔄 Cleared stored OAuth credentials for complete logout")

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
				} catch let error as APIError {
					await MainActor.run {
						// Handle specific API errors
						if case .invalidStatusCode(let statusCode) = error {
							if statusCode == 404 {
								// User doesn't exist in Spawn database - direct to account not found view
								print("📍 User not found in Spawn database (404) - directing to AccountNotFoundView")
								self.spawnUser = nil
								self.navigateTo(.accountNotFound)
							} else {
								// Other status codes (401, 500, etc.) - something went wrong with the request
								print("❌ Authentication error (\(statusCode)) during OAuth sign-in: \(error.localizedDescription)")
								self.spawnUser = nil
								self.navigateTo(.accountNotFound)
								self.errorMessage = "Authentication failed. Please try again."
							}
						} else {
							// Other API errors (network, parsing, etc.)
							print("❌ API error during OAuth sign-in: \(error.localizedDescription)")
							self.spawnUser = nil
							self.navigateTo(.accountNotFound)
							self.errorMessage = "Unable to sign in. Please check your connection and try again."
						}
					}
				} catch {
					await MainActor.run {
						// Generic error handling
						print("❌ Unexpected error during OAuth sign-in: \(error.localizedDescription)")
						self.spawnUser = nil
						self.navigateTo(.accountNotFound)
						self.errorMessage = "An unexpected error occurred. Please try again."
					}
				}
			await MainActor.run {
				self.hasCheckedSpawnUserExistence = true
			}
		}
	}
	
	// Helper method to handle API errors consistently
	private func handleApiError(_ error: APIError) {
		// For 404 errors (user doesn't exist), direct to account not found view without showing an error
		if case .invalidStatusCode(let statusCode) = error, statusCode == 404 {
			self.spawnUser = nil
			self.navigateTo(.accountNotFound)
			print("User does not exist yet in Spawn database - directing to account not found view")
		} else {
			self.spawnUser = nil
			self.navigateTo(.accountNotFound)
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
			self.navigationState = .none
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

			print("User created successfully: \(fetchedUser.username ?? "Unknown")")
			if let profilePic = fetchedUser.profilePicture {
				print("Profile picture set: \(profilePic)")
			} else {
				print("No profile picture set in created user")
			}
			
			// Only set user and navigate after successful account creation
			await MainActor.run {
				self.spawnUser = fetchedUser
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


	
	private func navigateBasedOnUserStatus(authResponse: AuthResponseDTO) {
		// Reset form validation state
		isFormValid = false
		
		guard let status = authResponse.status else {
			// No status means legacy active user
            print("Error: User has no status")
			return
		}
		
		// Reset hasCompletedOnboarding for users who haven't completed onboarding
		// This ensures they go through onboarding even if flag was previously set
		if status != .active {
			hasCompletedOnboarding = false
			UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
			print("🔄 Reset hasCompletedOnboarding for user with status: \(status.rawValue)")
		}
		
		switch status {
		case .emailVerified:
			// Needs to input username, phone number, and password
			// Check if user is registering with email vs OAuth
			let isOAuthUser = authProvider != .email
			navigateTo(.userDetailsInput(isOAuthUser: isOAuthUser))
			print("📍 User status: emailVerified - navigating to user details input (OAuth: \(isOAuthUser))")
		case .usernameAndPhoneNumber:
			// Needs to complete name and photo details
			navigateTo(.userOptionalDetailsInput)
			print("📍 User status: usernameAndPhoneNumber - navigating to name and photo input")
        case .nameAndPhoto:
            navigateTo(.contactImport)
            print("📍 User status: nameAndPhoto - navigating to contact import")
        case .contactImport:
            navigateTo(.userTermsOfService)
            print("📍 User status: contactImport - navigating to terms of service")
		case .active:
			// Fully onboarded user - go to feed
			isFormValid = true
            isLoggedIn = true
			// Ensure hasCompletedOnboarding is set for active users
			if !hasCompletedOnboarding {
				hasCompletedOnboarding = true
				UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
				print("🔄 Set hasCompletedOnboarding for active user")
			}
			navigateTo(.feedView)
			print("📍 User status: active - navigating to feed")
		}
	}
    
    private func continueUserOnboarding(authResponse: AuthResponseDTO) {
        
        guard let status = authResponse.status else {
            // No status means legacy active user
            print("❌ [AUTH] Error: User has no status")
            return
        }
        
        print("🔍 [AUTH] User status: \(status.rawValue)")
        print("🔍 [AUTH] User onboarding completed: \(hasCompletedOnboarding)")
        print("🔍 [AUTH] User details: \(authResponse.user.username ?? "no username"), \(authResponse.user.name ?? "no name")")
        
        switch status {
        case .emailVerified:
            // Needs to input username, phone number, and password
            // Check if user is registering with email vs OAuth
            let isOAuthUser = authProvider != .email
            navigateTo(.userDetailsInput(isOAuthUser: isOAuthUser))
            print("📍 [AUTH] User status: emailVerified - navigating to user details input (OAuth: \(isOAuthUser))")
            
        case .usernameAndPhoneNumber:
            // Needs to complete name and photo details
            navigateTo(.userOptionalDetailsInput)
            print("📍 [AUTH] User status: usernameAndPhoneNumber - navigating to optional details input")
        
        case .nameAndPhoto:
            navigateTo(.contactImport)
            print("📍 [AUTH] User status: nameAndPhoto - navigating to contact import")
        
        case .contactImport:
            navigateTo(.userTermsOfService)
            print("📍 [AUTH] User status: contactImport - navigating to terms of service")
            
        case .active:
            // Fully onboarded user - go to feed
            isFormValid = true
            isLoggedIn = true
            navigateTo(.feedView)
			// Mark onboarding as completed for active users
			if !hasCompletedOnboarding {
				markOnboardingCompleted()
			}
            print("📍 [AUTH] User status: active - navigating to feed")
        }
    }
    
    
    func completeContactImport() async {
        guard let userId = spawnUser?.id else {
            print("Error: No user ID available for contact import completion")
            return
        }
        
        guard let url = URL(string: APIService.baseURL + "auth/complete-contact-import/\(userId)") else {
            print("Error: Failed to create URL for contact import completion")
            return
        }
        
        do {
            let updatedUser: BaseUserDTO? = try await apiService.sendData(EmptyBody(), to: url, parameters: nil)
            
            guard let updatedUser = updatedUser else {
                await MainActor.run {
                    print("Error: No user data returned from contact import completion")
                    self.errorMessage = "Failed to complete contact import. Please try again."
                }
                return
            }
            
            await MainActor.run {
                self.spawnUser = updatedUser
                self.navigateTo(.userTermsOfService)
                print("Successfully completed contact import for user: \(updatedUser.username ?? "Unknown")")
            }
        } catch {
            await MainActor.run {
                print("Error completing contact import: \(error.localizedDescription)")
                self.errorMessage = "Failed to complete contact import. Please try again."
            }
        }
    }
    
    func acceptTermsOfService() async {
        guard let userId = spawnUser?.id else {
            print("Error: No user ID available for TOS acceptance")
            await MainActor.run {
                self.errorMessage = "Unable to proceed. Please try signing in again."
            }
            return
        }
        
        guard let url = URL(string: APIService.baseURL + "auth/accept-tos/\(userId)") else {
            print("Error: Failed to create URL for TOS acceptance")
            await MainActor.run {
                self.errorMessage = "Unable to proceed at this time. Please try again."
            }
            return
        }
        
        do {
            let updatedUser: BaseUserDTO? = try await apiService.sendData(EmptyBody(), to: url, parameters: nil)
            
            guard let updatedUser = updatedUser else {
                await MainActor.run {
                    print("Error: No user data returned from TOS acceptance")
                    self.errorMessage = "Unable to complete setup. Please try again."
                }
                return
            }
            
            await MainActor.run {
                self.spawnUser = updatedUser
                self.navigateTo(.feedView)
                self.isLoggedIn = true
                self.errorMessage = nil // Clear any previous errors on success
                // Mark onboarding as completed when user accepts Terms of Service
                self.markOnboardingCompleted()
                print("Successfully accepted Terms of Service for user: \(updatedUser.username ?? "Unknown")")
            }
        } catch let error as APIError {
            await MainActor.run {
                // Provide user-friendly error messages based on API error
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Unable to complete setup. Please try again."
                    case 401:
                        self.errorMessage = "Your session has expired. Please sign in again."
                    case 429:
                        self.errorMessage = "Too many attempts. Please wait a few minutes and try again."
                    case 500...599:
                        self.errorMessage = "Server temporarily unavailable. Please try again later."
                    default:
                        self.errorMessage = "Unable to complete setup. Please try again."
                    }
                } else {
                    self.errorMessage = "Network connection error. Please check your internet connection and try again."
                }
                print("Error accepting Terms of Service: \(error.localizedDescription)")
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to complete setup. Please try again."
                print("Error accepting Terms of Service: \(error.localizedDescription)")
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
				await NotificationService.shared.unregisterDeviceToken()

                _ = try await self.apiService.deleteData(from: url, parameters: nil, object: EmptyBody())
				
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
		// Clear all cached data for current user before clearing user data
		if let currentUserId = self.spawnUser?.id {
			AppCache.shared.clearAllDataForUser(currentUserId)
		}
		
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
			print("Starting profile picture update for user \(userId) (username: \(user.username ?? "Unknown"), name: \(user.name ?? "Unknown")) with image data size: \(imageData.count) bytes")
		} else {
			print("Starting profile picture update for user \(userId) with image data size: \(imageData.count) bytes")
		}
		
		// Immediately update the UI with the selected image for better UX
		await MainActor.run {
			// Create a temporary updated user with the selected image for immediate UI feedback
			if self.spawnUser != nil {
				// We'll update this with the actual URL once uploaded
				self.objectWillChange.send()
			}
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
					
					// Post notification for profile update to trigger hot-reload across the app
					NotificationCenter.default.post(
						name: .profileUpdated,
						object: nil,
						userInfo: ["updatedUser": updatedUser, "updateType": "profilePicture"]
					)
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
						
						// Post notification for profile update to trigger hot-reload across the app
						NotificationCenter.default.post(
							name: .profileUpdated,
							object: nil,
							userInfo: ["updatedUser": updatedUser, "updateType": "profilePicture"]
						)
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
			print("Editing profile for user \(userId) (username: \(user.username ?? "Unknown"), name: \(user.name ?? "Unknown"))")
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
					
					print("Profile updated successfully: \(updatedUser.username ?? "Unknown")")
					
					// Post notification for profile update to trigger hot-reload across the app
					NotificationCenter.default.post(
						name: .profileUpdated,
						object: nil,
						userInfo: ["updatedUser": updatedUser, "updateType": "nameAndUsername"]
					)
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
					
					print("User data refreshed: \(updatedUser.username ?? "Unknown"), \(updatedUser.name ?? "Unknown")")
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
                    // Set isLoggedIn to true for successful authentication, regardless of onboarding status
                    // This matches the behavior of other authentication methods
                    self.isLoggedIn = true
                    
                    // Only mark onboarding as completed for users with 'active' status
                    // Users with other statuses still need to complete onboarding steps
                    if authResponse.status == .active && !self.hasCompletedOnboarding {
                        self.markOnboardingCompleted()
                    }
                    
                    self.continueUserOnboarding(authResponse: authResponse)
                    // Don't set hasCheckedSpawnUserExistence directly - let checkLoadingCompletion() handle it
                    // This ensures the minimum loading time is respected
                }
            }
        } catch {
            print("🔄 DEBUG: quickSignIn() - Error performing quick-login. Re-login is required")
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
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
                    await MainActor.run {
                        self.isLoggedIn = false
                        self.spawnUser = nil
                        self.errorMessage = "Invalid email/username or password. Please check your credentials and try again."
                    }
                    return
                }
                print("Email/username login successful")
                await MainActor.run {
                    self.spawnUser = user
                    // For existing users with email/username sign-in, mark onboarding as completed
                    if !self.hasCompletedOnboarding {
                        self.markOnboardingCompleted()
                    }
                    self.navigateTo(.feedView)
                    self.isLoggedIn = true
                    self.errorMessage = nil // Clear any previous errors on success
                }
            }
        } catch let error as APIError {
            print("Failed to login with email/username: \(error)")
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
                print("[DEBUG] Error: \(error)")
                // Provide user-friendly error messages based on API error
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 401:
                        self.errorMessage = "Invalid email/username or password. Please check your credentials and try again."
                    case 404:
                        self.errorMessage = "Account not found. Please check your email/username or create a new account."
                    case 429:
                        self.errorMessage = "Too many login attempts. Please wait a few minutes and try again."
                    case 500...599:
                        self.errorMessage = "Server temporarily unavailable. Please try again later."
                    default:
                        self.errorMessage = "Unable to sign in at this time. Please try again later."
                    }
                } else {
                    self.errorMessage = "Network connection error. Please check your internet connection and try again."
                }
            }
        } catch {
            print("Failed to login with email/username: \(error)")
            await MainActor.run {
                self.isLoggedIn = false
                self.spawnUser = nil
                self.errorMessage = "Unable to sign in at this time. Please try again later."
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
    
    // New method for sending email verification
    func sendEmailVerification(email: String) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/register/verification/send") {
                let emailVerificationDTO = EmailVerificationSendDTO(email: email)
                let response: EmailVerificationResponseDTO? = try await self.apiService.sendData(emailVerificationDTO, to: url, parameters: nil)
                
                await MainActor.run {
                    if let response = response {
                        // Success - navigate to verification code view
                        self.navigationState = .verificationCode
                        self.email = email
                        // Set authProvider to email for email registration
                        self.authProvider = .email
                        // Store the seconds until next attempt for the timer
                        self.secondsUntilNextVerificationAttempt = response.secondsUntilNextAttempt
                        self.errorMessage = nil
                    } else {
                        // Handle error
                        self.errorMessage = "Unable to send verification email. Please try again."
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                // Handle specific API errors with user-friendly messages
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Please enter a valid email address."
                    case 409:
                        self.errorMessage = "This email is already registered. Please try signing in instead."
                    case 429:
                        self.errorMessage = "Too many verification attempts. Please wait a few minutes and try again."
                    case 500...599:
                        self.errorMessage = "Server temporarily unavailable. Please try again later."
                    default:
                        self.errorMessage = "Unable to send verification email. Please try again."
                    }
                } else {
                    self.errorMessage = "Network connection error. Please check your internet connection and try again."
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unable to send verification email. Please try again."
            }
        }
    }
    
    // New method for OAuth registration
    func registerWithOAuth(idToken: String, provider: AuthProviderType, email: String?, name: String?, profilePictureUrl: String?) async {
        // Store OAuth credentials immediately for potential re-authentication during onboarding
        await MainActor.run {
            self.authProvider = provider
            self.idToken = idToken
            self.email = email
            
            // Also store them in backup storage for onboarding
            self.storedOAuthProvider = provider
            self.storedIdToken = idToken
            self.storedEmail = email
            
            print("🔐 Stored OAuth credentials for onboarding (provider: \(provider.rawValue))")
        }
        
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
                        
                        // Ensure we have the OAuth credentials stored for subsequent API calls
                        self.authProvider = provider
                        self.idToken = idToken
                        self.email = email
                        
                        // Set isLoggedIn to true for OAuth users since they have a valid account and tokens
                        self.isLoggedIn = true
                        
                        self.navigateBasedOnUserStatus(authResponse: authResponse)
                        self.email = authResponse.user.email
                        self.errorMessage = nil
                    } else {
                        // Handle error
                        self.navigateTo(.accountNotFound)
                        self.errorMessage = "Unable to create account with this sign-in method. Please try again."
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                // Handle specific API errors with user-friendly messages
                if case .invalidStatusCode(let statusCode) = error {
                    switch statusCode {
                    case 400:
                        self.errorMessage = "Invalid sign-in credentials. Please try again."
                    case 409:
                        // User already exists - attempt to sign them in instead
                        print("📍 User already exists (409), attempting OAuth sign-in")
                        self.isAutoSigningIn = true
                        self.authAlert = .accountFoundSigningIn
                        Task {
                            await self.signInWithOAuth(idToken: idToken, provider: provider, email: email)
                        }
                        return
                    case 429:
                        self.errorMessage = "Too many registration attempts. Please wait a few minutes and try again."
                    case 500:
                        // Server error - might also indicate existing user, try sign-in as fallback
                        print("📍 Server error (500), attempting OAuth sign-in as fallback")
                        self.isAutoSigningIn = true
                        self.authAlert = .accountFoundSigningIn
                        Task {
                            await self.signInWithOAuth(idToken: idToken, provider: provider, email: email)
                        }
                        return
                    case 500...599:
                        self.errorMessage = "Server temporarily unavailable. Please try again later."
                    default:
                        self.navigateTo(.accountNotFound)
                        self.errorMessage = "Unable to create account. Please try again."
                    }
                } else {
                    self.navigateTo(.accountNotFound)
                    self.errorMessage = "Network connection error. Please check your internet connection and try again."
                }
            }
        } catch {
            await MainActor.run {
                self.navigateTo(.accountNotFound)
                self.errorMessage = "Unable to create account. Please try again."
            }
        }
    }
    
    // New method for OAuth sign-in (for existing users)
    private func signInWithOAuth(idToken: String, provider: AuthProviderType, email: String?) async {
        // Set the OAuth credentials for the sign-in attempt
        await MainActor.run {
            self.authProvider = provider
            self.idToken = idToken
            self.email = email
            print("🔐 Setting OAuth credentials for re-authentication")
        }
        
        guard let url = URL(string: APIService.baseURL + "auth/sign-in") else {
            await MainActor.run {
                self.errorMessage = "Failed to create sign-in URL"
            }
            return
        }
        
        let emailToUse = email ?? ""
        let parameters: [String: String] = [
            "idToken": idToken,
            "email": emailToUse,
            "provider": provider.rawValue
        ]
        
        do {
            let authResponse: AuthResponseDTO = try await self.apiService.fetchData(from: url, parameters: parameters)
            
            await MainActor.run {
                self.spawnUser = authResponse.user
                self.email = authResponse.user.email
                self.errorMessage = nil
                
                // Clear auto sign-in state and alert on successful sign-in
                self.isAutoSigningIn = false
                self.authAlert = nil
                
                // For re-authentication during onboarding, determine where to navigate
                if !self.hasCompletedOnboarding {
                    print("📍 Re-authentication successful during onboarding - continuing with onboarding flow")
                    self.navigateBasedOnUserStatus(authResponse: authResponse)
                } else {
                    // For incomplete users, continue their onboarding
                    self.continueUserOnboarding(authResponse: authResponse)
                }
                
                print("📍 OAuth re-authentication successful for user with status: \(authResponse.status?.rawValue ?? "unknown")")
            }
        } catch {
            await MainActor.run {
                print("❌ OAuth re-authentication failed: \(error.localizedDescription)")
                
                // If re-authentication fails, we need to start over
                self.navigateTo(.accountNotFound)
                self.errorMessage = "Authentication failed. Please try signing in again."
                
                // Clear auto sign-in state on failure
                self.isAutoSigningIn = false
                self.authAlert = nil
            }
        }
    }
    
    // New method for verifying email verification code
    func verifyEmailCode(email: String, code: String) async {
        do {
            if let url: URL = URL(string: APIService.baseURL + "auth/register/verification/check") {
                let verificationDTO = EmailVerificationVerifyDTO(email: email, verificationCode: code)
                let response: AuthResponseDTO? = try await self.apiService.sendData(verificationDTO, to: url, parameters: nil)
                
                await MainActor.run {
                    if let authResponse = response {
                        // Success - set user and navigate based on status
                        self.spawnUser = authResponse.user
                        self.email = authResponse.user.email
                        // Set authProvider to email for email registration
                        self.authProvider = .email
                        self.errorMessage = nil
                        
                        // Navigate based on user status
                        self.navigateBasedOnUserStatus(authResponse: authResponse)
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
    
    // Add this new method to validate stored tokens
    private func validateStoredTokens() -> Bool {
        // Check if we have both access and refresh tokens
        let hasAccessToken = KeychainService.shared.load(key: "accessToken") != nil
        let hasRefreshToken = KeychainService.shared.load(key: "refreshToken") != nil
        
        print("🔐 Token validation - Access: \(hasAccessToken ? "✅" : "❌"), Refresh: \(hasRefreshToken ? "✅" : "❌")")
        
        // For OAuth users during onboarding, we need at least one valid token
        // The refresh token is more important for long-term authentication
        return hasAccessToken || hasRefreshToken
    }
    
    // Modify updateUserDetails to validate tokens first
    func updateUserDetails(id: String, username: String, phoneNumber: String, password: String?) async {
        // Validate tokens before making the API call
        if !validateStoredTokens() {
            print("🔄 No valid tokens found before updateUserDetails. Attempting OAuth re-authentication...")
            await MainActor.run {
                self.handleAuthenticationFailure()
            }
            return
        }
        
        do {
            let dto = UpdateUserDetailsDTO(id: id, username: username, phoneNumber: phoneNumber, password: password)
            if let url = URL(string: APIService.baseURL + "auth/user/details") {
                let response: BaseUserDTO? = try await self.apiService.sendData(dto, to: url, parameters: nil)
                await MainActor.run {
                    if let user = response {
                        self.spawnUser = user
                        self.navigateTo(.userOptionalDetailsInput)
                        self.errorMessage = nil
                        print("✅ User details updated successfully")
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
                    if statusCode == 401 {
                        // Authentication failed - tokens may be invalid
                        print("🔄 Authentication failed during user details update. Attempting re-authentication...")
                        self.handleAuthenticationFailure()
                    } else {
                        self.errorMessage = "Server error (\(statusCode))."
                    }
                case .failedTokenSaving(let tokenType):
                    self.errorMessage = "Authentication error. Please try signing in again."
                    print("🔄 Token saving failed for \(tokenType). Logging out user.")
                    self.signOut()
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
    
    // Add this new method to handle authentication failures gracefully
    private func handleAuthenticationFailure() {
        // Prevent multiple concurrent re-authentication attempts
        guard !isReauthenticating else {
            print("🔄 Re-authentication already in progress, skipping duplicate attempt")
            return
        }
        
        isReauthenticating = true
        print("🔄 Starting authentication failure recovery...")
        
        // First try to use current OAuth credentials
        var idToken = self.idToken
        var authProvider = self.authProvider
        var email = self.email
        
        // If current credentials are not available, try stored credentials
        if idToken == nil || authProvider == nil {
            print("🔄 Current OAuth credentials not available, trying stored credentials...")
            idToken = self.storedIdToken
            authProvider = self.storedOAuthProvider
            email = self.storedEmail
        }
        
        // Check if we have OAuth credentials to re-authenticate
        guard let validIdToken = idToken,
              let validAuthProvider = authProvider,
              let validEmail = email else {
            print("🔄 No OAuth credentials available for re-authentication. Logging out.")
            isReauthenticating = false
            self.signOut()
            return
        }
        
        print("🔄 Re-authenticating with OAuth credentials (provider: \(validAuthProvider.rawValue))...")
        
        // Clear potentially stale tokens
        let _ = KeychainService.shared.delete(key: "accessToken")
        let _ = KeychainService.shared.delete(key: "refreshToken")
        
        // Attempt to re-sign in with OAuth credentials
        Task {
            await self.signInWithOAuth(idToken: validIdToken, provider: validAuthProvider, email: validEmail)
            await MainActor.run {
                self.isReauthenticating = false
                print("🔄 Re-authentication attempt completed")
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
                        self.navigateTo(.contactImport)
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

