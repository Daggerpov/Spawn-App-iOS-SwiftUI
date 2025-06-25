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
    
    /// Fetches all activity types for the user
    @MainActor
    func fetchActivityTypes() async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedTypes: [ActivityTypeDTO] = try await apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            self.activityTypes = fetchedTypes
            print("✅ Successfully fetched \(fetchedTypes.count) activity types")
            
        } catch {
            self.errorMessage = "Failed to load activity types"
            print("❌ Error fetching activity types: \(error)")
        }
    }
    
    /// Toggles the pin status of an activity type using batch update
    @MainActor
    func togglePin(for activityTypeDTO: ActivityTypeDTO) async {
        let newPinStatus = !activityTypeDTO.isPinned
        
        // Optimistically update the local state first
        if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
            activityTypes[index].isPinned = newPinStatus
        }
        
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                // Revert the optimistic update
                if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                    activityTypes[index].isPinned = !newPinStatus
                }
                return
            }
            
            // Create a copy of the activity type with the new pin status
            let updatedActivityType = ActivityTypeDTO(
                id: activityTypeDTO.id,
                title: activityTypeDTO.title,
                icon: activityTypeDTO.icon,
                associatedFriends: activityTypeDTO.associatedFriends,
                orderNum: activityTypeDTO.orderNum,
                isPinned: newPinStatus
            )
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [updatedActivityType],
                deletedActivityTypeIds: []
            )
            
            let _: BatchActivityTypeUpdateDTO = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            print("✅ Successfully updated pin status for activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error updating pin status: \(error)")
            errorMessage = "Failed to update pin status"
            
            // Revert the optimistic update on error
            if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                activityTypes[index].isPinned = !newPinStatus
            }
        }
    }
    
    /// Deletes an activity type
    @MainActor
    func deleteActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        // Optimistically remove from local state
        let originalActivityTypes = activityTypes
        activityTypes.removeAll { $0.id == activityTypeDTO.id }
        
        do {
            let endpoint = "activity-type/\(activityTypeDTO.id)/user/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for delete")
                // Revert the optimistic update
                activityTypes = originalActivityTypes
                return
            }
            
            // Define EmptyObject for delete request
            struct EmptyObject: Encodable {}
            
            try await apiService.deleteData(from: url, parameters: nil, object: EmptyObject())
            
            print("✅ Successfully deleted activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error deleting activity type: \(error)")
            errorMessage = "Failed to delete activity type"
            
            // Revert the optimistic update on error
            activityTypes = originalActivityTypes
        }
    }
    
    /// Creates a new activity type using batch update
    @MainActor
    func createActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                errorMessage = "Invalid URL"
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [activityTypeDTO],
                deletedActivityTypeIds: []
            )
            
            let _: BatchActivityTypeUpdateDTO = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Refresh the activity types after creating
            await fetchActivityTypes()
            
            print("✅ Successfully created activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error creating activity type: \(error)")
            errorMessage = "Failed to create activity type"
        }
    }
    
    /// Updates an existing activity type using batch update
    @MainActor
    func updateActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                errorMessage = "Invalid URL"
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [activityTypeDTO],
                deletedActivityTypeIds: []
            )
            
            let _: BatchActivityTypeUpdateDTO = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Update local state
            if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                activityTypes[index] = activityTypeDTO
            }
            
            print("✅ Successfully updated activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error updating activity type: \(error)")
            errorMessage = "Failed to update activity type"
        }
    }
    
    /// Batch update multiple activity types
    @MainActor
    func batchUpdateActivityTypes(
        updatedTypes: [ActivityTypeDTO] = [],
        deletedTypeIds: [UUID] = []
    ) async {
        guard !updatedTypes.isEmpty || !deletedTypeIds.isEmpty else {
            errorMessage = "No activity types to update or delete"
            return
        }
        
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                errorMessage = "Invalid URL"
                return
            }
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: updatedTypes,
                deletedActivityTypeIds: deletedTypeIds
            )
            
            let _: BatchActivityTypeUpdateDTO = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Refresh the activity types after batch update
            await fetchActivityTypes()
            
            print("✅ Successfully performed batch update with \(updatedTypes.count) updates and \(deletedTypeIds.count) deletions")
            
        } catch {
            print("❌ Error performing batch update: \(error)")
            errorMessage = "Failed to perform batch update"
        }
    }
    
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
    
    /// Clears any error messages
    @MainActor
    func clearError() {
        errorMessage = nil
    }
} 