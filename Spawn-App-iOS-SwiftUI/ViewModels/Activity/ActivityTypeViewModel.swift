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
        let updatedActivityType = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: activityTypeDTO.title,
            icon: activityTypeDTO.icon,
            associatedFriends: activityTypeDTO.associatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: !activityTypeDTO.isPinned
        )
        
        await updateActivityType(updatedActivityType)
        print("⚡ Toggled pin status for: \(activityTypeDTO.title) to \(updatedActivityType.isPinned)")
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
            
            print("✅ Successfully updated activity type: \(activityTypeDTO.title)")
            
        } catch {
            print("❌ Error updating activity type: \(error)")
            errorMessage = "Failed to update activity type"
            
            // Refresh from API to get correct state
            await fetchActivityTypes()
        }
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
    
    /// Clears any error messages
    @MainActor
    func clearError() {
        errorMessage = nil
    }
} 
