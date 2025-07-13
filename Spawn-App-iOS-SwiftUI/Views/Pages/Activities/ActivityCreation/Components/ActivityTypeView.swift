import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedActivityType: ActivityTypeDTO?
    let onNext: () -> Void
    
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: ActivityTypeViewModel
    @State private var navigateToManageType = false
    @State private var navigateToCreateType = false
    @State private var selectedActivityTypeForManagement: ActivityTypeDTO?
    
    // Drag and drop state
    @State private var draggedItem: ActivityTypeDTO?
    @State private var isDragging = false
    @State private var dragOffset = CGSize.zero
    @State private var showingDragFeedback = false
    @State private var dragTargetIndex: Int?
    @State private var dragOverItem: ActivityTypeDTO?
    
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
            .navigationDestination(isPresented: $navigateToManageType) {
                if let activityType = selectedActivityTypeForManagement {
                    ActivityTypeManagementView(activityTypeDTO: activityType)
                }
            }
            .navigationDestination(isPresented: $navigateToCreateType) {
                ActivityTypeEditView(activityTypeDTO: ActivityTypeDTO.createNew()) {
                    navigateToCreateType = false
                }
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
            LazyVGrid(columns: gridColumns, spacing: 16) {
                ForEach(viewModel.sortedActivityTypes, id: \.id) { activityTypeDTO in
                    activityTypeCardView(for: activityTypeDTO)
                }
                
                createNewActivityButton
            }
            .padding()
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
    
    private var gridColumns: [GridItem] {
        [
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
    }
    
    private var createNewActivityButton: some View {
        CreateNewActivityTypeCard(onCreateNew: {
            navigateToCreateType = true
        })
    }
    
    private func activityTypeCardView(for activityTypeDTO: ActivityTypeDTO) -> some View {
        let index = viewModel.sortedActivityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) ?? 0
        let isDraggedItem = draggedItem?.id == activityTypeDTO.id
        let isDropTarget = dragOverItem?.id == activityTypeDTO.id
        
        // Check if this would be an invalid drop target
        let isInvalidDropTarget = isDropTarget && draggedItem != nil && 
                                  !draggedItem!.isPinned && activityTypeDTO.isPinned
        
        return ActivityTypeCard(
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
            isDragging: isDraggedItem,
            isDropTarget: isDropTarget,
            isInvalidDropTarget: isInvalidDropTarget,
            onDragStart: {
                handleDragStart(for: activityTypeDTO)
            },
            onDragEnd: {
                handleDragEnd()
            }
        )
        .scaleEffect(isDraggedItem ? 1.05 : 1.0)
        .opacity(isDraggedItem ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDraggedItem)
        .animation(.easeInOut(duration: 0.15), value: isDropTarget)
        .onDrop(of: [.text], isTargeted: .constant(isDropTarget)) { providers, location in
            return handleDrop(for: activityTypeDTO, at: index)
        }
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            if !isDropTarget {
                dragOverItem = activityTypeDTO
            }
            return false
        }
    }
    
    private func handleDragStart(for activityTypeDTO: ActivityTypeDTO) {
        draggedItem = activityTypeDTO
        isDragging = true
        showingDragFeedback = true
        dragOverItem = nil
        
        // Haptic feedback for drag start
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    private func handleDragEnd() {
        // Reset all drag states
        draggedItem = nil
        isDragging = false
        showingDragFeedback = false
        dragOffset = .zero
        dragTargetIndex = nil
        dragOverItem = nil
    }
    
    private func handleDrop(for activityTypeDTO: ActivityTypeDTO, at index: Int) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        let sourceIndex = viewModel.sortedActivityTypes.firstIndex(where: { $0.id == draggedItem.id }) ?? 0
        let destinationIndex = index
        
        // Don't perform reorder if indices are the same
        guard sourceIndex != destinationIndex else { 
            handleDragEnd()
            return false 
        }
        
        let destinationItem = viewModel.sortedActivityTypes[destinationIndex]
        
        // Validate constraints before allowing drop
        if !draggedItem.isPinned && destinationItem.isPinned {
            // Show error feedback
            let errorGenerator = UINotificationFeedbackGenerator()
            errorGenerator.notificationOccurred(.error)
            
            // Clear drag state
            handleDragEnd()
            
            // Show error message
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.showError("Unpinned activities cannot be moved before pinned activities")
            }
            return false
        }
        
        // Success feedback
        let successGenerator = UIImpactFeedbackGenerator(style: .light)
        successGenerator.impactOccurred()
        
        // Perform the reorder
        Task {
            await viewModel.reorderActivityTypes(from: sourceIndex, to: destinationIndex)
        }
        
        // Clear drag state
        handleDragEnd()
        
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
    let isInvalidDropTarget: Bool
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?
    
    // Animation states for 3D effect
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var dragOffset = CGSize.zero
    @State private var longPressActivated = false
    @State private var wiggleOffset: CGFloat = 0
    
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
            return Color.white
        @unknown default:
            return Color.white
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

    // Computed properties to break down complex expressions
    private var borderColor: Color {
        if longPressActivated {
            return Color.blue.opacity(0.5)
        } else if isInvalidDropTarget {
            return Color.red.opacity(0.8)
        } else if isDropTarget {
            return Color.blue.opacity(0.8)
        } else if isSelected {
            return universalSecondaryColor
        } else {
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        if longPressActivated || isDropTarget || isInvalidDropTarget {
            return 2
        } else if isSelected {
            return 2
        } else {
            return 0
        }
    }
    
    private var shadowColor: Color {
        let opacity = (longPressActivated || isDragging) ? 0.3 : 0.15
        return Color.black.opacity(opacity)
    }
    
    private var shadowRadius: CGFloat {
        if longPressActivated || isDragging {
            return 12
        } else if isPressed {
            return 2
        } else {
            return 8
        }
    }
    
    private var shadowOffset: CGFloat {
        if longPressActivated || isDragging {
            return 6
        } else if isPressed {
            return 2
        } else {
            return 4
        }
    }
    
    private var dropTargetFillColor: Color {
        return isInvalidDropTarget ? Color.red.opacity(0.1) : Color.blue.opacity(0.1)
    }
    
    private var dropTargetOpacity: Double {
        return (isDropTarget || isInvalidDropTarget) ? 1 : 0
    }
    
    private var backgroundFillColor: Color {
        return longPressActivated ? adaptiveBackgroundColor.opacity(0.8) : adaptiveBackgroundColor
    }

    var body: some View {
        Button(action: { 
            // Only allow selection if not in drag mode
            guard !longPressActivated else { return }
            
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedActivityType = activityTypeDTO
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
                        .fill(backgroundFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: borderWidth)
                        )
                )
                .scaleEffect(scale)
                .shadow(
                    color: shadowColor,
                    radius: shadowRadius,
                    x: 0,
                    y: shadowOffset
                )
                .overlay(
                    // Drop target indicator
                    RoundedRectangle(cornerRadius: 12)
                        .fill(dropTargetFillColor)
                        .opacity(dropTargetOpacity)
                        .animation(.easeInOut(duration: 0.2), value: dropTargetOpacity)
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
                
                // Drag indicator overlay when in drag mode
                if longPressActivated {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.arrow.down")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: dragOffset.width + wiggleOffset, y: dragOffset.height)
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: longPressActivated)
        .onAppear {
            // Start wiggle animation when in drag mode
            if isDragging && !longPressActivated {
                startWiggleAnimation()
            }
        }
        .onChange(of: isDragging) { newValue in
            if newValue && !longPressActivated {
                startWiggleAnimation()
            } else {
                stopWiggleAnimation()
            }
        }
        .onChange(of: isInvalidDropTarget) { newValue in
            if newValue {
                // Provide haptic feedback for invalid drop target
                let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                impactGenerator.impactOccurred()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            scale = pressing ? 0.95 : 1.0
            
            // Additional haptic feedback for press down
            if pressing {
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.selectionChanged()
            }
        }, perform: {
            // Activate drag mode after long press
            longPressActivated = true
            
            // Stronger haptic feedback for drag activation
            let impactGenerator = UIImpactFeedbackGenerator(style: .heavy)
            impactGenerator.impactOccurred()
        })
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    // Only allow drag if long press was activated
                    guard longPressActivated else { return }
                    
                    dragOffset = value.translation
                    
                    // Start drag operation if not already dragging and we've moved enough
                    if !isDragging && 
                       (abs(value.translation.width) > 10 || abs(value.translation.height) > 10) {
                        onDragStart?()
                    }
                }
                .onEnded { value in
                    // Reset drag state
                    longPressActivated = false
                    dragOffset = .zero
                    
                    if isDragging {
                        onDragEnd?()
                    }
                }
        )
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
        .onDrag {
            // Always return an NSItemProvider, but only populate it when drag is active
            if longPressActivated {
                // Start drag operation when SwiftUI drag begins
                if !isDragging {
                    onDragStart?()
                }
                return NSItemProvider(object: activityTypeDTO.id.uuidString as NSString)
            } else {
                return NSItemProvider()
            }
        }
    }
    
    // MARK: - Wiggle Animation Methods
    private func startWiggleAnimation() {
        withAnimation(.easeInOut(duration: 0.1).repeatForever(autoreverses: true)) {
            wiggleOffset = 1.0
        }
    }
    
    private func stopWiggleAnimation() {
        withAnimation(.easeInOut(duration: 0.1)) {
            wiggleOffset = 0
        }
    }
}

struct CreateNewActivityTypeCard: View {
    let onCreateNew: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states for 3D effect
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
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
        Button(action: {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onCreateNew()
            }
        }) {
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
			.padding(.vertical, -4)
			.frame(maxWidth: .infinity)
            .background(cardBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 0.5)
            )
            .scaleEffect(scale)
            .shadow(
                color: Color.black.opacity(0.15),
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            scale = pressing ? 0.95 : 1.0
            
            // Additional haptic feedback for press down
            if pressing {
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.selectionChanged()
            }
        }, perform: {})
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
