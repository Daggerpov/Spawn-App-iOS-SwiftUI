//
//  BottomNavButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct BottomNavButtonView: View {
	var user: BaseUserDTO
	var buttonType: BottomNavButtonType
	var imageName: String
	var imageSize: CGFloat = 25
	let source: BackButtonSourcePageType

	init(
		user: BaseUserDTO, buttonType: BottomNavButtonType,
		source: BackButtonSourcePageType = .feed
	) {
		self.user = user
		self.buttonType = buttonType
		switch buttonType {
		case .map:
			self.imageName = "map.fill"
		case .friends:
			self.imageName = "person.2.fill"
		case .feed:
			self.imageName = "list.bullet"
			self.imageSize = 12
		}
		self.source = source
	}

	var body: some View {
		switch buttonType {
		case .map:
			Circle()
				.frame(width: 45, height: 45)
				.foregroundColor(universalBackgroundColor)
				.clipShape(Circle())
				.overlay(
					Circle()
						.stroke(universalAccentColor, lineWidth: 2)
				)
				.overlay(
					NavigationLink(destination: {
						MapView(user: user)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}) {
						navButtonImage
					}
				)
		case .feed:
			Circle()
				.modifier(
					CircularButtonStyling(
						width: 25,
						height: 20,
						frameSize: 45,
						source: "map"
					)
				)
				.overlay(
					NavigationLink(destination: {
						FeedView(user: user)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}) {
						Image(systemName: imageName)
							.resizable()
							.frame(width: 25, height: 20)
							.shadow(radius: 20)
							.foregroundColor(universalAccentColor)
					}
				)
		case .friends:
			Circle()
				.modifier(
					CircularButtonStyling(
						width: 25, height: 20, frameSize: 45, source: "map")
				)
				.overlay(
					NavigationLink(destination: {
						FriendsAndTagsView(user: user, source: source)
							.navigationBarTitle("")
							.navigationBarHidden(true)
					}) {
						Image(systemName: imageName)
							.resizable()
							.frame(width: 25, height: 20)
							.shadow(radius: 20)
							.foregroundColor(universalAccentColor)
					}
				)
		}
	}
}

extension BottomNavButtonView {
	var navButtonImage: some View {
		Image(systemName: imageName)
			.resizable()
			.frame(width: imageSize, height: imageSize)
			.clipShape(Circle())
			.shadow(radius: 20)
			.foregroundColor(universalAccentColor)
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	BottomNavButtonView(
		user: BaseUserDTO.danielAgapov,
		buttonType: BottomNavButtonType.map,
		source: BackButtonSourcePageType.feed
	).environmentObject(appCache)
}
