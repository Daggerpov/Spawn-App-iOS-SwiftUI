//
//  Spawn_App_iOS_SwiftUIApp.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI
import GoogleSignIn

@main
struct Spawn_App_iOS_SwiftUIApp: App {
	@StateObject var userAuth = UserAuthViewModel.shared

    var body: some Scene {
        WindowGroup {
			if userAuth.isLoggedIn, let unwrappedSpawnUser = userAuth.spawnUser {
				FeedView(user: unwrappedSpawnUser)
			} else {
				LaunchView()
					.onOpenURL {url in
						GIDSignIn.sharedInstance.handle(url)
					}
			}
		}
    }
}
