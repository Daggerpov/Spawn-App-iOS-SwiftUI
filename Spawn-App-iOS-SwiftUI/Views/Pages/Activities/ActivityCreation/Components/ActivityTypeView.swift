import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onNext: () -> Void
    
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: ActivityTypeViewModel
    @State private var navigateToManageType = false
    @State private var navigateToCreateType = false
    @State private var selectedActivityTypeForManagement: ActivityTypeDTO?
    
    // Simplified drag and drop state
    @State private var draggedItem: ActivityTypeDTO?
    @State private var targetItem: ActivityTypeDTO?
    
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
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $navigateToManageType) {
                if let selectedType = selectedActivityTypeForManagement {
                    NavigationStack {
                        ActivityTypeEditView(activityTypeDTO: selectedType)
                    }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("What are you up to?")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Choose an activity type or create a new one")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding(.top)
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
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.sortedActivityTypes, id: \.id) { activityTypeDTO in
                    activityTypeCardView(for: activityTypeDTO)
                }
                
                createNewActivityButton
            }
            .padding()
        }
        .onTapGesture {
            // Clear any residual drag state when tapping outside cards
            if draggedItem != nil {
                draggedItem = nil
                targetItem = nil
            }
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
                Task {
                    await viewModel.deleteActivityType(activityTypeDTO)
                }
            },
            onManage: {
                selectedActivityTypeForManagement = activityTypeDTO
                navigateToManageType = true
            },
            isDragging: draggedItem?.id == activityTypeDTO.id,
            isDropTarget: targetItem?.id == activityTypeDTO.id
        )
        .opacity(draggedItem?.id == activityTypeDTO.id ? 0.3 : (targetItem?.id == activityTypeDTO.id ? 0.3 : 1))
        .scaleEffect(draggedItem?.id == activityTypeDTO.id ? 0.8 : targetItem?.id == activityTypeDTO.id ? 1.1 : 1)
        .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 12))
        .onDrag {
            // Clear any previous drag states first
            targetItem = nil
            // Set draggedItem to the current item being dragged
            draggedItem = activityTypeDTO
            return NSItemProvider(object: activityTypeDTO.id.uuidString as NSString)
        }
        .onDrop(
            of: [.text],
            delegate: ActivityTypeDragDropDelegate(
                item: activityTypeDTO,
                draggedItem: $draggedItem,
                targetItem: $targetItem,
                viewModel: viewModel
            )
        )
    }
}

// MARK: - Drag and Drop Delegate
struct ActivityTypeDragDropDelegate: DropDelegate {
    let item: ActivityTypeDTO
    @Binding var draggedItem: ActivityTypeDTO?
    @Binding var targetItem: ActivityTypeDTO?
    let viewModel: ActivityTypeViewModel
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem, draggedItem.id != item.id else { return }
        targetItem = item
    }
    
    func dropExited(info: DropInfo) {
        if targetItem?.id == item.id {
            targetItem = nil
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem, draggedItem.id != item.id else { 
            self.draggedItem = nil
            targetItem = nil
            return false 
        }
        
        let sortedTypes = viewModel.sortedActivityTypes
        
        // Find the indices of the dragged item and the target item
        guard let fromIndex = sortedTypes.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = sortedTypes.firstIndex(where: { $0.id == item.id }),
              fromIndex != toIndex else { 
            self.draggedItem = nil
            targetItem = nil
            return false 
        }
        
        // Validation: Don't allow unpinned items to be moved before pinned items
        if !draggedItem.isPinned && item.isPinned {
            // Show error feedback
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            
            Task { @MainActor in
                viewModel.showError("Unpinned activities cannot be moved before pinned activities")
            }
            
            self.draggedItem = nil
            targetItem = nil
            return false
        }
        
        // Validation: Don't allow pinned items to be moved after unpinned items
        if draggedItem.isPinned && !item.isPinned {
            // Show error feedback
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            
            Task { @MainActor in
                viewModel.showError("Pinned activities cannot be moved after unpinned activities")
            }
            
            self.draggedItem = nil
            targetItem = nil
            return false
        }
        
        // Success feedback
        let successGenerator = UIImpactFeedbackGenerator(style: .light)
        successGenerator.impactOccurred()
        
        // Clear drag state immediately to prevent UI deformation
        self.draggedItem = nil
        targetItem = nil
        
        // Perform the reorder
        Task {
            await viewModel.reorderActivityTypes(from: fromIndex, to: toIndex)
        }
        
        return true
    }
}

struct ActivityTypeCard: View {
    let activityTypeDTO: ActivityTypeDTO
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onPin: () -> Void
    let onDelete: () -> Void
    let onManage: () -> Void
    
    // Drag and drop states
    let isDragging: Bool
    let isDropTarget: Bool
    
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
        } else if isDropTarget {
            return Color.green.opacity(0.2)
        } else {
            return adaptiveBackgroundColor
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.blue
        } else if isDropTarget {
            return Color.green
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected || isDropTarget {
            return 2
        } else {
            return 0
        }
    }
    
    private var shadowColor: Color {
        if isDragging {
            return Color.black.opacity(0.3)
        } else if isSelected {
            return Color.blue.opacity(0.3)
        } else {
            return Color.black.opacity(0.1)
        }
    }
    
    private var shadowRadius: CGFloat {
        if isDragging {
            return 8
        } else if isSelected {
            return 4
        } else {
            return 2
        }
    }
    
    private var shadowOffset: CGFloat {
        if isDragging {
            return 4
        } else if isSelected {
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
                VStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Text(activityTypeDTO.icon)
                            .font(.system(size: 24))
                    }
                    .frame(width: 32, height: 32)
                    
                    // Title and people count
                    VStack(spacing: 8) {
                        Text(activityTypeDTO.title)
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(adaptiveTitleColor)
                        
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
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowOffset
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
            VStack(spacing: 12) {
                Image("CreateNewActivityIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
                
                Text("Create New Activity")
                    .font(Font.custom("Onest", size: 12).weight(.medium))
                    .foregroundColor(adaptiveTextColor)
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
