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
                    ProgressView("Loading activity types...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.activityTypes.isEmpty {
                    emptyStateSection
                } else {
                    activityTypeGrid
                }
                
                Spacer()
            }
            .onAppear {
                Task {
                    await viewModel.fetchActivityTypes()
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


struct ActivityTypeCard: View {
    let activityTypeDTO: ActivityTypeDTO
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onPin: () -> Void
    let onDelete: () -> Void
    let onManage: () -> Void
    
    // Add state to track button interaction
    @State private var isPressed = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var isSelected: Bool {
        selectedActivityType?.id == activityTypeDTO.id
    }
    
    // Adaptive background color for card
    private var adaptiveBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.24, green: 0.23, blue: 0.23)
        case .light:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        @unknown default:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        }
    }
    
    // Adaptive text colors
    private var adaptiveTitleColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        @unknown default:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        }
    }
    
    private var adaptiveSecondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    // Computed properties for dynamic styling
    private var backgroundFillColor: Color {
        if isSelected {
            return Color.blue.opacity(0.1)
        } else {
            return adaptiveBackgroundColor
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.clear
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 2
        } else {
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isSelected {
            return Color.blue.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isSelected {
            return 4
        } else {
            return 2
        }
    }
    
    private var shadowOffset: CGFloat {
        if isSelected {
            return 2
        } else {
            return 1
        }
    }

    var body: some View {
        Button(action: { 
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedActivityType = activityTypeDTO
            }
        }) {
            ZStack {
                VStack(spacing: 10) {
                    // Icon
                    ZStack {
                        Text(activityTypeDTO.icon)
                            .font(.system(size: 24))
                    }
                    .frame(width: 32, height: 32)
                    
                    // Title and people count
                    VStack {
                        Text(activityTypeDTO.title)
                            .font(Font.custom("Onest", size: 14).weight(.medium))
                            .foregroundColor(adaptiveTitleColor)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.center)
                        
                        Text("\(activityTypeDTO.associatedFriends.count) people")
                            .font(Font.custom("Onest", size: 12))
                            .foregroundColor(adaptiveSecondaryTextColor)
                    }
                }
                .padding(16)
                .frame(width: 116, height: 116)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.95, green: 0.93, blue: 0.93), lineWidth: 1) // "border"
                        .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: -2) // dark shadow top
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.white.opacity(0.7), radius: 4, x: 0, y: 4) // light shadow bottom
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                )
                
                
                // Pin icon overlay
                if activityTypeDTO.isPinned {
                    VStack {
                        HStack {
                            Image(systemName: "pin.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 8))
                                .padding(3)
                                .rotationEffect(.degrees(45))
                                .background(Color(hex: colorsRed600))
                                .clipShape(Circle())
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: onPin) {
                Label(
                    activityTypeDTO.isPinned ? "Unpin" : "Pin",
                    systemImage: activityTypeDTO.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Button(action: onManage) {
                Label("Manage", systemImage: "gear")
            }
            
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

// MARK: - Supporting Views
struct CreateNewActivityTypeCard: View {
    let onCreateNew: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.24, green: 0.23, blue: 0.23)
        case .light:
            return Color.white
        @unknown default:
            return Color.white
        }
    }
    
    private var adaptiveTextColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        @unknown default:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        }
    }
    
    private var adaptiveBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.5)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    var body: some View {
        Button(action: onCreateNew) {
            VStack(spacing: 8) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(hex: colorsGreen700))
                
                Text("Create New Activity")
                    .font(Font.custom("Onest", size: 12).weight(.medium))
                    .foregroundColor(adaptiveTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(width: 116, height: 116)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(adaptiveBorderColor, lineWidth: 0.50, dashLengthValue: 5, dashSpacingValue: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Extensions
extension RoundedRectangle {
    func stroke(_ content: Color, lineWidth: CGFloat, dashLengthValue: CGFloat, dashSpacingValue: CGFloat) -> some View {
        self.stroke(content, style: StrokeStyle(lineWidth: lineWidth, dash: [dashLengthValue, dashSpacingValue]))
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

