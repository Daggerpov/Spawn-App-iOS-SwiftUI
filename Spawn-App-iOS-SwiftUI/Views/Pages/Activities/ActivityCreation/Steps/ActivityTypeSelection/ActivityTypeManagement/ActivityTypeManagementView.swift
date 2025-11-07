import SwiftUI

struct ActivityTypeManagementView: View {
    let activityTypeDTO: ActivityTypeDTO
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingOptions = false
    @State private var showingManagePeople = false
    @State private var showingEditView = false
    @State private var navigateToProfile = false
    @State private var selectedUserForProfile: BaseUserDTO?
    
    // Store background refresh task so we can cancel it on disappear
    @State private var backgroundRefreshTask: Task<Void, Never>?
    
    // Use the ActivityTypeViewModel for managing activity types
    @StateObject private var viewModel: ActivityTypeViewModel
    
    init(activityTypeDTO: ActivityTypeDTO) {
        self.activityTypeDTO = activityTypeDTO
        
        // Initialize the view model with userId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    // Computed property to get the current activity type data from view model
    private var currentActivityType: ActivityTypeDTO? {
        return viewModel.activityTypes.first { $0.id == activityTypeDTO.id }
    }
    
    // Use current data if available, otherwise fall back to original
    private var displayActivityType: ActivityTypeDTO {
        return currentActivityType ?? activityTypeDTO
    }
    
    // MARK: - Theme-aware colors
    private var adaptiveCardBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.24, green: 0.23, blue: 0.23) : Color(red: 0.95, green: 0.93, blue: 0.93)
    }
    
    private var adaptiveEditButtonColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : Color(red: 0.75, green: 0.75, blue: 0.75)
    }
    
    private var adaptiveCardTextColor: Color {
        colorScheme == .dark ? Color.white : universalAccentColor
    }
    
    private var adaptivePeopleCountColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
    }
    
    private var adaptiveEmptyStateTextColor: Color {
        colorScheme == .dark ? Color.white : universalAccentColor
    }
    
    private var adaptiveEmptyStateDescriptionColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : figmaBlack300
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header - following app's standard pattern
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(universalAccentColor)
                    }
                    
                    Spacer()
                    
                    Text("Manage Type - \(displayActivityType.title)")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(universalAccentColor)
                    
                    Spacer()
                    
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Activity Type Card
                        activityTypeCard
                        
                        // People Section
                        peopleSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
                .background(universalBackgroundColor)
                
                // Loading overlay
                if viewModel.isLoading {
                    ProgressView("Deleting...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingManagePeople) {
                ManagePeopleView(
                    user: UserAuthViewModel.shared.spawnUser ?? BaseUserDTO.danielAgapov,
                    activityTitle: displayActivityType.title,
                    activityTypeDTO: displayActivityType
                )
            }
            .navigationDestination(isPresented: $navigateToProfile) {
                if let selectedUser = selectedUserForProfile {
                    ProfileView(user: selectedUser)
                }
            }
        .task {
            print("📍 [NAV] ActivityTypeManagementView .task started")
            let taskStartTime = Date()
            
            // CRITICAL FIX: Load cached data immediately to unblock UI
            // This prevents the UI from hanging while waiting for API calls
            
            // Load cached data synchronously first (fast, non-blocking)
            let cacheLoadStart = Date()
            let cachedActivityTypes = AppCache.shared.activityTypes
            let cacheLoadDuration = Date().timeIntervalSince(cacheLoadStart)
            
            print("📊 [NAV] Cache loaded in \(String(format: "%.3f", cacheLoadDuration))s")
            print("   Activity Types: \(cachedActivityTypes.count)")
            
            // Check if task was cancelled (user navigated away)
            if Task.isCancelled {
                print("⚠️ [NAV] Task cancelled before applying cached data - user navigated away")
                return
            }
            
            // Apply cached data to view model immediately
            await MainActor.run {
                let applyStart = Date()
                
                if !cachedActivityTypes.isEmpty {
                    viewModel.activityTypes = cachedActivityTypes
                    print("✅ [NAV] Applied \(cachedActivityTypes.count) cached activity types to UI")
                } else {
                    print("⚠️ [NAV] No cached activity types available")
                }
                
                let applyDuration = Date().timeIntervalSince(applyStart)
                let totalDuration = Date().timeIntervalSince(taskStartTime)
                print("⏱️ [NAV] UI update took \(String(format: "%.3f", applyDuration))s, total: \(String(format: "%.3f", totalDuration))s")
            }
            
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
            print("👁️ [NAV] ActivityTypeManagementView appeared")
        }
        .onDisappear {
            print("👋 [NAV] ActivityTypeManagementView disappearing - cancelling background tasks")
            // Cancel any ongoing background refresh to prevent blocking
            backgroundRefreshTask?.cancel()
            backgroundRefreshTask = nil
            print("👋 [NAV] ActivityTypeManagementView disappeared")
        }
        .onReceive(NotificationCenter.default.publisher(for: .activityTypesChanged)) { _ in
            // Refresh when activity types change
            Task {
                await viewModel.fetchActivityTypes()
            }
        }
        .fullScreenCover(isPresented: $showingEditView) {
            NavigationStack {
                ActivityTypeEditView(activityTypeDTO: displayActivityType) {
                    showingEditView = false
                }
            }
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
            
            // Custom popup overlay
            if showingOptions {
                ActivityTypeOptionsPopup(
                    isPresented: $showingOptions,
                    onManagePeople: {
                        showingManagePeople = true
                    },
                    onDeleteActivityType: {
                        Task {
                            await viewModel.deleteActivityType(displayActivityType)
                            // Dismiss the view after successful deletion
                            if viewModel.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                )
            }
        }
    }
    
    private var activityTypeCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(adaptiveCardBackgroundColor)
                .frame(width: 145, height: 145)
            
            VStack(spacing: 15) {
                // Activity Icon
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 40, height: 40)
                    
                    Text(displayActivityType.icon)
                        .font(.system(size: 24))
                }
                .frame(width: 40, height: 40)
                
                // Activity Title
                Text(displayActivityType.title)
                    .font(.onestMedium(size: 24))
                    .foregroundColor(adaptiveCardTextColor)
            }
            .padding(20)
            
            // Edit button overlay - positioned at bottom right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingEditView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(adaptiveEditButtonColor)
                                .frame(width: 36.25, height: 36.25)
                            
                            Image(systemName: "pencil")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: 10, y: 10)
                }
            }
        }
        .frame(width: 145, height: 145)
    }
    
    private var peopleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Only show header when there are friends
            if !displayActivityType.associatedFriends.isEmpty {
                // Header with people count and manage button - improved alignment
                HStack(alignment: .center, spacing: 12) {
                    Text("People (\(displayActivityType.associatedFriends.count))")
                        .font(.onestSemiBold(size: 17))
                        .foregroundColor(adaptivePeopleCountColor)
                    
                    Spacer()
                    
                    Button(action: { showingManagePeople = true }) {
                        Text("Manage People")
                            .font(.onestMedium(size: 16))
                            .foregroundColor(figmaBlue)
                    }
                }
            }
            
            if displayActivityType.associatedFriends.isEmpty {
                // Empty state - new design
                emptyStateView
            } else {
                // People list - following Figma design pattern
                LazyVStack(spacing: 12) {
                    ForEach(displayActivityType.associatedFriends, id: \.id) { friend in
                        peopleRowView(friend: friend)
                    }
                }
            }
        }
    }
    
    private func peopleRowView(friend: BaseUserDTO) -> some View {
        PeopleRowView(friend: friend, activityType: displayActivityType) { user in
            selectedUserForProfile = user
            navigateToProfile = true
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 60)
            
            // No people yet text
            Text("No people yet!")
                .font(.onestSemiBold(size: 28))
                .foregroundColor(adaptiveEmptyStateTextColor)
            
            Spacer()
                .frame(height: 24)
            
            // Description text
            Text("You haven't added placed friends under this tag yet. Tap below to get started!")
                .font(.onestMedium(size: 16))
                .foregroundColor(adaptiveEmptyStateDescriptionColor)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineLimit(nil)
            
            Spacer()
                .frame(height: 32)
            
            // Add friends button - matching Figma design exactly
            Button(action: { showingManagePeople = true }) {
                HStack(spacing: 5.6) {
                    Image(systemName: "plus")
                        .font(.system(size: 16.8, weight: .semibold))
                        .foregroundColor(figmaGreen)
                    
                    Text("Add friends")
                        .font(.onestSemiBold(size: 16.8))
                        .foregroundColor(figmaGreen)
                }
                .padding(EdgeInsets(top: 16.8, leading: 22.4, bottom: 16.8, trailing: 22.4))
                .frame(height: 55.35)
                .background(
                    RoundedRectangle(cornerRadius: 115.5)
                        .stroke(figmaGreen, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - ManagePeopleView and Related Components
// The ManagePeopleView is now implemented as a standalone full-page view in:
// Views/Pages/Activities/ManagePeopleView.swift
// This allows for better navigation and follows the Figma design as a full page instead of a sheet.

@available(iOS 17, *)
#Preview {
    @Previewable @ObservedObject var appCache = AppCache.shared
    
    ActivityTypeManagementView(activityTypeDTO: ActivityTypeDTO.mockChillActivityType)
        .environmentObject(appCache)
} 
