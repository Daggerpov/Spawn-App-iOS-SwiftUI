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
                        onDelete: {
                            Task {
                                await deleteActivityType(activityTypeDTO)
                            }
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
        
        // Update the activity type locally first
        await MainActor.run {
            if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                activityTypes[index].isPinned = newPinStatus
            }
        }
        
        do {
            let endpoint = "activity-type/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for batch update")
                return
            }
            
            // Create a copy of the activity type with the new pin status
            let updatedActivityType = ActivityTypeDTO(
                id: activityTypeDTO.id,
                title: activityTypeDTO.title,
                icon: activityTypeDTO.icon,
                associatedFriends: activityTypeDTO.associatedFriends,
                orderNum: activityTypeDTO.orderNum,
                isPinned: newPinStatus
            )
            
            let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                updatedActivityTypes: [updatedActivityType],
                deletedActivityTypeIds: []
            )
            
            let _: BatchActivityTypeUpdateDTO = try await apiService.updateData(
                batchUpdateDTO,
                to: url,
                parameters: nil
            )
            
            print("✅ Successfully updated pin status for activity type: \(activityTypeDTO.title)")
        } catch {
            print("❌ Error updating pin status: \(error)")
            // Revert the local change on error
            await MainActor.run {
                if let index = activityTypes.firstIndex(where: { $0.id == activityTypeDTO.id }) {
                    activityTypes[index].isPinned = !newPinStatus
                }
            }
        }
    }
    
    private func deleteActivityType(_ activityTypeDTO: ActivityTypeDTO) async {
        do {
            let endpoint = "activity-type/\(activityTypeDTO.id)/user/\(userId)"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                print("❌ Error: Invalid URL for delete")
                return
            }
            
            // Define EmptyObject for delete request
            struct EmptyObject: Encodable {}
            
            try await apiService.deleteData(from: url, parameters: nil, object: EmptyObject())
            
            // Remove from local state
            await MainActor.run {
                activityTypes.removeAll { $0.id == activityTypeDTO.id }
            }
        } catch {
            print("❌ Error deleting activity type: \(error)")
            // Could show an alert to the user here
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
