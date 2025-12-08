//
//  SearchViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2024-11-19.
//

@preconcurrency import Combine
import Foundation
import SwiftUI

@Observable
@MainActor
final class SearchViewModel {
	var searchText: String = "" {
		didSet {
			searchTextSubject.send(searchText)
		}
	}
	var isSearching: Bool = false
	var debouncedSearchText: String = ""

	// Keep Combine for debouncing - this is a valid use case
	private let searchTextSubject = PassthroughSubject<String, Never>()
	private var cancellables = Set<AnyCancellable>()

	// Published property for external Combine subscriptions (e.g., FriendsTabViewModel)
	var debouncedSearchTextPublisher: AnyPublisher<String, Never> {
		searchTextSubject
			.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
			.eraseToAnyPublisher()
	}

	init() {
		// Set up a debounce mechanism to avoid too many API calls while typing
		searchTextSubject
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
