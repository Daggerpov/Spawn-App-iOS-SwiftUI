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

	@StateObject var observableUser: ObservableUser = ObservableUser(
		user: .danielAgapov)

    var body: some Scene {
        WindowGroup {
			if userAuth.isLoggedIn {
				UserInfoInputView()
					.environmentObject(observableUser)
			} else {
				LaunchView()
					.environmentObject(observableUser)
					.onOpenURL {url in
						GIDSignIn.sharedInstance.handle(url)
					}
			}
		}
    }
}
