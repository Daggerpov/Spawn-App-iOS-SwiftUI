//
//  AnimatedActionButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Standardizes friend action button animations
//

import SwiftUI

/// Button style variants for friend actions
enum FriendActionButtonStyle {
	case accept
	case remove
	case cancel
	case add

	func title(isActive: Bool) -> String {
		switch self {
		case .accept: return "Accept"
		case .remove: return "Remove"
		case .cancel: return "Cancel"
		case .add: return isActive ? "" : "Add +"
		}
	}

	var normalColor: Color {
		switch self {
		case .accept: return .white
		case .remove, .cancel: return figmaGray700
		case .add: return .white
		}
	}

	var activeColor: Color {
		switch self {
		case .accept: return .white
		case .remove, .cancel, .add: return figmaGreen
		}
	}

	var backgroundColor: (_ isActive: Bool) -> Color {
		return { isActive in
			switch self {
			case .accept:
				return isActive ? Color(hex: colorsIndigo800) : universalSecondaryColor
			case .remove, .cancel:
				return Color.clear
			case .add:
				return universalSecondaryColor
			}
		}
	}

	var borderColor: (_ isActive: Bool) -> Color {
		return { isActive in
			switch self {
			case .accept, .add:
				return Color.clear
			case .remove, .cancel:
				return isActive ? figmaGreen : figmaGray700
			}
		}
	}

	var width: CGFloat {
		switch self {
		case .accept: return 79
		case .remove, .cancel: return 85
		case .add: return 71
		}
	}
}

/// Animated action button with consistent behavior across friend-related actions
/// - Shows checkmark animation
/// - Fades out smoothly
/// - Calls completion handler after animation
struct AnimatedActionButton: View {
	let style: FriendActionButtonStyle
	let delayBeforeFadeOut: UInt64  // nanoseconds
	let fadeOutDuration: UInt64  // nanoseconds
	let onImmediateAction: (() async -> Void)?  // Called immediately when tapped
	let onAnimationComplete: () -> Void  // Called after animation completes

	@State private var isActive = false
	@State private var isFadingOut = false
	@Binding var parentOpacity: CGFloat

	init(
		style: FriendActionButtonStyle,
		delayBeforeFadeOut: UInt64 = 500_000_000,  // 0.5 seconds
		fadeOutDuration: UInt64 = 300_000_000,  // 0.3 seconds
		parentOpacity: Binding<CGFloat> = .constant(1.0),
		onImmediateAction: (() async -> Void)? = nil,
		onAnimationComplete: @escaping () -> Void
	) {
		self.style = style
		self.delayBeforeFadeOut = delayBeforeFadeOut
		self.fadeOutDuration = fadeOutDuration
		self._parentOpacity = parentOpacity
		self.onImmediateAction = onImmediateAction
		self.onAnimationComplete = onAnimationComplete
	}

	var body: some View {
		Button(action: {
			withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
				isActive = true
			}
			Task {
				// Call immediate action if provided (e.g., API call)
				if let immediateAction = onImmediateAction {
					await immediateAction()
				}
				// Add delay before fading out
				try? await Task.sleep(nanoseconds: delayBeforeFadeOut)
				// Fade out animation
				await MainActor.run {
					withAnimation(.easeOut(duration: Double(fadeOutDuration) / 1_000_000_000)) {
						isFadingOut = true
						parentOpacity = 0
					}
				}
				// Wait for fade out to complete
				try? await Task.sleep(nanoseconds: fadeOutDuration)
				// Call completion handler
				onAnimationComplete()
			}
		}) {
			HStack(spacing: 6) {
				if isActive {
					Image(systemName: "checkmark")
						.foregroundColor(style.activeColor)
						.font(.system(size: 14, weight: style == .add ? .regular : .semibold))
						.transition(.scale.combined(with: .opacity))
				}

				let titleText = style.title(isActive: isActive)
				if !titleText.isEmpty {
					Text(titleText)
						.font(.onestMedium(size: 14))
						.foregroundColor(isActive ? style.activeColor : style.normalColor)
						.transition(.scale.combined(with: .opacity))
				}
			}
			.frame(width: style.width, height: 34)
			.background(
				RoundedRectangle(cornerRadius: 8)
					.fill(style.backgroundColor(isActive))
					.overlay(
						RoundedRectangle(cornerRadius: 8)
							.stroke(style.borderColor(isActive), lineWidth: 1)
					)
			)
		}
		.disabled(isActive)
	}
}

/// Container view that applies fade-out animation to its content
/// Use this to wrap friend list rows that need to fade out
struct AnimatedFriendRow<Content: View>: View {
	let content: Content
	@State private var opacity: CGFloat = 1.0

	init(@ViewBuilder content: () -> Content) {
		self.content = content()
	}

	var body: some View {
		content
			.opacity(opacity)
			.environment(\.friendRowOpacity, $opacity)
	}
}

// Environment key for parent opacity
private struct FriendRowOpacityKey: EnvironmentKey {
	static let defaultValue: Binding<CGFloat> = .constant(1.0)
}

extension EnvironmentValues {
	var friendRowOpacity: Binding<CGFloat> {
		get { self[FriendRowOpacityKey.self] }
		set { self[FriendRowOpacityKey.self] = newValue }
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 20) {
		AnimatedActionButton(style: .accept) {
			print("Accept completed")
		}

		AnimatedActionButton(style: .remove) {
			print("Remove completed")
		}

		AnimatedActionButton(style: .cancel) {
			print("Cancel completed")
		}

		AnimatedActionButton(style: .add) {
			print("Add completed")
		}
	}
	.padding()
	.background(universalBackgroundColor)
}
