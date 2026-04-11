import Combine
import SwiftUI
import UIKit

/// Tracks how much of the screen bottom is covered by the keyboard (screen coordinates).
/// Use when ancestors apply `.ignoresSafeArea(.keyboard)` so system avoidance does not run.
final class KeyboardOverlapHeight: ObservableObject {
	@Published var value: CGFloat = 0

	private var observers: [NSObjectProtocol] = []

	init() {
		let center = NotificationCenter.default
		observers.append(
			center.addObserver(forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main) {
				[weak self] notification in
				self?.update(from: notification)
			}
		)
		observers.append(
			center.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) {
				[weak self] notification in
				self?.update(from: notification)
			}
		)
	}

	deinit {
		observers.forEach { NotificationCenter.default.removeObserver($0) }
	}

	private func update(from notification: Notification) {
		guard
			let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
		else {
			return
		}

		let screenHeight = UIScreen.main.bounds.height
		let overlap = max(0, screenHeight - frame.minY)

		let duration =
			(notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
			?? 0.25

		withAnimation(.easeOut(duration: duration)) {
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
