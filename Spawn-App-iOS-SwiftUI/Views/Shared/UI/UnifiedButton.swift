//
//  UnifiedButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring - Consolidates Enhanced3DButton, ActivityNextStepButton, and OnboardingButton variants

import SwiftUI

/// Button style options
enum ButtonVariant {
	case primary
	case secondary
	case tertiary
	case outline
	case custom(backgroundColor: Color, foregroundColor: Color, borderColor: Color?)
}

/// Unified button component with consistent styling, haptic feedback, and animations
struct UnifiedButton: View {
	let title: String
	let variant: ButtonVariant
	let isEnabled: Bool
	let action: () -> Void

	// Animation states
	@State private var isPressed = false
	@State private var scale: CGFloat = 1.0

	init(
		_ title: String,
		variant: ButtonVariant = .primary,
		isEnabled: Bool = true,
		action: @escaping () -> Void
	) {
		self.title = title
		self.variant = variant
		self.isEnabled = isEnabled
		self.action = action
	}

	var body: some View {
		Button(action: {
			// Unified haptic feedback
			HapticFeedbackService.shared.medium()

			// Execute action with slight delay for animation
			Task { @MainActor in
				try? await Task.sleep(for: .seconds(0.1))
				action()
			}
		}) {
			HStack(alignment: .center, spacing: 8) {
				Text(title)
					.font(.onestSemiBold(size: 20))
					.foregroundColor(foregroundColor)
					.lineLimit(1)
					.allowsTightening(true)
			}
			.padding(.vertical, 18)
			.padding(.horizontal, 16)
			.frame(maxWidth: .infinity, minHeight: 56)
			.background(isEnabled ? backgroundColor : disabledBackgroundColor)
			.cornerRadius(16)
			.overlay(
				RoundedRectangle(cornerRadius: 16)
					.stroke(borderColor, lineWidth: borderWidth)
			)
			.scaleEffect(scale)
			.shadow(
				color: isEnabled ? Color.black.opacity(0.15) : Color.clear,
				radius: isPressed ? 2 : 8,
				x: 0,
				y: isPressed ? 2 : 4
			)
		}
		.buttonStyle(PlainButtonStyle())
		.disabled(!isEnabled)
		.opacity(isEnabled ? 1.0 : 0.8)
		.animation(.easeInOut(duration: 0.15), value: scale)
		.animation(.easeInOut(duration: 0.15), value: isPressed)
		.simultaneousGesture(
			DragGesture(minimumDistance: 0)
				.onChanged { _ in
					if !isPressed && isEnabled {
						isPressed = true
						scale = 0.95
						HapticFeedbackService.shared.selection()
					}
				}
				.onEnded { _ in
					isPressed = false
					scale = 1.0
				}
		)
	}

	// MARK: - Computed Properties

	private var backgroundColor: Color {
		switch variant {
		case .primary:
			return figmaSoftBlue
		case .secondary:
			return figmaLightGrey
		case .tertiary:
			return Color.clear
		case .outline:
			return Color.clear
		case .custom(let bgColor, _, _):
			return bgColor
		}
	}

	private var foregroundColor: Color {
		switch variant {
		case .primary:
			return .white
		case .secondary:
			return universalAccentColor
		case .tertiary:
			return universalAccentColor
		case .outline:
			return universalAccentColor
		case .custom(_, let fgColor, _):
			return fgColor
		}
	}

	private var borderColor: Color {
		switch variant {
		case .outline:
			return universalAccentColor
		case .custom(_, _, let border):
			return border ?? Color.clear
		default:
			return Color.clear
		}
	}

	private var borderWidth: CGFloat {
		switch variant {
		case .outline:
			return 1
		case .custom(_, _, let border):
			return border != nil ? 1 : 0
		default:
			return 0
		}
	}

	private var disabledBackgroundColor: Color {
		return Color.gray.opacity(0.3)
	}
}

// MARK: - Convenience Initializers

extension UnifiedButton {
	/// Create a primary button (blue background, white text)
	static func primary(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> UnifiedButton {
		UnifiedButton(title, variant: .primary, isEnabled: isEnabled, action: action)
	}

	/// Create a secondary button (light grey background)
	static func secondary(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> UnifiedButton {
		UnifiedButton(title, variant: .secondary, isEnabled: isEnabled, action: action)
	}

	/// Create an outline button (transparent with border)
	static func outline(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) -> UnifiedButton {
		UnifiedButton(title, variant: .outline, isEnabled: isEnabled, action: action)
	}
}

@available(iOS 17, *)
#Preview {
	VStack(spacing: 20) {
		UnifiedButton.primary("Primary Button") {
			print("Primary tapped")
		}

		UnifiedButton.secondary("Secondary Button") {
			print("Secondary tapped")
		}

		UnifiedButton.outline("Outline Button") {
			print("Outline tapped")
		}

		UnifiedButton.primary("Disabled Button", isEnabled: false) {
			print("Should not print")
		}
	}
	.padding()
	.background(universalBackgroundColor)
}
