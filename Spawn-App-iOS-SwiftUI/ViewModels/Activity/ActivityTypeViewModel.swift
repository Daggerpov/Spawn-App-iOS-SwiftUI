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
            appCache.$activityTypes
                .sink { [weak self] cachedActivityTypes in
                    if !cachedActivityTypes.isEmpty {
                        self?.activityTypes = cachedActivityTypes
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Backend API Methods
    
    /// Fetches all activity types for the user from the backend
    @MainActor
    func fetchActivityTypes() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedTypes: [ActivityTypeDTO] = try await apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            self.activityTypes = fetchedTypes
            
            // Update cache with fetched data
            appCache.updateActivityTypes(fetchedTypes)
            

            
        } catch {
            self.errorMessage = "Failed to load activity types"
            print("❌ Error fetching activity types: \(error)")
        }
    }
    

    
    // MARK: - Local State Manipulation Methods
    
    /// Toggles the pin status of an activity type via direct API call
    @MainActor
    func togglePin(for activityTypeDTO: ActivityTypeDTO) async {
        // Check if we're already at the pin limit when trying to pin
        if !activityTypeDTO.isPinned {
            let currentPinnedCount = activityTypes.filter { $0.isPinned }.count
            
            if currentPinnedCount >= 3 {
                print("❌ Cannot pin: Already at maximum of 3 pinned activity types")
                await MainActor.run {
                    errorMessage = "You can only pin up to 3 activity types"
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
            isPinned: !activityTypeDTO.isPinned
        )
        
        await updateActivityType(updatedActivityType)
    }
    
    /// Deletes an activity type via direct API call
    @MainActor
    func deleteActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
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
            
            // Update local state with confirmed data from API
            self.activityTypes = updatedActivityTypes
            
            // Update cache with confirmed data
            appCache.updateActivityTypes(updatedActivityTypes)
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
            
            print("✅ Successfully deleted activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error deleting activity type: \(error)")
            errorMessage = "Failed to delete activity type"
        }
    }
    
    /// Creates a new activity type via direct API call
    @MainActor
    func createActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
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
            
            // Update local state with confirmed data from API
            self.activityTypes = updatedActivityTypes
            
            // Update cache with confirmed data
            appCache.updateActivityTypes(updatedActivityTypes)
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
            
            print("✅ Successfully created activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error creating activity type: \(error)")
            errorMessage = "Failed to create activity type"
        }
    }
    
    /// Updates an existing activity type via direct API call
    @MainActor
    func updateActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        print("📡 API Mode: \(MockAPIService.isMocking ? "MOCK" : "REAL")")
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Invalid URL for endpoint: \(endpoint)")
                errorMessage = "Invalid URL"
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
            
            // Update local state with confirmed data from API
            self.activityTypes = updatedActivityTypes
            
            // Update cache with confirmed data
            appCache.updateActivityTypes(updatedActivityTypes)
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
            
        } catch {
            print("❌ Error updating activity type: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            // Enhanced error handling
            if let error = error as? APIError {
                switch error {
                case .invalidStatusCode(let statusCode):
                    errorMessage = "Server error (status \(statusCode)). Please try again."
                case .invalidData:
                    errorMessage = "Invalid response format. Please try again."
                case .URLError:
                    errorMessage = "Network error. Please check your connection."
                case .failedHTTPRequest(let description):
                    errorMessage = "Request failed: \(description)"
                case .failedJSONParsing:
                    errorMessage = "Failed to parse server response. Please try again."
                case .unknownError(let error):
                    errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                case .failedTokenSaving:
                    errorMessage = "Authentication error. Please try logging in again."
                }
            } else {
                errorMessage = "Failed to update activity type"
            }
            
            // Check if error is related to pinning limits
            if error.localizedDescription.contains("pinned activity types") {
                errorMessage = "You can only pin up to 3 activity types"
            }
            
            // Refresh from API to get correct state
            await fetchActivityTypes()
        }
    }
    
    // MARK: - Utility Methods
    
    /// Computed property to sort activity types with pinned ones first
    var sortedActivityTypes: [ActivityTypeDTO] {
        let sorted = activityTypes.sorted { first, second in
            // Pinned types come first
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            // If both are pinned or both are not pinned, sort by orderNum
            return first.orderNum < second.orderNum
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
    
    /// Reorders activity types based on drag and drop, with validation for pinned/unpinned constraints
    @MainActor
    func reorderActivityTypes(from source: Int, to destination: Int) async {
        guard source != destination else { return }
        
        let sortedTypes = sortedActivityTypes
        guard source < sortedTypes.count && destination < sortedTypes.count else {
            print("❌ Invalid indices for reordering")
            return
        }
        
        let sourceItem = sortedTypes[source]
        let destinationItem = sortedTypes[destination]
        
        // Validation: Don't allow unpinned items to be moved before pinned items
        if !sourceItem.isPinned && destinationItem.isPinned {
            print("❌ Cannot move unpinned item before pinned item")
            errorMessage = "Unpinned activities cannot be moved before pinned activities"
            return
        }
        
        // Create a mutable copy of the sorted types
        var reorderedTypes = sortedTypes
        
        // Move the item from source to destination
        let movedItem = reorderedTypes.remove(at: source)
        reorderedTypes.insert(movedItem, at: destination)
        
        // Update orderNum for all affected items
        var updatedTypes: [ActivityTypeDTO] = []
        for (index, activityType) in reorderedTypes.enumerated() {
            let updatedType = ActivityTypeDTO(
                id: activityType.id,
                title: activityType.title,
                icon: activityType.icon,
                associatedFriends: activityType.associatedFriends,
                orderNum: index,
                isPinned: activityType.isPinned
            )
            updatedTypes.append(updatedType)
        }
        
        // Update the local state optimistically
        self.activityTypes = updatedTypes
        
        // Save changes to the backend
        await batchUpdateActivityTypes(updatedTypes)
    }
    
    /// Performs a batch update of activity types
    @MainActor
    private func batchUpdateActivityTypes(_ activityTypes: [ActivityTypeDTO]) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: activityTypes,
                deletedActivityTypeIds: []
            )
            
            let updatedActivityTypes: [ActivityTypeDTO] = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Update local state with confirmed data from API
            self.activityTypes = updatedActivityTypes
            
            // Update cache with confirmed data
            appCache.updateActivityTypes(updatedActivityTypes)
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: .activityTypesChanged, object: nil)
            
            print("✅ Successfully reordered activity types")
            
        } catch {
            print("❌ Error reordering activity types: \(error)")
            errorMessage = "Failed to reorder activity types"
            
            // Refresh from API to get correct state
            await fetchActivityTypes()
        }
    }
} 
