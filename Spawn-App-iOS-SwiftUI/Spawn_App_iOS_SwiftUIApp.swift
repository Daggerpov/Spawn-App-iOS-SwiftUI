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
	// Add UIApplicationDelegateAdaptor for push notifications
	@UIApplicationDelegateAdaptor private var appDelegate: CustomAppDelegate
	@StateObject var userAuth = UserAuthViewModel.shared
	@StateObject var appCache = AppCache.shared
    
    init() {
        // Set default appearance for common UI controls using system fonts
        // Custom fonts will be applied through SwiftUI modifiers
        let systemFont = UIFont.systemFont(ofSize: 16)
        let systemBold = UIFont.boldSystemFont(ofSize: 16)
        
        UILabel.appearance().font = systemFont
        UITextField.appearance().font = systemFont
        UITextView.appearance().font = systemFont
        UIButton.appearance().titleLabel?.font = systemBold
        
        // Set fonts for navigation bars
        UINavigationBar.appearance().titleTextAttributes = [
            .font: systemBold.withSize(18)
        ]
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: systemBold.withSize(34)
        ]
        
        // Customize tab bar appearance
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: systemFont.withSize(12)
        ], for: .normal)
    }

	var body: some Scene {
		WindowGroup {
			Group {
				if userAuth.isLoggedIn && userAuth.spawnUser != nil {
					// User is logged in and user data exists - go to main content
					ContentView(user: userAuth.spawnUser!)
						.onAppear {
							// Connect the app delegate to the app
							appDelegate.app = self

							// Initialize and validate the cache
							Task {
								await appCache.validateCache()
							}
						}
						.onestFontTheme()
				} else if !userAuth.hasCheckedSpawnUserExistence {
                    // Show loading screen while auth checks are in progress
                    LoadingView()
                        .onAppear {
                            // Connect the app delegate to the app
                            appDelegate.app = self
                            
                            // If we're mocking, simulate a login with mock user
                            if MockAPIService.isMocking {
                                Task {
                                    await userAuth.setMockUser()
                                }
                            }
                        }
				} else {
                    // User is not logged in or has no user data - show launch screen with login options
                    LaunchView()
                        .onOpenURL { url in
                            GIDSignIn.sharedInstance.handle(url)
                        }
                        .onAppear {
                            // Connect the app delegate to the app
                            appDelegate.app = self
                        }
                        .onestFontTheme()
                }
            }
		}
	}
}
