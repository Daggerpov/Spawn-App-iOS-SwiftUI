//
//  DeleteAccountAlertType.swift
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
