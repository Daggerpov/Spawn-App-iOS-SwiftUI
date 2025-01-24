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
    var body: some Scene {
        WindowGroup {
			LaunchView()
				.onOpenURL {url in
					GIDSignIn.sharedInstance.handle(url)
				}
		}
    }
}
