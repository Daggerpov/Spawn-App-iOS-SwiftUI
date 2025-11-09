//
//  NavigationState.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Assistant on 1/21/25.
//

import Foundation

/// Master enum representing all possible navigation states in the app
/// This replaces multiple boolean navigation flags to prevent concurrent navigation updates
enum NavigationState: Equatable, Hashable {
	// Auth Flow States
	case welcome
	case spawnIntro
	case signIn
	case register
	case loginInput
	case accountNotFound
	case onboardingContinuation

	// Onboarding States
	case userDetailsInput(isOAuthUser: Bool = false)
	case userOptionalDetailsInput
	case contactImport
	case userTermsOfService
	case phoneNumberInput
	case verificationCode

	// Main App States
	case feedView
	case none  // Default/no navigation state

	var description: String {
		switch self {
		case .welcome:
			return "Welcome"
		case .spawnIntro:
			return "Spawn Intro"
		case .signIn:
			return "Sign In"
		case .register:
			return "Register"
		case .loginInput:
			return "Login Input"
		case .accountNotFound:
			return "Account Not Found"
		case .onboardingContinuation:
			return "Onboarding Continuation"
		case .userDetailsInput(let isOAuthUser):
			return "User Details Input (OAuth: \(isOAuthUser))"
		case .userOptionalDetailsInput:
			return "User Optional Details Input"
		case .contactImport:
			return "Contact Import"
		case .userTermsOfService:
			return "Terms of Service"
		case .phoneNumberInput:
			return "Phone Number Input"
		case .verificationCode:
			return "Verification Code"
		case .feedView:
			return "Feed View"
		case .none:
			return "None"
		}
	}
}
