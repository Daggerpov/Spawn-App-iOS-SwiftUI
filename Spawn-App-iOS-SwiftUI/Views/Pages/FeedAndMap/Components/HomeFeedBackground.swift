//
//  HomeFeedBackground.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Home's page background. Figma's Event Feed (node 2802:4741) uses a very light radial gradient,
/// #F0F3FF at the bottom center fading to white, in a tall narrow ellipse (about a third of the
/// width wide and the full height tall). Dark mode keeps the plain background.
struct HomeFeedBackground: View {
	@Environment(\.colorScheme) private var colorScheme

	var body: some View {
		if colorScheme == .dark {
			universalBackgroundColor
		} else {
			GeometryReader { geometry in
				// An elliptical gradient's radii scale with its frame, so the frame is sized to make
				// Figma's ellipse: half its width (35% of the screen) by half its height (the screen).
				EllipticalGradient(
					colors: [Color(hex: "#F0F3FF"), .white],
					center: .bottom,
					startRadiusFraction: 0,
					endRadiusFraction: 0.5
				)
				.frame(width: geometry.size.width * 0.7, height: geometry.size.height * 2)
				.frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
			}
			.background(Color.white)
			.clipped()
		}
	}
}
