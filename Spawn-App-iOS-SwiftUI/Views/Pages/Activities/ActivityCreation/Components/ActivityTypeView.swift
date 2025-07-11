import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onNext: () -> Void
    
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: ActivityTypeViewModel
    @State private var navigateToManageType = false
    @State private var navigateToCreateType = false
    @State private var selectedActivityTypeForManagement: ActivityTypeDTO?
    
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
                
                if viewModel.isLoading {
                    ProgressView("Loading activity types...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.activityTypes.isEmpty {
                    emptyStateSection
                } else {
                    activityTypeGrid
                }
                
                Spacer()
                
                ActivityNextStepButton(
                    title: "Next Step",
                    isEnabled: selectedActivityType != nil,
                    action: onNext
                )
            }
            .onAppear {
                Task {
                    await viewModel.fetchActivityTypes()
                }
            }
            .onDisappear {
                // Save any unsaved changes when the view disappears
                if viewModel.hasUnsavedChanges {
                    Task {
                        await viewModel.saveBatchChanges()
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
            .navigationDestination(isPresented: $navigateToManageType) {
                if let activityType = selectedActivityTypeForManagement {
                    ActivityTypeManagementView(activityTypeDTO: activityType)
                }
            }
            .navigationDestination(isPresented: $navigateToCreateType) {
                ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.createNew())
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Activity Type")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(universalAccentColor)
            
            Text("Choose what type of activity you're planning")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var emptyStateSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Activity Types")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Create your first activity type to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var activityTypeGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.sortedActivityTypes, id: \.id) { activityTypeDTO in
                    ActivityTypeCard(
                        activityTypeDTO: activityTypeDTO,
                        selectedActivityType: $selectedActivityType,
                        onPin: {
                            viewModel.togglePin(for: activityTypeDTO)
                        },
                        onDelete: {
                            viewModel.deleteActivityType(activityTypeDTO)
                        },
                        onManage: {
                            selectedActivityTypeForManagement = activityTypeDTO
                            navigateToManageType = true
                        }
                    )
                }
                
                // Create New Activity Button
                CreateNewActivityTypeCard(onCreateNew: {
                    navigateToCreateType = true
                })
            }
            .padding()
        }
    }
}

struct ActivityTypeCard: View {
    let activityTypeDTO: ActivityTypeDTO
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onPin: () -> Void
    let onDelete: () -> Void
    let onManage: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteConfirmation = false
    
    private var isSelected: Bool {
        return selectedActivityType?.id == activityTypeDTO.id
    }
    
    // Adaptive background color
    private var adaptiveBackgroundColor: Color {
        if isSelected {
            return universalSecondaryColor.opacity(0.1)
        } else {
            switch colorScheme {
            case .dark:
                return Color.white.opacity(0.08)
            case .light:
                return Color.gray.opacity(0.05)
            @unknown default:
                return Color.gray.opacity(0.05)
            }
        }
    }
    
    // Adaptive text color for people count
    private var adaptiveSecondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.6)
        case .light:
            return figmaBlack300
        @unknown default:
            return figmaBlack300
        }
    }
    
    // Adaptive text color for title
    private var adaptiveTitleColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white
        case .light:
            return universalAccentColor
        @unknown default:
            return universalAccentColor
        }
    }
    
    var body: some View {
        Button(action: { 
            selectedActivityType = activityTypeDTO
        }) {
            ZStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(activityTypeDTO.icon)
                            .font(.title)
                        Spacer()
                        Text("\(activityTypeDTO.associatedFriends.count) people")
                            .font(.caption)
                            .foregroundColor(adaptiveSecondaryTextColor)
                    }
                    
                    Text(activityTypeDTO.title)
                        .font(.headline)
                        .foregroundColor(adaptiveTitleColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(adaptiveBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? universalSecondaryColor : Color.clear, lineWidth: 2)
                        )
                )
                
                // Pin icon overlay
                if activityTypeDTO.isPinned {
                    VStack {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 12))
                                .rotationEffect(.degrees(45))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .contextMenu {
            Button(action: onPin) {
                Label(activityTypeDTO.isPinned ? "Unpin Type" : "Pin Type", systemImage: "pin")
            }
            
            Button(action: onManage) {
                Label("Manage Type", systemImage: "slider.horizontal.3")
            }
            
            Button(action: { showDeleteConfirmation = true }) {
                Label("Delete Type", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
        .alert("Delete Activity Type", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(activityTypeDTO.title)'? This action cannot be undone.")
        }
    }
}

struct CreateNewActivityTypeCard: View {
    let onCreateNew: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Design colors based on Figma specifications
    private var cardBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)
        case .light:
            return Color(red: 0.98, green: 0.85, blue: 0.85).opacity(0.70)
        @unknown default:
            return Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50)
        }
    }
    
    private var borderColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.38, green: 0.35, blue: 0.35)
        case .light:
            return Color(red: 0.75, green: 0.65, blue: 0.65)
        @unknown default:
            return Color(red: 0.38, green: 0.35, blue: 0.35)
        }
    }
    
    private var textColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        case .light:
            return Color(red: 0.45, green: 0.35, blue: 0.35)
        @unknown default:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        }
    }
    
    var body: some View {
        Button(action: onCreateNew) {
            VStack(spacing: 8) {
                // Icon area - matches Figma dimensions with custom image
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 54, height: 47)
                    .overlay(
                        Image("CreateNewActivityIcon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 35)
                    )
                
                // Text
                Text("Create New Activity")
                    .font(.onestMedium(size: 12))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedActivityType: ActivityTypeDTO? = nil
    @Previewable @StateObject var appCache = AppCache.shared
    
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
