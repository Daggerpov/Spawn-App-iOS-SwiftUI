//
//  Spawn_App_iOS_SwiftUIApp.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import GoogleSignIn
import SwiftUI

@main
struct Spawn_App_iOS_SwiftUIApp: App {
	// This will set the app delegate that will handle notifications and other system events
	@UIApplicationDelegateAdaptor(CustomAppDelegate.self) var appDelegate
	@StateObject var userAuth = UserAuthViewModel.shared

	// Register the user notification center delegate and request authorization
	init() {
		// Initialize any required services here
		if let userId = KeychainService.shared.retrieveUserID() {
			// When app starts, fetch user data if we have a saved user ID
			Task {
				do {
					if let url = URL(string: APIService.baseURL + "users/\(userId)") {
						let apiService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
						let user: BaseUserDTO = try await apiService.fetchData(from: url, parameters: nil)
						
						// Set the user in the UserService
						UserService.shared.setCurrentUser(user)
					}
				} catch {
					print("Failed to load user data: \(error)")
				}
			}
		}
	}

	var body: some Scene {
		WindowGroup {
			if userAuth.isLoggedIn, let unwrappedSpawnUser = userAuth.spawnUser
			{
				FeedView(user: unwrappedSpawnUser)
					.onAppear {
						// Connect the app delegate to the app
						appDelegate.app = self
					}
			} else {
				LaunchView()
					.onOpenURL { url in
						GIDSignIn.sharedInstance.handle(url)
					}
					.onAppear {
						// Connect the app delegate to the app
						appDelegate.app = self
					}
			}
		}
	}
}
