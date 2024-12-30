//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct LaunchView: View {
	var body: some View {
		VStack (spacing: 16){
			Spacer()
			Image("spawn_launch_logo")
				.resizable()
				.scaledToFit()
				.frame(width: 300, height: 300)

			// TODO: fill in action for button later
			Button(action: {}) {
				AuthProviderButtonView(authProviderType: .google)
			}

			// TODO: fill in action for button later
			Button(action: {}) {
				AuthProviderButtonView(authProviderType: .apple)
			}
			Spacer()
		}
		.background(Color(red: 0.69, green: 0.75, blue: 1.0))
		.ignoresSafeArea()
	}
}

#Preview {
	LaunchView()
}
