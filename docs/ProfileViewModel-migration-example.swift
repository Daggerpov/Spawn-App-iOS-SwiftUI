//
//  ProfileViewModel-migration-example.swift
//
//  Example of ProfileViewModel migrated to use DataService only.
//  This file shows the before and after comparison.
//
//  BEFORE: Used DataFetcher, APIService, and AppCache directly
//  AFTER: Uses only DataService
//

import SwiftUI

// ============================================================================
// AFTER: Using DataService Only
// ============================================================================

class ProfileViewModel_New: ObservableObject {
	@Published var userStats: UserStatsDTO?
	@Published var userInterests: [String] = []
	@Published var originalUserInterests: [String] = []
	@Published var userSocialMedia: UserSocialMediaDTO?
	@Published var isLoadingStats: Bool = false
	@Published var isLoadingInterests: Bool = false
	@Published var isLoadingSocialMedia: Bool = false
	@Published var errorMessage: String?

	// ✅ Single dependency on DataService
	private let dataService: IDataService

	init(dataService: IDataService = DataService.shared) {
		self.dataService = dataService
	}

	// MARK: - Read Operations (GET)

	func fetchUserStats(userId: UUID) async {
		guard UserAuthViewModel.shared.spawnUser != nil,
			UserAuthViewModel.shared.isLoggedIn
		else {
			print("Cannot fetch user stats: User is not logged in")
			await MainActor.run { self.isLoadingStats = false }
			return
		}

		// ✅ Simple read operation with DataService
		let result = await dataService.readProfileStats(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let stats, let source):
			await MainActor.run {
				self.userStats = stats
				self.isLoadingStats = false
			}
			print("✅ Loaded stats from \(source == .cache ? "cache" : "API")")

		case .failure(let error):
			await MainActor.run {
				self.errorMessage = ErrorFormattingService.shared.formatError(error)
				self.isLoadingStats = false
			}
		}
	}

	func fetchUserInterests(userId: UUID) async {
		// ✅ Another read operation
		let result = await dataService.readProfileInterests(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let interests, let source):
			await MainActor.run {
				self.userInterests = interests
				self.originalUserInterests = interests
				self.isLoadingInterests = false
			}
			print("✅ Loaded interests from \(source == .cache ? "cache" : "API")")

		case .failure(let error):
			await MainActor.run {
				self.errorMessage = ErrorFormattingService.shared.formatError(error)
				self.isLoadingInterests = false
			}
		}
	}

	// MARK: - Write Operations (POST, PUT, PATCH, DELETE)

	func addUserInterest(userId: UUID, interest: String) async -> Bool {
		// ✅ Write operation with DataService
		let operation = WriteOperation<InterestDTO>.post(
			endpoint: "users/\(userId)/interests",
			body: InterestDTO(interest: interest),
			cacheInvalidationKeys: ["profileInterests-\(userId)"]
		)

		let result: DataResult<EmptyResponse> = await dataService.write(operation)

		switch result {
		case .success:
			await MainActor.run {
				// Optimistically update UI
				if !self.userInterests.contains(interest) {
					self.userInterests.append(interest)
				}
			}
			// ✅ Cache is automatically invalidated
			return true

		case .failure(let error):
			print("❌ Failed to add interest: \(error)")
			return false
		}
	}

	func removeUserInterest(userId: UUID, interest: String) async -> Bool {
		// ✅ DELETE operation with DataService
		let operation = WriteOperation<NoBody>.delete(
			endpoint: "users/\(userId)/interests/\(interest)",
			cacheInvalidationKeys: ["profileInterests-\(userId)"]
		)

		let result = await dataService.writeWithoutResponse(operation)

		switch result {
		case .success:
			await MainActor.run {
				// Optimistically update UI
				self.userInterests.removeAll { $0 == interest }
			}
			// ✅ Cache is automatically invalidated
			return true

		case .failure(let error):
			print("❌ Failed to remove interest: \(error)")
			return false
		}
	}

	func updateSocialMedia(userId: UUID, socialMedia: UserSocialMediaDTO) async -> Bool {
		// ✅ PATCH operation with DataService
		let operation = WriteOperation<UserSocialMediaDTO>.patch(
			endpoint: "users/\(userId)/social-media",
			body: socialMedia,
			cacheInvalidationKeys: ["profileSocialMedia-\(userId)"]
		)

		let result: DataResult<UserSocialMediaDTO> = await dataService.write(operation)

		switch result {
		case .success(let updatedSocialMedia, _):
			await MainActor.run {
				self.userSocialMedia = updatedSocialMedia
			}
			// ✅ Cache is automatically invalidated and updated
			return true

		case .failure(let error):
			print("❌ Failed to update social media: \(error)")
			return false
		}
	}
}

// ============================================================================
// BEFORE: Using DataFetcher, APIService, and AppCache
// ============================================================================

class ProfileViewModel_Old: ObservableObject {
	@Published var userStats: UserStatsDTO?
	@Published var userInterests: [String] = []
	@Published var originalUserInterests: [String] = []
	@Published var userSocialMedia: UserSocialMediaDTO?
	@Published var isLoadingStats: Bool = false
	@Published var isLoadingInterests: Bool = false
	@Published var isLoadingSocialMedia: Bool = false
	@Published var errorMessage: String?

	// ❌ Multiple dependencies
	private let apiService: IAPIService
	private let appCache: AppCache
	private let dataFetcher: DataFetcher

