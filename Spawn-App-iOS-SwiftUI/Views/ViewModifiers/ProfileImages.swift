//
//  ProfileImages.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

extension Image {
	func ProfileImageModifier(imageType: ProfileImageType) -> some View {
		let imageSize: CGFloat
		var strokeColor: Color = universalAccentColor
		var lineWidth: CGFloat = 2

		switch imageType {
		case .feedPage:
			imageSize = 55
		case .friendsListView:
			imageSize = 50
			lineWidth = 0
		case .eventParticipants, .chatMessage:
			imageSize = 25
			strokeColor = .white
			lineWidth = 1
		case .profilePage:
			imageSize = 150
		case .mapView:
			imageSize = 40
		case .tagFriends:
			imageSize = 35
			lineWidth = 0
        case .friendRequest, .choosingFriendTags:
            imageSize = 80
		}

		return
			self
			.resizable()
			.aspectRatio(contentMode: .fill)
			.frame(width: imageSize, height: imageSize)
			.clipShape(Circle())
			.overlay(Circle().stroke(strokeColor, lineWidth: lineWidth))
	}
}
