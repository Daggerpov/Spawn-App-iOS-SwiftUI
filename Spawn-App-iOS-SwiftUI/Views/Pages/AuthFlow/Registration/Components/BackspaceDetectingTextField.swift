import SwiftUI
import UIKit

struct BackspaceDetectingTextField: UIViewRepresentable {
	@Binding var text: String
	let onBackspace: () -> Void
	let onPaste: ((String) -> Void)?
	var keyboardType: UIKeyboardType = .numberPad
	var textAlignment: NSTextAlignment = .center
	var font: UIFont = UIFont.systemFont(ofSize: 24)
	var textColor: UIColor = .label

	func makeUIView(context: Context) -> UITextField {
		let textField = UITextField()
		textField.delegate = context.coordinator
		textField.keyboardType = keyboardType
		textField.textAlignment = textAlignment
		textField.font = font
		textField.textColor = textColor
		textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange), for: .editingChanged)
		return textField
	}

	func updateUIView(_ uiView: UITextField, context: Context) {
		if uiView.text != text {
			uiView.text = text
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, UITextFieldDelegate {
		let parent: BackspaceDetectingTextField

		init(_ parent: BackspaceDetectingTextField) {
			self.parent = parent
		}

		@objc func textDidChange(_ textField: UITextField) {
			parent.text = textField.text ?? ""
		}

		func textField(
			_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String
		) -> Bool {
			let currentText = textField.text ?? ""

			// Detect backspace (replacement string is empty)
			if string.isEmpty {
				if currentText.isEmpty {
					// Backspace on empty field - move to previous field
					parent.onBackspace()
					return false
				} else {
					// Backspace on non-empty field - clear current field and move to previous
					DispatchQueue.main.async {
						self.parent.text = ""
						self.parent.onBackspace()
					}
					return false
				}
			}

			// Check if this is a paste operation (multiple characters)
			if string.count > 1 {
				// Filter to only digits
				let digits = string.filter { $0.isNumber }
				if !digits.isEmpty {
					parent.onPaste?(digits)
				}
				return false
			}

			// Only allow single digits for regular input
			if string.count == 1 && string.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) != nil {
				return false
			}

			// Only allow single character
			if currentText.count >= 1 && !string.isEmpty {
				return false
			}

			return true
		}
	}
}
