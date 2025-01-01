//
//  LaunchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

import SwiftUI

struct LaunchView: View {
	@StateObject var observableUser = ObservableUser(user: .danielAgapov)

	var body: some View {
		NavigationStack{
			VStack(spacing: 16) {
				Spacer()
				Image("spawn_launch_logo")
					.resizable()
					.scaledToFit()
					.frame(width: 300, height: 300)
				
				NavigationLink(destination: {
					UserInfoInputView()
						.environmentObject(observableUser) // Inject the observable user into the environment
						.onAppear {
							User.setupFriends()
						}
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}) {
					AuthProviderButtonView(authProviderType: .google)
				}
				
				NavigationLink(destination: {
					UserInfoInputView()
						.environmentObject(observableUser) // Inject the observable user into the environment
						.onAppear {
							User.setupFriends()
						}
						.navigationBarTitle("")
						.navigationBarHidden(true)
				}) {
					AuthProviderButtonView(authProviderType: .apple)
				}
				Spacer()
			}
			.background(Color(hex: "#8693FF"))
			.ignoresSafeArea()
		}
	}
}

#Preview {
	LaunchView()
}
