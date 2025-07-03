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
    @Published var hasUnsavedChanges: Bool = false
    
    private let apiService: IAPIService
    private let userId: UUID
    private var appCache: AppCache
    private var cancellables = Set<AnyCancellable>()
    
    // Track changes for batch update
    private var originalActivityTypes: [ActivityTypeDTO] = []
    private var deletedActivityTypeIds: Set<UUID> = []
    
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
            // TODO: Implement cache subscription when activity types are added to AppCache
            // appCache.$activityTypes
            //     .sink { [weak self] cachedActivityTypes in
            //         if !cachedActivityTypes.isEmpty {
            //             self?.activityTypes = cachedActivityTypes
            //         }
            //     }
            //     .store(in: &cancellables)
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
            let endpoint = "api/v1/\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedTypes: [ActivityTypeDTO] = try await apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            self.activityTypes = fetchedTypes
            self.originalActivityTypes = fetchedTypes.map { ActivityTypeDTO(
                id: $0.id,
                title: $0.title,
                icon: $0.icon,
                associatedFriends: $0.associatedFriends,
                orderNum: $0.orderNum,
                isPinned: $0.isPinned
            )}
            self.deletedActivityTypeIds.removeAll()
            self.hasUnsavedChanges = false
            
            print("✅ Successfully fetched \(fetchedTypes.count) activity types")
            
        } catch {
            self.errorMessage = "Failed to load activity types"
            print("❌ Error fetching activity types: \(error)")
        }
    }
    
    /// Sends all accumulated changes to the backend in one batch update
    @MainActor
    func saveBatchChanges() async {
        guard hasUnsavedChanges else {
            print("ℹ️ No unsaved changes to batch update")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "api/v1/\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                errorMessage = "Invalid URL"
                return
            }
            
            // Get all activity types that have been modified or are new
            let updatedActivityTypes = activityTypes.filter { activityType in
                // Check if this is a new activity type (not in original)
                if !originalActivityTypes.contains(where: { $0.id == activityType.id }) {
                    return true
                }
                
                // Check if this activity type has been modified
                if let original = originalActivityTypes.first(where: { $0.id == activityType.id }) {
                    return original.title != activityType.title ||
                           original.icon != activityType.icon ||
                           original.orderNum != activityType.orderNum ||
                           original.isPinned != activityType.isPinned ||
                           !original.associatedFriends.elementsEqual(activityType.associatedFriends, by: { $0.id == $1.id })
                }
                
                return false
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: updatedActivityTypes,
                deletedActivityTypeIds: Array(deletedActivityTypeIds)
            )
            
            let updatedActivityTypes: [ActivityTypeDTO] = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Update local state with the returned activity types from server
            self.activityTypes = updatedActivityTypes
            self.originalActivityTypes = updatedActivityTypes.map { ActivityTypeDTO(
                id: $0.id,
                title: $0.title,
                icon: $0.icon,
                associatedFriends: $0.associatedFriends,
                orderNum: $0.orderNum,
                isPinned: $0.isPinned
            )}
            self.deletedActivityTypeIds.removeAll()
            self.hasUnsavedChanges = false
            
            print("✅ Successfully saved batch changes: \(updatedActivityTypes.count) total activity types returned")
            
        } catch {
            print("❌ Error saving batch changes: \(error)")
            errorMessage = "Failed to save changes"
        }
    }
    
    // MARK: - Local State Manipulation Methods
    
    /// Toggles the pin status of an activity type locally
    @MainActor
    func togglePin(for activityTypeDTO: ActivityTypeDTO) {
        if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
            activityTypes[index].isPinned.toggle()
            hasUnsavedChanges = true
            print("🔄 Locally toggled pin status for: \(activityTypeDTO.title)")
        }
    }
    
    /// Deletes an activity type locally
    @MainActor
    func deleteActivityType(_ activityTypeDTO: ActivityTypeDTO) {
        // Remove from local array
        activityTypes.removeAll { $0.id == activityTypeDTO.id }
        
        // Track deletion if this was an existing activity type (not newly created)
        if originalActivityTypes.contains(where: { $0.id == activityTypeDTO.id }) {
            deletedActivityTypeIds.insert(activityTypeDTO.id)
        }
        
        hasUnsavedChanges = true
        print("🗑️ Locally deleted activity type: \(activityTypeDTO.title)")
    }
    
    /// Creates a new activity type locally
    @MainActor
    func createActivityType(_ activityTypeDTO: ActivityTypeDTO) {
        activityTypes.append(activityTypeDTO)
        hasUnsavedChanges = true
        print("➕ Locally created activity type: \(activityTypeDTO.title)")
    }
    
    /// Updates an existing activity type locally
    @MainActor
    func updateActivityType(_ activityTypeDTO: ActivityTypeDTO) {
        if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
            activityTypes[index] = activityTypeDTO
            hasUnsavedChanges = true
            print("📝 Locally updated activity type: \(activityTypeDTO.title)")
        }
    }
    
    /// Reorders activity types locally
    @MainActor
    func reorderActivityTypes(from source: IndexSet, to destination: Int) {
        var sortedTypes = sortedActivityTypes
        sortedTypes.move(fromOffsets: source, toOffset: destination)
        
        // Update order numbers
        for (index, activityType) in sortedTypes.enumerated() {
            if let originalIndex = activityTypes.firstIndex(where: { $0.id == activityType.id }) {
                activityTypes[originalIndex].orderNum = index
            }
        }
        
        hasUnsavedChanges = true
        print("🔄 Locally reordered activity types")
    }
    
    /// Updates order numbers for all activity types based on current sort
    @MainActor
    func updateOrderNumbers() {
        let sorted = sortedActivityTypes
        for (index, activityType) in sorted.enumerated() {
            if let originalIndex = activityTypes.firstIndex(where: { $0.id == activityType.id }) {
                activityTypes[originalIndex].orderNum = index
            }
        }
        hasUnsavedChanges = true
    }
    
    // MARK: - Utility Methods
    
    /// Computed property to sort activity types with pinned ones first
    var sortedActivityTypes: [ActivityTypeDTO] {
        activityTypes.sorted { first, second in
            // Pinned types come first
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            // If both are pinned or both are not pinned, sort by orderNum
            return first.orderNum < second.orderNum
        }
    }
    
    /// Discards all local changes and reverts to original state
    @MainActor
    func discardLocalChanges() {
        activityTypes = originalActivityTypes.map { ActivityTypeDTO(
            id: $0.id,
            title: $0.title,
            icon: $0.icon,
            associatedFriends: $0.associatedFriends,
            orderNum: $0.orderNum,
            isPinned: $0.isPinned
        )}
        deletedActivityTypeIds.removeAll()
        hasUnsavedChanges = false
        print("↩️ Discarded all local changes")
    }
    
    /// Clears any error messages
    @MainActor
    func clearError() {
        errorMessage = nil
    }
} 