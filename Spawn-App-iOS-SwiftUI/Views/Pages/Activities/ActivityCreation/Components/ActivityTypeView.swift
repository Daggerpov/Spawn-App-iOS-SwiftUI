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
            isDragging: draggedItem?.id == activityTypeDTO.id,
            onDragStart: {
                handleDragStart(for: activityTypeDTO)
            },
            onDragEnd: {
                handleDragEnd()
            }
        )
        .scaleEffect(draggedItem?.id == activityTypeDTO.id ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: draggedItem?.id == activityTypeDTO.id)
        .onDrop(of: [.text], isTargeted: nil) { providers, location in
            return handleDrop(for: activityTypeDTO, at: index)
        }
    }
    
    private func handleDragStart(for activityTypeDTO: ActivityTypeDTO) {
        draggedItem = activityTypeDTO
        isDragging = true
        showingDragFeedback = true
        
        // Haptic feedback for drag start
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
    
    private func handleDragEnd() {
        draggedItem = nil
        isDragging = false
        showingDragFeedback = false
        dragOffset = .zero
    }
    
    private func handleDrop(for activityTypeDTO: ActivityTypeDTO, at index: Int) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        let sourceIndex = viewModel.sortedActivityTypes.firstIndex(where: { $0.id == draggedItem.id }) ?? 0
        let destinationIndex = index
        
        // Don't perform reorder if indices are the same
        guard sourceIndex != destinationIndex else { return false }
        
        // Perform the reorder
        Task {
            await viewModel.reorderActivityTypes(from: sourceIndex, to: destinationIndex)
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
    var onDragStart: (() -> Void)?
    var onDragEnd: (() -> Void)?
    
    // Animation states for 3D effect
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    @State private var dragOffset = CGSize.zero
    @State private var longPressActivated = false
    
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
                        .fill(longPressActivated ? adaptiveBackgroundColor.opacity(0.8) : adaptiveBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    longPressActivated ? Color.blue.opacity(0.5) : 
                                    (isSelected ? universalSecondaryColor : Color.clear), 
                                    lineWidth: longPressActivated ? 1 : 2
                                )
                        )
                )
                .scaleEffect(scale)
                .shadow(
                    color: Color.black.opacity(longPressActivated ? 0.3 : 0.15),
                    radius: longPressActivated ? 12 : (isPressed ? 2 : 8),
                    x: 0,
                    y: longPressActivated ? 6 : (isPressed ? 2 : 4)
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
        .offset(dragOffset)
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: longPressActivated)
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
            DragGesture()
                .onChanged { value in
                    // Only allow drag if long press was activated
                    guard longPressActivated else { return }
                    
                    dragOffset = value.translation
                    
                    // Start drag operation if not already dragging
                    if !isDragging {
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
                return NSItemProvider(object: activityTypeDTO.id.uuidString as NSString)
            } else {
                return NSItemProvider()
            }
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
