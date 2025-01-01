//
//  Spawn_App_iOS_SwiftUIApp.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import SwiftUI

@main
struct Spawn_App_iOS_SwiftUIApp: App {
	@StateObject var observableUser = ObservableUser(user: .danielAgapov) // Shared instance

    var body: some Scene {
        WindowGroup {
			LaunchView()
				.environmentObject(observableUser) // Inject the observable user into the environment
				.onAppear {
					User.setupFriends()
				}
		}
    }
}

