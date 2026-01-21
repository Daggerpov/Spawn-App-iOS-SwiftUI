//
//  AuthProviderType.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

enum AuthProviderType {
	case google, apple, email

	var rawValue: String {
		switch self {
		case .google:
			return "google"
		case .apple:
			return "apple"
		case .email:
			return "email"
		}
	}

	init?(rawValue: String) {
		switch rawValue.lowercased() {
		case "google":
			self = .google
		case "apple":
			self = .apple
		case "email":
			self = .email
		default:
			return nil
		}
	}
}
