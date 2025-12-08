//
//  VerificationCodeViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-28.
//

import Foundation

@Observable
@MainActor
final class VerificationCodeViewModel {
	var code: [String] = Array(repeating: "", count: 6)
	var previousCode: [String] = Array(repeating: "", count: 6)
	var focusedIndex: Int? = 0
	var secondsRemaining: Int = 30
	var isResendEnabled: Bool = false

	/// Timer for countdown - uses weak self pattern in callbacks
	/// - Note: `nonisolated(unsafe)` allows safe access from nonisolated deinit.
	/// Thread safety is ensured by only accessing from MainActor context (via Timer's main runloop)
	/// and in deinit (which runs after all other accesses complete).
	@ObservationIgnored private nonisolated(unsafe) var timer: Timer?
	private var userAuthViewModel: UserAuthViewModel

	var isFormValid: Bool {
		code.allSatisfy { $0.count == 1 && $0.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil }
	}

	var codeString: String {
		code.joined()
	}

	init(userAuthViewModel: UserAuthViewModel) {
		self.userAuthViewModel = userAuthViewModel
	}

	deinit {
		// Safe to access nonisolated(unsafe) timer here - deinit runs after all references are released
		timer?.invalidate()
		timer = nil
	}

	// MARK: - Timer Management

	func startTimer() {
		secondsRemaining = userAuthViewModel.secondsUntilNextVerificationAttempt
		isResendEnabled = false
		stopTimer()

		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
			guard let self = self else { return }

			// Dispatch to main actor since Timer callback is @Sendable
			Task { @MainActor in
				if self.secondsRemaining > 0 {
					self.secondsRemaining -= 1
				}

				if self.secondsRemaining == 0 {
					self.isResendEnabled = true
					self.stopTimer()
				}
			}
		}
	}

	func stopTimer() {
		timer?.invalidate()
		timer = nil
	}

	// MARK: - Code Input Management

	func handleTextFieldChange(at index: Int, oldValue: String, newValue: String) {
		// Handle forward navigation when a character is entered
		if oldValue.isEmpty && !newValue.isEmpty {
			// New character entered, move to next field
			if index < 5 {
				focusedIndex = index + 1
			}
		}
	}

	func handleBackspace(at index: Int) {
		// Move focus to previous field when backspace is pressed
		if index > 0 {
			focusedIndex = index - 1
		}
	}

	func handlePaste(pastedText: String, startingAt startIndex: Int) {
		// Filter to only digits
		let digits = pastedText.filter { $0.isNumber }
		let digitArray = Array(digits)

		// Only handle if we have digits
		guard !digitArray.isEmpty else { return }

		// Clear all boxes first
		code = Array(repeating: "", count: 6)
		previousCode = Array(repeating: "", count: 6)

		// Fill boxes with pasted digits starting from the beginning
		for (i, digit) in digitArray.enumerated() {
			if i < 6 {
				code[i] = String(digit)
				previousCode[i] = String(digit)
			}
		}

		// Move focus to the next empty box or the last filled box
		let nextIndex = min(digitArray.count, 5)
		focusedIndex = nextIndex
	}

	func initialize() {
		focusedIndex = 0
		previousCode = code
		startTimer()
	}

	func clearCode() {
		code = Array(repeating: "", count: 6)
		previousCode = Array(repeating: "", count: 6)
		focusedIndex = 0
	}

	// MARK: - API Actions

	func verifyCode() async {
		guard let email = userAuthViewModel.email else { return }
		await userAuthViewModel.verifyEmailCode(email: email, code: codeString)
	}

	func resendCode() async {
		guard let email = userAuthViewModel.email else { return }
		await userAuthViewModel.sendEmailVerification(email: email)

		// The timer will be updated with the new seconds from the backend response
		await MainActor.run {
			startTimer()
		}
	}
}