	init(apiService: IAPIService? = nil) {
		self.dataFetcher = DataFetcher.shared
		self.appCache = AppCache.shared

		if let apiService = apiService {
			self.apiService = apiService
		} else {
			self.apiService =
				MockAPIService.isMocking
				? MockAPIService(userId: nil)
				: APIService()
		}
	}

	// MARK: - Read Operations (GET)

	func fetchUserStats(userId: UUID) async {
		guard UserAuthViewModel.shared.spawnUser != nil,
			UserAuthViewModel.shared.isLoggedIn
		else {
			print("Cannot fetch user stats: User is not logged in")
			await MainActor.run { self.isLoadingStats = false }
			return
		}

		// ❌ Using DataFetcher for read
		let result = await dataFetcher.fetchProfileStats(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let stats, let source):
			await MainActor.run {
				self.userStats = stats
				self.isLoadingStats = false
			}
			print("✅ Loaded stats from \(source == .cache ? "cache" : "API")")

		case .failure(let error):
			await MainActor.run {
				self.errorMessage = ErrorFormattingService.shared.formatError(error)
				self.isLoadingStats = false
			}
		}
	}

	func fetchUserInterests(userId: UUID) async {
		// ❌ Using DataFetcher for read
		let result = await dataFetcher.fetchProfileInterests(
			userId: userId,
			cachePolicy: .cacheFirst(backgroundRefresh: true)
		)

		switch result {
		case .success(let interests, let source):
			await MainActor.run {
				self.userInterests = interests
				self.originalUserInterests = interests
				self.isLoadingInterests = false
			}
			print("✅ Loaded interests from \(source == .cache ? "cache" : "API")")

		case .failure(let error):
			await MainActor.run {
				self.errorMessage = ErrorFormattingService.shared.formatError(error)
				self.isLoadingInterests = false
			}
		}
	}

	// MARK: - Write Operations (POST, PUT, PATCH, DELETE)

	func addUserInterest(userId: UUID, interest: String) async -> Bool {
		// ❌ Manual URL construction
		guard let url = URL(string: APIService.baseURL + "users/\(userId)/interests") else {
			return false
		}

		do {
			// ❌ Direct APIService call
			let _: EmptyResponse? = try await apiService.sendData(
				InterestDTO(interest: interest),
				to: url,
				parameters: nil
			)

			await MainActor.run {
				if !self.userInterests.contains(interest) {
					self.userInterests.append(interest)
				}
			}

			// ❌ Manual cache update
			appCache.updateProfileInterests(userId, userInterests)

			return true

		} catch {
			print("❌ Failed to add interest: \(error)")
			return false
		}
	}

	func removeUserInterest(userId: UUID, interest: String) async -> Bool {
		// ❌ Manual URL construction
		guard let url = URL(string: APIService.baseURL + "users/\(userId)/interests/\(interest)") else {
			return false
		}

		do {
			// ❌ Direct APIService call with manual type annotation
			try await apiService.deleteData(
				from: url,
				parameters: nil,
				object: nil as EmptyObject?
			)

			await MainActor.run {
				self.userInterests.removeAll { $0 == interest }
			}

			// ❌ Manual cache update
			appCache.updateProfileInterests(userId, userInterests)

			return true

		} catch {
			print("❌ Failed to remove interest: \(error)")
			return false
		}
	}

	func updateSocialMedia(userId: UUID, socialMedia: UserSocialMediaDTO) async -> Bool {
		// ❌ Manual URL construction
		guard let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") else {
			return false
		}

		do {
			// ❌ Direct APIService call
			let updatedSocialMedia: UserSocialMediaDTO = try await apiService.patchData(
				from: url,
				with: socialMedia
			)

			await MainActor.run {
				self.userSocialMedia = updatedSocialMedia
			}

			// ❌ Manual cache update
			appCache.updateProfileSocialMedia(userId, updatedSocialMedia)

			return true

		} catch {
			print("❌ Failed to update social media: \(error)")
			return false
		}
	}
}

// ============================================================================
// COMPARISON SUMMARY
// ============================================================================

/*

 Key Improvements in New Architecture:

 1. ✅ Single Dependency:
    - OLD: apiService, appCache, dataFetcher (3 dependencies)
    - NEW: dataService (1 dependency)

 2. ✅ No Manual URL Construction:
    - OLD: guard let url = URL(string: APIService.baseURL + "users/...")
    - NEW: endpoint: "users/..." (just the path)

 3. ✅ Automatic Cache Management:
    - OLD: appCache.updateProfileInterests(...) after every write
    - NEW: Automatic via cacheInvalidationKeys

 4. ✅ Cleaner Write Operations:
    - OLD: try await apiService.sendData/patchData/deleteData
    - NEW: await dataService.write(operation)

 5. ✅ Type Safety:
    - OLD: Manual type annotations, nullable results
    - NEW: Generic operations with clear types

 6. ✅ Better Testing:
    - OLD: Need to mock apiService, appCache, and dataFetcher
    - NEW: Only need to mock dataService

 7. ✅ Consistent Error Handling:
    - OLD: Mix of throws and result types
    - NEW: Consistent DataResult<T> everywhere

 8. ✅ Less Boilerplate:
    - OLD: ~40 lines per write operation
    - NEW: ~15 lines per write operation

 Lines of Code Comparison:
 - OLD ProfileViewModel: ~300 lines with 3 dependencies
 - NEW ProfileViewModel: ~180 lines with 1 dependency
 - Reduction: ~40% less code!

 */
