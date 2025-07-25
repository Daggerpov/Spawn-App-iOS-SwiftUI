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
	@StateObject var themeService = ThemeService.shared
	@StateObject var deepLinkManager = DeepLinkManager.shared
    
    init() {
        // Register custom fonts
        Font.registerFonts()
        
        // Create font instances for our custom fonts with fallbacks
        let regularFont = UIFont(name: "Onest-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
        let mediumFont = UIFont(name: "Onest-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .medium)
        let semiboldFont = UIFont(name: "Onest-SemiBold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .semibold)
        let boldFont = UIFont(name: "Onest-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        
        // Set default appearance for common UI controls
        UILabel.appearance().font = regularFont
        UITextField.appearance().font = regularFont
        UITextView.appearance().font = regularFont
        UIButton.appearance().titleLabel?.font = semiboldFont
        
        // Set specific fonts for navigation bars, etc.
        UINavigationBar.appearance().titleTextAttributes = [
            .font: boldFont.withSize(18)
        ]
        
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: boldFont.withSize(34)
        ]
        
        // Customize tab bar appearance
        UITabBarItem.appearance().setTitleTextAttributes([
            .font: mediumFont.withSize(12)
        ], for: .normal)
    }

	private var rootView: some View {
		Group {
			if !userAuth.hasCheckedSpawnUserExistence {
				// Show loading screen while checking user existence
				LoadingView()
					.onAppear {
						// Connect the app delegate to the app
						appDelegate.app = self
						
						print("🔄 DEBUG: Showing LoadingView - hasCheckedSpawnUserExistence: \(userAuth.hasCheckedSpawnUserExistence), isFirstLaunch: \(userAuth.isFirstLaunch)")
						
						// If we're mocking, simulate a login with mock user
						if MockAPIService.isMocking {
							Task {
								await userAuth.setMockUser()
							}
						}
					}
					.onOpenURL { url in
						GIDSignIn.sharedInstance.handle(url)
					}
					.onestFontTheme()
			} else if userAuth.isLoggedIn, let spawnUser = userAuth.spawnUser, userAuth.hasCompletedOnboarding {
				// User is logged in, has user data, and has completed onboarding - go to main content
				ContentView(user: spawnUser, deepLinkManager: deepLinkManager)
					.onAppear {
						print("🔄 DEBUG: Showing ContentView - User is logged in")
						// Initialize and validate the cache
						Task {
							await appCache.validateCache()
						}
					}
					.onOpenURL { url in
						print("🔗 App: Received URL: \(url.absoluteString)")
						// Handle Google Sign-In URLs
						if url.scheme == "com.googleusercontent.apps.822760465266-hl53d2rku66uk4cljschig9ld0ur57na" {
							GIDSignIn.sharedInstance.handle(url)
						}
						// Handle Spawn deep links (both custom URL schemes and Universal Links)
						else if url.scheme == "spawn" || (url.scheme == "https" && url.host == "getspawn.com") {
							deepLinkManager.handleURL(url)
						}
					}
					.onestFontTheme()
			} else {
				// User is not logged in or has no user data - show welcome screen
				WelcomeView()
					.onAppear {
						print("🔄 DEBUG: Showing WelcomeView - hasCheckedSpawnUserExistence: \(userAuth.hasCheckedSpawnUserExistence), isLoggedIn: \(userAuth.isLoggedIn), spawnUser: \(userAuth.spawnUser?.id.uuidString ?? "nil")")
						
						// Connect the app delegate to the app
						appDelegate.app = self
					}
					.onOpenURL { url in
						GIDSignIn.sharedInstance.handle(url)
					}
					.onestFontTheme()
			}
		}
	}
	
	var body: some Scene {
		WindowGroup {
			rootView
				.preferredColorScheme(themeService.colorScheme.colorScheme)
		}
	}
}
