import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: ActivityType?
    let onNext: () -> Void
    
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: ActivityTypeViewModel
    
    // Initialize the view model with userId
    init(selectedType: Binding<ActivityType?>, onNext: @escaping () -> Void) {
        self._selectedType = selectedType
        self.onNext = onNext
        
        // Get userId from UserAuthViewModel like the original code
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self._viewModel = StateObject(wrappedValue: ActivityTypeViewModel(userId: userId))
    }
    
    var body: some View {
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
                isEnabled: selectedType != nil,
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
                        selectedType: $selectedType,
                        onPin: {
                            viewModel.togglePin(for: activityTypeDTO)
                        },
                        onDelete: {
                            viewModel.deleteActivityType(activityTypeDTO)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct ActivityTypeCard: View {
    let activityTypeDTO: ActivityTypeDTO
    @Binding var selectedType: ActivityType?
    let onPin: () -> Void
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var navigateToManageType = false
    
    // Convert ActivityTypeDTO to ActivityType for selection comparison
    private var activityType: ActivityType? {
        // First try exact match
        if let exactMatch = ActivityType.allCases.first(where: { $0.rawValue == activityTypeDTO.title }) {
            return exactMatch
        }
        
        // If no exact match, try fuzzy matching for common cases
        switch activityTypeDTO.title.lowercased() {
        case "food":
            return .foodAndDrink
        case "active":
            return .active
        case "study":
            return .grind
        case "chill":
            return .chill
        case "general":
            return .general
        default:
            // For unmapped types, return nil to make them unselectable
            // This prevents conflicts in selection logic
            return nil
        }
    }
    
    private var isSelected: Bool {
        guard let activityType = activityType else {
            return false
        }
        
        let selected = selectedType == activityType
        return selected
    }
    
    // Adaptive background color
    private var adaptiveBackgroundColor: Color {
        // If unmapped, show as disabled
        if activityType == nil {
            return Color.gray.opacity(0.02)
        }
        
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
        // If unmapped, show as disabled
        if activityType == nil {
            return Color.gray.opacity(0.5)
        }
        
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
            if let type = activityType {
                selectedType = type
            }
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
        .disabled(activityType == nil)
        .opacity(activityType == nil ? 0.6 : 1.0)
        .contextMenu {
            Button(action: onPin) {
                Label(activityTypeDTO.isPinned ? "Unpin Type" : "Pin Type", systemImage: "pin")
            }
            
            Button(action: {
                navigateToManageType = true
            }) {
                Label("Manage Type", systemImage: "slider.horizontal.3")
            }
            
            Button(action: onDelete) {
                Label("Delete Type", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
        .background(
            NavigationLink(
                destination: ActivityTypeManagementView(activityTypeDTO: activityTypeDTO),
                isActive: $navigateToManageType
            ) {
                EmptyView()
            }
        )
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedType: ActivityType? = nil
    @Previewable @StateObject var appCache = AppCache.shared
    
    NavigationView {
        ActivityTypeView(
            selectedType: $selectedType,
            onNext: {
                print("Next step tapped")
            }
        )
        .environmentObject(appCache)
    }
} 
