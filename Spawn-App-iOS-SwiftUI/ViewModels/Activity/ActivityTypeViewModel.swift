//
//  ActivityTypeViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude on 2025-01-28.
//

import Foundation
import Combine

class ActivityTypeViewModel: ObservableObject {
    @Published var activityTypes: [ActivityTypeDTO] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let apiService: IAPIService
    private let userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private enum APIEndpoints {
        static func activityTypes(userId: UUID) -> String {
            return "users/\(userId)/activity-types"
        }
    }
    
    // MARK: - Helper Methods
    
    /// Constructs a URL for the activity types endpoint
    private func buildActivityTypesURL() -> URL? {
        let endpoint = APIEndpoints.activityTypes(userId: userId)
        return URL(string: APIService.baseURL + endpoint)
    }
    
    /// Sets loading state
    @MainActor
    private func setLoadingState(_ loading: Bool, error: String? = nil) {
        isLoading = loading
        errorMessage = error
    }
    
	/// Updates local state and cache after successful API call
	@MainActor
	private func updateStateAfterAPISuccess(_ updatedTypes: [ActivityTypeDTO]) {
		self.activityTypes = updatedTypes
		appCache.updateActivityTypes(updatedTypes)
		NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
	}
    
    init(
        userId: UUID,
        apiService: IAPIService? = nil
    ) {
        self.userId = userId
        self.appCache = AppCache.shared
        
        if let apiService = apiService {
            self.apiService = apiService
        } else {
            self.apiService = MockAPIService.isMocking
                ? MockAPIService(userId: userId) : APIService()
        }
        
        // Subscribe to cache updates if not mocking
        if !MockAPIService.isMocking {
            // Subscribe to cached activity types updates
            appCache.activityTypesPublisher
                .sink { [weak self] cachedActivityTypes in
                    if !cachedActivityTypes.isEmpty {
                        self?.activityTypes = cachedActivityTypes
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Backend API Methods
    
    /// Loads cached activity types immediately (synchronous, fast, non-blocking)
    /// Call this before fetchActivityTypes() to show cached data instantly
    @MainActor
    func loadCachedActivityTypes() {
        let cachedTypes = appCache.activityTypes
        if !cachedTypes.isEmpty {
            self.activityTypes = cachedTypes
            print("✅ ActivityTypeViewModel: Loaded \(cachedTypes.count) activity types from cache")
        } else {
            print("⚠️ ActivityTypeViewModel: No cached activity types available")
        }
    }
    
    /// Fetches all activity types for the user from the backend or cache
    @MainActor
    func fetchActivityTypes(forceRefresh: Bool = false) async {
        // Check if user is still authenticated before making API call
        guard UserAuthViewModel.shared.spawnUser != nil, UserAuthViewModel.shared.isLoggedIn else {
            print("Cannot fetch activity types: User is not logged in")
            return
        }
        
        // First, try to load from cache if not forcing a refresh
        if !forceRefresh {
            let cachedTypes = appCache.activityTypes
            if !cachedTypes.isEmpty {
                // Use cached data immediately - no loading state needed!
                self.activityTypes = cachedTypes
                return
            }
        }
        
        // Cache is empty or force refresh requested - show loading and fetch
        await fetchActivityTypesFromAPI()
    }
    
    /// Internal method to fetch from API with loading state
    @MainActor
    private func fetchActivityTypesFromAPI() async {
        setLoadingState(true)
        defer { setLoadingState(false) }
        
        do {
            guard let url = buildActivityTypesURL() else {
                setLoadingState(false, error: "Invalid URL")
                return
            }
            
            let fetchedTypes: [ActivityTypeDTO] = try await apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            self.activityTypes = fetchedTypes
            appCache.updateActivityTypes(fetchedTypes)
            
		} catch let error as APIError {
			print("❌ Error fetching activity types: \(error)")
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
		}
    }
    

    
    // MARK: - Local State Manipulation Methods
    
    /// Toggles the pin status of an activity type via direct API call
    @MainActor
    func togglePin(for activityTypeDTO: ActivityTypeDTO) async {
        let currentPinnedCount = activityTypes.filter { $0.isPinned }.count
        let isCurrentlyPinned = activityTypeDTO.isPinned
        let willBePinned = !isCurrentlyPinned
        
        // Debug logging
        print("🔄 Toggle pin for '\(activityTypeDTO.title)':")
        print("   Currently pinned: \(isCurrentlyPinned)")
        print("   Will be pinned: \(willBePinned)")
        print("   Current pinned count: \(currentPinnedCount)")
        print("   Current pinned items: \(activityTypes.filter { $0.isPinned }.map { $0.title })")
        
        // Check if we're already at the pin limit when trying to pin (not when unpinning)
        if willBePinned {
            if currentPinnedCount >= 4 {
                print("❌ Cannot pin: Already at maximum of 4 pinned activity types")
                await MainActor.run {
                    errorMessage = "You can only pin up to 4 activity types"
                }
                return
            }
        }
        
        let updatedActivityType = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: activityTypeDTO.title,
            icon: activityTypeDTO.icon,
            associatedFriends: activityTypeDTO.associatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: willBePinned
        )
        
        await updateActivityType(updatedActivityType)
    }
    
    /// Deletes an activity type via direct API call
    @MainActor
    func deleteActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        setLoadingState(true)
        
        defer { setLoadingState(false) }
        
        do {
            guard let url = buildActivityTypesURL() else {
                setLoadingState(false, error: "Invalid URL")
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [],
                deletedActivityTypeIds: [activityTypeDTO.id]
            )
            
            let updatedActivityTypes: [ActivityTypeDTO] = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            updateStateAfterAPISuccess(updatedActivityTypes)
            
			print("✅ Successfully deleted activity type: \(activityTypeDTO.title)")
			
		} catch let error as APIError {
			print("❌ Error deleting activity type: \(error)")
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
		}
    }
    
    /// Creates a new activity type via direct API call
    @MainActor
    func createActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        setLoadingState(true)
        
        defer { setLoadingState(false) }
        
        do {
            guard let url = buildActivityTypesURL() else {
                setLoadingState(false, error: "Invalid URL")
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [activityTypeDTO],
                deletedActivityTypeIds: []
            )
            
            let updatedActivityTypes: [ActivityTypeDTO] = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            updateStateAfterAPISuccess(updatedActivityTypes)
            
			print("✅ Successfully created activity type: \(activityTypeDTO.title)")
			
		} catch let error as APIError {
			print("❌ Error creating activity type: \(error)")
			errorMessage = ErrorFormattingService.shared.formatAPIError(error)
		} catch {
			errorMessage = ErrorFormattingService.shared.formatError(error)
		}
    }
    
    /// Removes a friend from an activity type
    @MainActor
    func removeFriendFromActivityType(activityTypeId: UUID, friendId: UUID) async {
        guard let activityType = activityTypes.first(where: { $0.id == activityTypeId }) else {
            errorMessage = "Activity type not found"
            return
        }
        
        // Create updated activity type with friend removed
        let updatedAssociatedFriends = activityType.associatedFriends.filter { $0.id != friendId }
        
        let updatedActivityType = ActivityTypeDTO(
            id: activityType.id,
            title: activityType.title,
            icon: activityType.icon,
            associatedFriends: updatedAssociatedFriends,
            orderNum: activityType.orderNum,
            isPinned: activityType.isPinned
        )
        
        await updateActivityType(updatedActivityType)
    }
    
    /// Updates an existing activity type via direct API call
    @MainActor
    func updateActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        
        setLoadingState(true)
        
        defer { setLoadingState(false) }
        
        do {
            guard let url = buildActivityTypesURL() else {
                print("❌ Invalid URL for activity types endpoint")
                setLoadingState(false, error: "Invalid URL")
                return
            }
            
            print("📡 Making API call to: \(url.absoluteString)")
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [activityTypeDTO],
                deletedActivityTypeIds: []
            )
            
            let updatedActivityTypes: [ActivityTypeDTO] = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            updateStateAfterAPISuccess(updatedActivityTypes)
            
		} catch let error as APIError {
			print("❌ Error updating activity type: \(error)")
			print("❌ Error details: \(ErrorFormattingService.shared.formatAPIError(error))")
			
			// Check if error is related to pinning limits
			let formattedError = ErrorFormattingService.shared.formatAPIError(error)
			print("🔍 Formatted error from server: \(formattedError)")
			if formattedError.contains("pinned activity types") {
				print("⚠️ Server returned pinning limit error - this might be a server-side validation bug")
				errorMessage = "You can only pin up to 4 activity types"
			} else {
				errorMessage = formattedError
			}
			
			// Refresh from API to get correct state
			await fetchActivityTypes()
		} catch {
            errorMessage = ErrorFormattingService.shared.formatError(error)
        }
    }
    
    // MARK: - Utility Methods
    
    /// Computed property to sort activity types with pinned ones first, then alphabetically
    var sortedActivityTypes: [ActivityTypeDTO] {
        let sorted = activityTypes.sorted { first, second in
            // Pinned types come first
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            // If both are pinned or both are not pinned, sort alphabetically by title
            return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
        }
        
        return sorted
    }
    
    /// Clears any error messages
    @MainActor
    func clearError() {
        errorMessage = nil
    }
    
    /// Shows an error message
    @MainActor
    func showError(_ message: String) {
        errorMessage = message
    }
    
} 
