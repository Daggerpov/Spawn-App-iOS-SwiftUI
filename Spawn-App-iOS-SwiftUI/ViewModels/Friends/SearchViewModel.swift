//
//  SearchViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
	@Published var searchText: String = ""
	@Published var isSearching: Bool = false
	@Published var debouncedSearchText: String = ""

	private var cancellables = Set<AnyCancellable>()

	init() {
		// Set up a debounce mechanism to avoid too many API calls while typing
		$searchText
			.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
			.sink { [weak self] value in
				self?.debouncedSearchText = value
				self?.isSearching = !value.isEmpty
			}
			.store(in: &cancellables)
	}

	func clearSearch() {
		searchText = ""
	}
}
