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
					source: source, buttonActionCallback: buttonActionCallback, systemName: systemName)
			)
	}
}

struct CircularButtonStyling: ViewModifier {
	var width: CGFloat?
	var height: CGFloat?
	var frameSize: CGFloat?
	var source: String? = "default"
	var buttonActionCallback: () -> Void
	var systemName: String

	// Animation states for 3D effect
	@State private var isPressed = false
	@State private var scale: CGFloat = 1.0

	func body(content: Content) -> some View {
		content
			.frame(width: frameSize, height: frameSize)
			.foregroundColor(
				source == "map" ? universalBackgroundColor : universalBackgroundColor
			)
			.background(
				source == "map" ? universalBackgroundColor : universalBackgroundColor
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
			.overlay(
				Button(action: {
					// Unified haptic feedback
					HapticFeedbackService.shared.medium()

					// Execute action with slight delay for animation
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
						buttonActionCallback()
					}
				}) {
					Image(systemName: systemName)
						.resizable()
						.frame(width: width, height: height)
						.shadow(radius: 20)
						.foregroundColor(universalAccentColor)
				}
				.buttonStyle(PlainButtonStyle())
			)
			.scaleEffect(scale)
			.shadow(
				color: Color.black.opacity(0.15),
				radius: isPressed ? 2 : 8,
				x: 0,
				y: isPressed ? 2 : 4
			)
			.animation(.easeInOut(duration: 0.15), value: scale)
			.animation(.easeInOut(duration: 0.15), value: isPressed)
			.simultaneousGesture(
				DragGesture(minimumDistance: 0)
					.onChanged { _ in
						if !isPressed {
							isPressed = true
							scale = 0.95

							// Additional haptic feedback for press down
							HapticFeedbackService.shared.selection()
						}
					}
					.onEnded { _ in
						isPressed = false
						scale = 1.0
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
