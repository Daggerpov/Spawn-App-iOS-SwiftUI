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

enum AuthAlertType: Identifiable {
	case providerMismatch
	case emailAlreadyInUse
	case createError
	
	var id: Int {
		switch self {
			case .providerMismatch: return 0
			case .emailAlreadyInUse: return 1
			case .createError: return 2
		}
	}
	
	var title: String {
		switch self {
			case .providerMismatch: 
				return "Authentication Error"
			case .emailAlreadyInUse: 
				return "Email Already in Use"
			case .createError: 
				return "Account Creation Error"
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
		}
	}
}
