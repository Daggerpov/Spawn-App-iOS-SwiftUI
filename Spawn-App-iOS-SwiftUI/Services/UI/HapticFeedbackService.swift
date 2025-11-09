//
//  HapticFeedbackService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created for DRY refactoring

import UIKit

/// Centralized haptic feedback service to eliminate duplicate UIImpactFeedbackGenerator code
final class HapticFeedbackService {
	static let shared = HapticFeedbackService()

	private init() {}

	/// Trigger a light haptic feedback
	func light() {
		let generator = UIImpactFeedbackGenerator(style: .light)
		generator.impactOccurred()
	}

	/// Trigger a medium haptic feedback (default for most interactions)
	func medium() {
		let generator = UIImpactFeedbackGenerator(style: .medium)
		generator.impactOccurred()
	}

	/// Trigger a heavy haptic feedback
	func heavy() {
		let generator = UIImpactFeedbackGenerator(style: .heavy)
		generator.impactOccurred()
	}

	/// Trigger a selection changed feedback
	func selection() {
		let generator = UISelectionFeedbackGenerator()
		generator.selectionChanged()
	}

	/// Trigger a success notification feedback
	func success() {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(.success)
	}

	/// Trigger a warning notification feedback
	func warning() {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(.warning)
	}

	/// Trigger an error notification feedback
	func error() {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(.error)
	}
}
