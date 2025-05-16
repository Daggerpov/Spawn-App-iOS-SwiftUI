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
        // Register custom fonts
        Font.registerFonts()
        
        // Print available fonts for debugging
        UIFont.familyNames.forEach { familyName in
            print("Family: \(familyName)")
            UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
                print(" Font: \(fontName)")
            }
        }
        
        // Create font instances for our custom fonts
        let regularFont = UIFont(name: "Onest-Regular", size: 16)!
        let mediumFont = UIFont(name: "Onest-Medium", size: 16)!
        let semiboldFont = UIFont(name: "Onest-SemiBold", size: 16)!
        let boldFont = UIFont(name: "Onest-Bold", size: 16)!
        
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

	var body: some Scene {
		WindowGroup {
			if userAuth.isLoggedIn, let unwrappedSpawnUser = userAuth.spawnUser
			{
                ContentView(user: unwrappedSpawnUser)
					.onAppear {
						// Connect the app delegate to the app
						appDelegate.app = self
						
						// Initialize and validate the cache
						Task {
							await appCache.validateCache()
						}
					}
					.environmentObject(appCache)
                    .onestFontTheme()
			} else {
				LaunchView()
					.onOpenURL { url in
						GIDSignIn.sharedInstance.handle(url)
					}
					.onAppear {
						// Connect the app delegate to the app
						appDelegate.app = self
					}
                    .environmentObject(appCache)
                    .onestFontTheme()
			}
		}
	}
}
