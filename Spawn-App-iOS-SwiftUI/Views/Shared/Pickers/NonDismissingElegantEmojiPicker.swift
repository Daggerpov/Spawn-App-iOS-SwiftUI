import ElegantEmojiPicker
import SwiftUI

// Custom subclass to prevent auto-dismissal
@MainActor
final class NonDismissingElegantEmojiPicker: ElegantEmojiPicker {
	var onManualDismiss: (@MainActor () -> Void)?
	private var allowDismissal = false

	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		if allowDismissal {
			print("DEBUG: Allowing manual dismissal")
			super.dismiss(animated: flag, completion: completion)
		} else {
			print("DEBUG: Prevented automatic dismissal of emoji picker")
			completion?()
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		print("DEBUG: NonDismissingElegantEmojiPicker loaded")
	}

	// Allow manual dismissal through this method
	func manualDismiss() {
		print("DEBUG: Manual dismissal triggered")
		allowDismissal = true
		onManualDismiss?()
	}

	// Override other potential dismissal methods
	override func viewDidDisappear(_ animated: Bool) {
		if allowDismissal {
			super.viewDidDisappear(animated)
		} else {
			print("DEBUG: Prevented viewDidDisappear")
		}
	}
}
