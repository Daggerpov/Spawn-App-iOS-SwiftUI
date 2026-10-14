import SwiftUI
import UIKit

/// Tracks how much of the screen bottom is covered by the keyboard (screen coordinates).
/// Use when ancestors apply `.ignoresSafeArea(.keyboard)` so system avoidance does not run.
/// `ObservableObject` updates and notification handlers run on the main queue only.
final class KeyboardOverlapHeight: ObservableObject, @unchecked Sendable {
	@Published var value: CGFloat = 0

	private var observers: [NSObjectProtocol] = []

	init() {
		let center = NotificationCenter.default
		observers.append(
			center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) {
				[weak self] notification in
				let (frame, duration) = Self.keyboardFrameValues(from: notification)
				// `queue: .main` runs on the main queue; only Sendable values cross into MainActor work.
				MainActor.assumeIsolated {
					self?.applyKeyboardFrame(frame: frame, animationDuration: duration)
				}
			}
		)
		observers.append(
			center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) {
				[weak self] notification in
				let (frame, duration) = Self.keyboardFrameValues(from: notification)
				MainActor.assumeIsolated {
					self?.applyKeyboardFrame(frame: frame, animationDuration: duration)
				}
			}
		)
	}

	private static func keyboardFrameValues(from notification: Notification) -> (frame: CGRect?, duration: Double) {
		let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
		let duration =
			(notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
			?? 0.25
		return (frame, duration)
	}

	deinit {
		observers.forEach { NotificationCenter.default.removeObserver($0) }
	}

	@MainActor
	private func applyKeyboardFrame(frame: CGRect?, animationDuration: Double) {
		guard let frame else { return }

		let screenHeight = UIScreen.main.bounds.height
		let overlap = max(0, screenHeight - frame.minY)

		withAnimation(.easeOut(duration: animationDuration)) {
			value = overlap
		}
	}
}

extension View {
	/// Bottom padding matching on-screen keyboard overlap (for views under `.ignoresSafeArea(.keyboard)`).
	func keyboardOverlapPadding(_ keyboard: KeyboardOverlapHeight) -> some View {
		padding(.bottom, keyboard.value)
	}
}
