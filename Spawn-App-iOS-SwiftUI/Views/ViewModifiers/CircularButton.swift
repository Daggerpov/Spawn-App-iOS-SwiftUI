//
//  CircularButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/14/24.
//

import SwiftUI

extension Circle {
	func CircularButton(
		systemName: String, buttonActionCallback: @escaping () -> Void,
		width: CGFloat? = 17.5, height: CGFloat? = 17.5,
		frameSize: CGFloat? = 40, source: String? = "default"
	) -> some View {
		return
			self
			.modifier(
				CircularButtonStyling(
					width: width, height: height, frameSize: frameSize,
					source: source)
			)
			.overlay(
				Button(action: {
					buttonActionCallback()
				}) {
					Image(systemName: systemName)
						.resizable()
						.frame(width: width, height: height)
						.shadow(radius: 20)
						.foregroundColor(universalAccentColor)
				}
			)
	}
}

struct CircularButtonStyling: ViewModifier {
	var width: CGFloat?
	var height: CGFloat?
	var frameSize: CGFloat?
	var source: String? = "default"
	func body(content: Content) -> some View {
		content
			.frame(width: frameSize, height: frameSize)
			.foregroundColor(
				source == "map" ? universalBackgroundColor : Color.white
			)
			.background(
				source == "map" ? universalBackgroundColor : Color.white
			)
			.clipShape(Circle())
			.overlay(
				Group {
					if source == "map" {
						Circle()
							.stroke(universalAccentColor, lineWidth: 2)
					} else {
						EmptyView()
					}
				}
			)
	}
}

@available(iOS 17.0, *)
#Preview {
	VStack(spacing: 20) {
		// Default circular button
		Circle()
			.CircularButton(
				systemName: "plus",
				buttonActionCallback: {},
				width: 17.5,
				height: 17.5,
				frameSize: 40
			)
		
		// Map style circular button
		Circle()
			.CircularButton(
				systemName: "location",
				buttonActionCallback: {},
				width: 17.5,
				height: 17.5,
				frameSize: 40,
				source: "map"
			)
	}
	.padding()
}
