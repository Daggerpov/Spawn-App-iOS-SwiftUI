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
