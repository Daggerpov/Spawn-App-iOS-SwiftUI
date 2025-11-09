import Foundation

struct InputFieldState {
	var hasError: Bool = false
	var errorMessage: String? = nil

	mutating func setError(_ message: String) {
		hasError = true
		errorMessage = message
	}

	mutating func clearError() {
		hasError = false
		errorMessage = nil
	}
}
