//
//  TutorialOverlayView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import SwiftUI

struct ActivityTypesFrameKey: PreferenceKey {
	static var defaultValue: CGRect = .zero
	static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
		value = nextValue()
	}
}

struct TutorialOverlayView: View {
	var tutorialViewModel = TutorialViewModel.shared
	@Environment(\.colorScheme) var colorScheme

	let activityTypesFrame: CGRect?
	let headerFrame: CGRect?

	@State private var showCallout = false

	private let cutoutPadding: CGFloat = 12
	private let cutoutCornerRadius: CGFloat = 16
	private let calloutGap: CGFloat = 14

	init(activityTypesFrame: CGRect? = nil, headerFrame: CGRect? = nil) {
		self.activityTypesFrame = activityTypesFrame
		self.headerFrame = headerFrame
	}

	var body: some View {
		ZStack {
			if tutorialViewModel.tutorialState.shouldShowTutorialOverlay {
				GeometryReader { _ in
					ZStack(alignment: .top) {
						overlayWithCutout

						if showCallout && tutorialViewModel.shouldShowCallout,
							let frame = activityTypesFrame, frame != .zero
						{
							calloutView
								.padding(.top, frame.maxY + cutoutPadding + calloutGap)
								.allowsHitTesting(false)
								.transition(
									.asymmetric(
										insertion: .move(edge: .top).combined(with: .opacity),
										removal: .opacity
									)
								)
						}
					}
				}
				.ignoresSafeArea()
				.onTapGesture {}
			}
		}
		.onAppear {
			if tutorialViewModel.tutorialState.shouldShowTutorialOverlay {
				Task { @MainActor in
					try? await Task.sleep(for: .seconds(0.5))
					withAnimation(.easeOut(duration: 0.4)) {
						showCallout = true
					}
				}
			}
		}
		.onChange(of: tutorialViewModel.tutorialState) { _, newState in
			if !newState.shouldShowTutorialOverlay {
				withAnimation(.easeInOut(duration: 0.3)) {
					showCallout = false
				}
			}
		}
	}

	@ViewBuilder
	private var overlayWithCutout: some View {
		if let frame = activityTypesFrame, frame != .zero {
			TutorialCutoutShape(
				cutoutRect: CGRect(
					x: frame.origin.x - cutoutPadding,
					y: frame.origin.y - cutoutPadding,
					width: frame.width + cutoutPadding * 2,
					height: frame.height + cutoutPadding * 2
				),
				cornerRadius: cutoutCornerRadius
			)
			.fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
		} else {
			Color.black.opacity(0.6)
		}
	}

	private var calloutView: some View {
		VStack(spacing: 0) {
			CalloutTriangle()
				.fill(Color.white)
				.frame(width: 24, height: 14)

			Text(
				"Welcome to Spawn! Tap on an Activity Type to create your first activity."
			)
			.font(.onestMedium(size: 16))
			.foregroundColor(Color(red: 0.23, green: 0.22, blue: 0.22))
			.multilineTextAlignment(.center)
			.padding(.horizontal, 24)
			.padding(.vertical, 20)
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 16)
					.fill(Color.white)
					.shadow(
						color: Color.black.opacity(0.1),
						radius: 8,
						x: 0,
						y: 4
					)
			)
		}
		.padding(.horizontal, 24)
	}
}

private struct TutorialCutoutShape: Shape {
	let cutoutRect: CGRect
	let cornerRadius: CGFloat

	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.addRect(rect)
		path.addRoundedRect(
			in: cutoutRect,
			cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
		)
		return path
	}
}

private struct CalloutTriangle: Shape {
	func path(in rect: CGRect) -> Path {
		var path = Path()
		path.move(to: CGPoint(x: rect.midX, y: rect.minY))
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
		path.closeSubpath()
		return path
	}
}
