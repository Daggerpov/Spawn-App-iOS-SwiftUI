//
//  LaunchViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-20.
//

import Foundation

class LaunchViewModel: ObservableObject {
	@Published var user: User?

	var apiService: IAPIService

	init(apiService: IAPIService) {
		self.apiService = apiService
	}
}
