import SwiftUI

struct ActivityTypeView: View {
    @Binding var selectedType: ActivityType?
    let onNext: () -> Void
    let onBack: (() -> Void)?
    
    // Backend integration
    @State private var activityTypes: [ActivityTypeDTO] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    
    // API Service
    private let apiService: IAPIService
    private let userId: UUID
    
    init(selectedType: Binding<ActivityType?>, onNext: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        self._selectedType = selectedType
        self.onNext = onNext
        self.onBack = onBack
        self.userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        
        // Initialize API service based on mocking state
        self.apiService = MockAPIService.isMocking 
            ? MockAPIService(userId: userId) 
            : APIService()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button at the top (if provided)
            if let onBack = onBack {
                HStack {
                    ActivityBackButton {
                        onBack()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            Text("What are you up to?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(universalAccentColor)
                .padding(.horizontal)
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading activity types...")
                    Spacer()
                }
            } else if let errorMessage = errorMessage {
                VStack {
                    Spacer()
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await fetchActivityTypes()
                        }
                    }
                    .padding()
                    .background(universalSecondaryColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    Spacer()
                }
            } else {
                activityTypeGrid
            }
            
            ActivityNextStepButton(
                isEnabled: selectedType != nil
            ) {
                onNext()
            }
        }
        .background(universalBackgroundColor)
        .onAppear {
            Task {
                await fetchActivityTypes()
            }
        }
    }
    
    private var activityTypeGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(sortedActivityTypes, id: \.id) { activityTypeDTO in
                    ActivityTypeCard(
                        activityTypeDTO: activityTypeDTO,
                        selectedType: $selectedType,
                        onPin: {
                            Task {
                                await togglePin(for: activityTypeDTO)
                            }
                        },
                        onManage: {
                            // Handle manage action
                            print("Manage \(activityTypeDTO.title)")
                        },
                        onDelete: {
                            // Handle delete action
                            print("Delete \(activityTypeDTO.title)")
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    // Computed property to sort activity types with pinned ones first
    private var sortedActivityTypes: [ActivityTypeDTO] {
        activityTypes.sorted { first, second in
            // Pinned types come first
            if first.isPinned != second.isPinned {
                return first.isPinned
            }
            // If both are pinned or both are not pinned, sort by orderNum
            return first.orderNum < second.orderNum
        }
    }
    
    private func fetchActivityTypes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid URL"
                }
                return
            }
            
            let fetchedTypes: [ActivityTypeDTO] = try await apiService.fetchData(
                from: url,
                parameters: nil
            )
            
            await MainActor.run {
                self.activityTypes = fetchedTypes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to load activity types"
                print("❌ Error fetching activity types: \(error)")
            }
        }
    }
    
    private func togglePin(for activityTypeDTO: ActivityTypeDTO) async {
        let newPinStatus = !activityTypeDTO.isPinned
        
        do {
            let endpoint = "activity-type/pin/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for pin toggle")
                return
            }
            
            let pinUpdateDTO = ActivityTypePinUpdateDTO(
                activityTypeId: activityTypeDTO.id,
                isPinned: newPinStatus
            )
            
            let _: EmptyResponse = try await apiService.updateData(
                pinUpdateDTO,
                to: url,
                parameters: nil
            )
            
            // Update local state
            await MainActor.run {
                if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                    activityTypes[index].isPinned = newPinStatus
                }
            }
        } catch {
            print("❌ Error toggling pin status: \(error)")
            // Could show an alert to the user here
        }
    }
}

struct ActivityTypeCard: View {
    let activityTypeDTO: ActivityTypeDTO
    @Binding var selectedType: ActivityType?
    let onPin: () -> Void
    let onManage: () -> Void
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
            
            Button(action: onManage) {
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
    
    ActivityTypeView(
        selectedType: $selectedType,
        onNext: {
            print("Next step tapped")
        }
    )
    .environmentObject(appCache)
} 