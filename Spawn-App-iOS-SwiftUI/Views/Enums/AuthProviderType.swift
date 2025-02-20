//
//  AuthProviderType.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-12-30.
//

enum AuthProviderType {
	case google, apple

	var rawValue: String {
		switch self {
		case .google:
			return "google"
		case .apple:
			return "apple"
		}
	}

}
