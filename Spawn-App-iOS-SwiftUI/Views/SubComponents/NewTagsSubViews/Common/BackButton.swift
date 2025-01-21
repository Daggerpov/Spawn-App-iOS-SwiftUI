//
//  BackButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct BackButton: View {
	@EnvironmentObject var observableUser: ObservableUser
	var source: BackButtonSourcePageType
	var body: some View {
		Image(systemName: "arrow.left")
			.font(.system(size: 24, weight: .bold))
			.foregroundColor(universalAccentColor)
			.overlay(
				NavigationLink(destination: {
					switch source {
					case .map:
						MapView(user: observableUser.user)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					case .feed:
						FeedView(user: observableUser.user)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}
				}) {
					Image(systemName: "arrow.left")
						.font(.system(size: 24, weight: .bold))
						.foregroundColor(universalAccentColor)
				}
			)
	}
}
