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
    
    // Convert ActivityTypeDTO to ActivityType for selection comparison
    private var activityType: ActivityType? {
        ActivityType.allCases.first { $0.rawValue == activityTypeDTO.title }
    }
    
    private var isSelected: Bool {
        selectedType == activityType
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
                            .foregroundColor(figmaBlack300)
                    }
                    
                    Text(activityTypeDTO.title)
                        .font(.headline)
                        .foregroundColor(universalAccentColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? universalSecondaryColor.opacity(0.1) : Color.gray.opacity(0.05))
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
            
            NavigationLink(destination: ActivityTypeManagementView(activityTypeDTO: activityTypeDTO)) {
                Label("Manage Type", systemImage: "slider.horizontal.3")
            }
            
            Button(action: onDelete) {
                Label("Delete Type", systemImage: "trash")
            }
            .foregroundColor(.red)
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedType: ActivityType? = .foodAndDrink
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
