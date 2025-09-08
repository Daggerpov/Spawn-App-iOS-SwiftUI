//
//  AlertTypes.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-19.
//

import Foundation

enum DeleteAccountAlertType: Identifiable {
	case deleteConfirmation
	case deleteSuccess
	case deleteError

	var id: Int {
		switch self {
			case .deleteConfirmation: return 0
			case .deleteSuccess: return 1
			case .deleteError: return 2
		}
	}
}

enum AuthAlertType: Identifiable, Equatable {
	case providerMismatch
	case emailAlreadyInUse
	case createError
	case usernameAlreadyInUse
	case phoneNumberAlreadyInUse
	case emailVerificationFailed
	case tokenExpired
	case providerUnavailable
	case invalidToken
	case networkError
	case unknownError(String)
	case accountFoundSigningIn // New case for graceful OAuth handling
	
	var id: Int {
		switch self {
			case .providerMismatch: return 0
			case .emailAlreadyInUse: return 1
			case .createError: return 2
			case .usernameAlreadyInUse: return 3
			case .phoneNumberAlreadyInUse: return 4
			case .emailVerificationFailed: return 5
			case .tokenExpired: return 6
			case .providerUnavailable: return 7
			case .invalidToken: return 8
			case .networkError: return 9
			case .unknownError: return 10
			case .accountFoundSigningIn: return 11
		}
	}
	
	var title: String {
		switch self {
			case .providerMismatch: 
				return "Sign-in Method Mismatch"
			case .emailAlreadyInUse: 
				return "Email Already in Use"
			case .createError: 
				return "Account Creation Error"
			case .usernameAlreadyInUse:
				return "Username Already Taken"
			case .phoneNumberAlreadyInUse:
				return "Phone Number Already in Use"
			case .emailVerificationFailed:
				return "Email Verification Failed"
			case .tokenExpired:
				return "Session Expired"
			case .providerUnavailable:
				return "Service Temporarily Unavailable"
			case .invalidToken:
				return "Authentication Error"
			case .networkError:
				return "Network Error"
			case .unknownError:
				return "Unexpected Error"
			case .accountFoundSigningIn:
				return "Account Found"
		}
	}
	
	var message: String {
		switch self {
			case .providerMismatch: 
				return "This account was created using a different sign-in method. Please try the other sign-in option."
			case .emailAlreadyInUse: 
				return "This email is already associated with an existing account. Please use a different email or sign in with the account this email is attached to."
			case .createError: 
				return "There was an error creating your account. Please try again later."
			case .usernameAlreadyInUse:
				return "This username is already taken. Please choose a different username."
			case .phoneNumberAlreadyInUse:
				return "This phone number has already been used. Try signing in instead."
			case .emailVerificationFailed:
				return "The email verification code is invalid or has expired. Please request a new verification code."
			case .tokenExpired:
				return "Your session has expired. Please sign in again to continue."
			case .providerUnavailable:
				return "The authentication service is temporarily unavailable. Please try again in a few minutes."
			case .invalidToken:
				return "There was an authentication error. Please try signing in again."
			case .networkError:
				return "Unable to connect to the server. Please check your internet connection and try again."
			case .unknownError(let message):
				// Never show raw error messages to users - always provide friendly alternatives
				return formatUserFriendlyError(message)
			case .accountFoundSigningIn:
				return "We found your existing account and are signing you in automatically."
		}
	}
	
	/// Converts raw error messages into user-friendly alternatives
	private func formatUserFriendlyError(_ rawMessage: String) -> String {
		let lowercased = rawMessage.lowercased()
		
		// Network-related errors
		if lowercased.contains("network") || lowercased.contains("connection") || lowercased.contains("timeout") {
			return "Unable to connect to the server. Please check your internet connection and try again."
		}
		
		// Server errors
		if lowercased.contains("server") || lowercased.contains("internal") || lowercased.contains("500") {
			return "We're experiencing technical difficulties. Please try again in a few moments."
		}
		
		// Authentication errors
		if lowercased.contains("unauthorized") || lowercased.contains("401") || lowercased.contains("forbidden") || lowercased.contains("403") {
			return "Authentication failed. Please try signing in again."
		}
		
		// Validation errors
		if lowercased.contains("validation") || lowercased.contains("invalid") || lowercased.contains("format") {
			return "Please check your information and try again."
		}
		
		// Rate limiting
		if lowercased.contains("rate") || lowercased.contains("limit") || lowercased.contains("429") {
			return "Too many attempts. Please wait a few minutes and try again."
		}
		
		// Generic fallback - never show raw technical errors
		return "We're having trouble processing your request. Please try again."
	}
}
