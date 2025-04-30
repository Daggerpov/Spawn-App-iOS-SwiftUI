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
        
        // Set Onest as the default font for the app
        let fontDescriptor = UIFontDescriptor(name: "Onest-Regular", size: 0)
        UIFont.familyNames.forEach { familyName in
            print("Family: \(familyName)")
            UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
                print(" Font: \(fontName)")
            }
        }
        
        // Set Onest font as default for various UI elements
        UILabel.appearance().font = UIFont(descriptor: fontDescriptor, size: 16)
        UITextField.appearance().font = UIFont(descriptor: fontDescriptor, size: 16)
        UITextView.appearance().font = UIFont(descriptor: fontDescriptor, size: 16)
        UIButton.appearance().titleLabel?.font = UIFont(descriptor: fontDescriptor, size: 16)
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
