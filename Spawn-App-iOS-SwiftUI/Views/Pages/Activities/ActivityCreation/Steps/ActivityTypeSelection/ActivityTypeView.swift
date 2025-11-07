import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onNext: () -> Void
    
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: ActivityTypeViewModel
    @State private var navigateToManageType = false
    @State private var navigateToCreateType = false
    @State private var selectedActivityTypeForManagement: ActivityTypeDTO?
    
    // Delete confirmation state
    @State private var showDeleteConfirmation = false
    @State private var activityTypeToDelete: ActivityTypeDTO?
    
    // Store background refresh task so we can cancel it on disappear
    @State private var backgroundRefreshTask: Task<Void, Never>?
    
    // Initialize the view model with userId
    init(selectedActivityType: Binding<ActivityTypeDTO?>, onNext: @escaping () -> Void) {
        self._selectedActivityType = selectedActivityType
        self.onNext = onNext
        
        // Get userId from UserAuthViewModel like the original code
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                
                // Error message display
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                if viewModel.isLoading {
                    LoadingStateView(message: "Loading activity types...")
                } else if viewModel.activityTypes.isEmpty {
                    emptyStateSection
                } else {
                    activityTypeGrid
                }
                
                Spacer()
            }
            .task {
                print("📍 [NAV] ActivityTypeView .task started")
                let taskStartTime = Date()
                
                // CRITICAL FIX: Load cached data immediately to unblock UI
                // This prevents the UI from hanging while waiting for API calls
                
                // Load cached data through view model (fast, non-blocking)
                let cacheLoadStart = Date()
                let activityTypesCount: Int = await MainActor.run {
                    viewModel.loadCachedActivityTypes()
                    return viewModel.activityTypes.count
                }
                let cacheLoadDuration = Date().timeIntervalSince(cacheLoadStart)
                let totalDuration = Date().timeIntervalSince(taskStartTime)
                
                print("📊 [NAV] Cache loaded in \(String(format: "%.3f", cacheLoadDuration))s")
                print("   Activity Types: \(activityTypesCount)")
                print("⏱️ [NAV] UI update took \(String(format: "%.3f", totalDuration))s")
                
                // Check if task was cancelled before starting background refresh
                if Task.isCancelled {
                    print("⚠️ [NAV] Task cancelled before starting background refresh - user navigated away")
                    return
                }
                
                // Refresh from API in background (non-blocking)
                // Store the task so we can cancel it if user navigates away
                print("🔄 [NAV] Starting background refresh for activity types")
                backgroundRefreshTask = Task.detached(priority: .userInitiated) {
                    let refreshStart = Date()
                    await viewModel.fetchActivityTypes(forceRefresh: true)
                    let refreshDuration = Date().timeIntervalSince(refreshStart)
                    print("⏱️ [NAV] Activity types refresh took \(String(format: "%.2f", refreshDuration))s")
                    print("✅ [NAV] Background refresh completed")
                }
            }
            .onAppear {
                print("👁️ [NAV] ActivityTypeView appeared")
            }
            .onDisappear {
                print("👋 [NAV] ActivityTypeView disappearing - cancelling background tasks")
                // Cancel any ongoing background refresh to prevent blocking
                backgroundRefreshTask?.cancel()
                backgroundRefreshTask = nil
                print("👋 [NAV] ActivityTypeView disappeared")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Delete Activity Type", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    activityTypeToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let activityType = activityTypeToDelete {
                        // Clear selected activity type if it's the one being deleted
                        if selectedActivityType?.id == activityType.id {
                            selectedActivityType = nil
                        }
                        Task {
                            await viewModel.deleteActivityType(activityType)
                        }
                    }
                    activityTypeToDelete = nil
                }
            } message: {
                if let activityType = activityTypeToDelete {
                    Text("Are you sure you want to delete '\(activityType.title)'? This action cannot be undone.")
                }
            }
            .navigationDestination(isPresented: $navigateToManageType) {
                if let selectedType = selectedActivityTypeForManagement {
                    ActivityTypeManagementView(activityTypeDTO: selectedType)
                }
            }
            .sheet(isPresented: $navigateToCreateType) {
                NavigationStack {
                    ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.createNew())
                }
            }
        }
    }
}

// MARK: - View Components
extension ActivityTypeView {
    private var headerSection: some View {
        HStack {
            // Invisible chevron to balance layout (no back button on this screen)
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundColor(.clear)
            
            Spacer()
            
            Text("What are you up to?")
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Invisible chevron to balance the left side
            Image(systemName: "chevron.left")
                .font(.title3)
                .foregroundColor(.clear)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Activity Types")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first activity type to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create New Activity Type") {
                navigateToCreateType = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var activityTypeGrid: some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(viewModel.sortedActivityTypes, id: \.id) { activityTypeDTO in
                    activityTypeCardView(for: activityTypeDTO)
                }
                
                createNewActivityButton
            }
            .padding()
        }
    }
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.fixed(116), spacing: 8),
            GridItem(.fixed(116), spacing: 8),
            GridItem(.fixed(116), spacing: 8)
        ]
    }
    
    private var createNewActivityButton: some View {
        CreateNewActivityTypeCard(onCreateNew: {
            navigateToCreateType = true
        })
    }
    
    private func activityTypeCardView(for activityTypeDTO: ActivityTypeDTO) -> some View {
        ActivityTypeCard(
            activityTypeDTO: activityTypeDTO,
            selectedActivityType: $selectedActivityType,
            onPin: {
                Task {
                    await viewModel.togglePin(for: activityTypeDTO)
                }
            },
            onDelete: {
                activityTypeToDelete = activityTypeDTO
                showDeleteConfirmation = true
            },
            onManage: {
                selectedActivityTypeForManagement = activityTypeDTO
                navigateToManageType = true
            },
        )
    }
}

// MARK: - Supporting Views
// All supporting view structs have been moved to separate files in ActivityTypeView/
// - ActivityTypeCard.swift
// - CreateNewActivityTypeCard.swift

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedActivityType: ActivityTypeDTO? = nil
    @Previewable @ObservedObject var appCache = AppCache.shared
    
    NavigationView {
        ActivityTypeView(
            selectedActivityType: $selectedActivityType,
            onNext: {
                print("Next step tapped")
            }
        )
        .environmentObject(appCache)
    }
} 

