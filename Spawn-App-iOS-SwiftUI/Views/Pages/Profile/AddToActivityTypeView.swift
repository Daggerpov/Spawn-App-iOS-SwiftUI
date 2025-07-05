import SwiftUI

struct AddToActivityTypeView: View {
    let user: Nameable
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedActivityTypes: Set<UUID> = []
    @StateObject private var viewModel = AddToActivityTypeViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                universalBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Main content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile section with glow effect
                            profileSection
                            
                                                // Activity type grid or loading state
                    if viewModel.isLoading {
                        ProgressView("Loading activity types...")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor)
                            .padding()
                    } else {
                        activityTypeGrid
                    }
                    
                    // Error message display
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.onestRegular(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Spacer to push save button to bottom
                    Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                    
                    // Save button at bottom
                    saveButton
                        .padding(.horizontal, 16)
                        .padding(.bottom, 34) // Account for tab bar
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(universalAccentColor)
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Add to Activity Type")
                    .font(.onestMedium(size: 20))
                    .foregroundColor(universalAccentColor)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadActivityTypes()
            }
        }
    }
    
    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile picture with glow effect
            ZStack {
                // Glow effect circles
                Group {
                    Circle()
                        .fill(Color.yellow.opacity(0.4))
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .offset(x: 8, y: -18)
                    
                    Circle()
                        .fill(Color.pink.opacity(0.4))
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .offset(x: -9, y: 0)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .offset(x: 8, y: 0)
                    
                    Circle()
                        .fill(Color.green.opacity(0.4))
                        .frame(width: 60, height: 60)
                        .blur(radius: 18)
                        .offset(x: -9, y: -18)
                }
                
                // Profile picture
                if let profilePicture = user.profilePicture {
                    AsyncImage(url: URL(string: profilePicture)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 67, height: 67)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 67, height: 67)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            )
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 67, height: 67)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // User info text
            VStack(spacing: 2) {
                Text("Adding \(FormatterService.shared.formatName(user: user)) to \(selectedActivityTypes.count) activity types")
                    .font(.onestSemiBold(size: 16))
                    .foregroundColor(universalAccentColor)
                
                Text(selectedActivityTypesText)
                    .font(.onestRegular(size: 12))
                    .foregroundColor(figmaBlack400)
            }
        }
    }
    
    private var selectedActivityTypesText: String {
        let selectedTypes = viewModel.activityTypes.filter { selectedActivityTypes.contains($0.id) }
        if selectedTypes.isEmpty {
            return "No activity types selected"
        }
        return selectedTypes.map { $0.title }.joined(separator: " & ")
    }
    
    private var activityTypeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 16) {
            ForEach(viewModel.activityTypes, id: \.id) { activityType in
                ActivityTypeSelectionCard(
                    activityType: activityType,
                    isSelected: selectedActivityTypes.contains(activityType.id)
                ) {
                    toggleSelection(for: activityType)
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            // Handle save action
            Task {
                await saveSelectedActivityTypes()
            }
        }) {
            Text(viewModel.isLoading ? "Saving..." : "Save")
                .font(.onestBold(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(universalSecondaryColor)
                .cornerRadius(16)
        }
        .disabled(selectedActivityTypes.isEmpty || viewModel.isLoading)
        .opacity(selectedActivityTypes.isEmpty || viewModel.isLoading ? 0.6 : 1.0)
    }
    
    private func toggleSelection(for activityType: ActivityTypeDTO) {
        if selectedActivityTypes.contains(activityType.id) {
            selectedActivityTypes.remove(activityType.id)
        } else {
            selectedActivityTypes.insert(activityType.id)
        }
    }
    
    private func saveSelectedActivityTypes() async {
        let success = await viewModel.addUserToActivityTypes(user, selectedActivityTypeIds: selectedActivityTypes)
        
        await MainActor.run {
            if success {
                presentationMode.wrappedValue.dismiss()
            }
            // If not successful, the error message will be shown in the UI
            // The viewModel.errorMessage will be displayed to the user
        }
    }
}

struct ActivityTypeSelectionCard: View {
    let activityType: ActivityTypeDTO
    let isSelected: Bool
    let onTap: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    // Dynamic colors based on selection state
    private var iconColor: Color {
        if isSelected {
            return colorScheme == .dark ? .white : Color(red: 0.07, green: 0.07, blue: 0.07)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.5) : Color(red: 0.07, green: 0.07, blue: 0.07).opacity(0.4)
        }
    }
    
    private var titleColor: Color {
        if isSelected {
            return colorScheme == .dark ? .white : Color(red: 0.07, green: 0.07, blue: 0.07)
        } else {
            return colorScheme == .dark ? Color.white.opacity(0.5) : Color(red: 0.07, green: 0.07, blue: 0.07).opacity(0.4)
        }
    }
    
    private var peopleCountColor: Color {
        if isSelected {
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        } else {
            return Color(red: 0.52, green: 0.49, blue: 0.49).opacity(0.4)
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return colorScheme == .dark ? 
                   Color(red: 0.24, green: 0.23, blue: 0.23) : 
                   Color(red: 0.95, green: 0.93, blue: 0.93)
        } else {
            return colorScheme == .dark ? 
                   Color(red: 0.24, green: 0.23, blue: 0.23).opacity(0.5) : 
                   Color(red: 0.95, green: 0.93, blue: 0.93).opacity(0.5)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon
                Text(activityType.icon)
                    .font(.onestBold(size: 34))
                    .foregroundColor(iconColor)
                
                VStack(spacing: 2) {
                    // Title
                    Text(activityType.title)
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(titleColor)
                    
                    // People count
                    Text("\(activityType.associatedFriends.count) people")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(peopleCountColor)
                }
            }
            .padding(16)
            .frame(width: 111, height: 111)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
            )
            .shadow(
                color: isSelected ? (colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1)) : Color.clear,
                radius: isSelected ? 4 : 0,
                x: 0,
                y: isSelected ? 2 : 0
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .opacity(isSelected ? 1.0 : 0.6)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// ViewModel for managing activity types
class AddToActivityTypeViewModel: ObservableObject {
    @Published var activityTypes: [ActivityTypeDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: IAPIService
    private let userId: UUID
    
    init(userId: UUID? = nil) {
        self.userId = userId ?? UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        self.apiService = MockAPIService.isMocking
            ? MockAPIService(userId: self.userId) : APIService()
    }
    
    func loadActivityTypes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Fetch activity types from the API
            let endpoint = "\(userId)/activity-types"
            guard let url = URL(string: APIService.baseURL + endpoint) else {
                await MainActor.run {
                    self.errorMessage = "Invalid URL"
                    self.isLoading = false
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
                self.errorMessage = "Failed to load activity types: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func addUserToActivityTypes(_ userToAdd: Nameable, selectedActivityTypeIds: Set<UUID>) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        defer {
            Task {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        
        do {
            // Create updated activity types with the user added
            var updatedTypes: [ActivityTypeDTO] = []
            
            for activityType in activityTypes {
                if selectedActivityTypeIds.contains(activityType.id) {
                    // Convert Nameable to BaseUserDTO
                    let userDTO: BaseUserDTO
                    if let baseUser = userToAdd as? BaseUserDTO {
                        userDTO = baseUser
                    } else {
                        // Create a BaseUserDTO from the Nameable properties
                        // For users that aren't BaseUserDTO, we'll use default values for missing properties
                        userDTO = BaseUserDTO(
                            id: userToAdd.id,
                            username: userToAdd.username,
                            profilePicture: userToAdd.profilePicture,
                            name: userToAdd.name,
                            bio: nil, // Default value since it's not part of Nameable
                            email: "" // Default value since it's not part of Nameable
                        )
                    }

                    // Add user to associated friends if not already present
                    if !activityType.associatedFriends.contains(where: { $0.id == userDTO.id }) {
                        let updatedActivityType = ActivityTypeDTO(
                            id: activityType.id,
                            title: activityType.title,
                            icon: activityType.icon,
                            associatedFriends: activityType.associatedFriends + [userDTO],
                            orderNum: activityType.orderNum,
                            isPinned: activityType.isPinned
                        )
                        updatedTypes.append(updatedActivityType)
                    }
                }
            }
            
            if !updatedTypes.isEmpty {
                // Use batch update to save the changes
                let endpoint = "\(userId)/activity-types"
                guard let url = URL(string: APIService.baseURL + endpoint) else {
                    await MainActor.run {
                        self.errorMessage = "Invalid URL"
                    }
                    return false
                }
                
                let batchUpdateDTO = BatchActivityTypeUpdateDTO(
                    updatedActivityTypes: updatedTypes,
                    deletedActivityTypeIds: []
                )
                
                let updatedActivityTypesReturned: [ActivityTypeDTO] = try await apiService.updateData(
                    batchUpdateDTO,
                    to: url,
                    parameters: nil
                )
                
                await MainActor.run {
                    self.activityTypes = updatedActivityTypesReturned
                }
                
                return true
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to save activity types: \(error.localizedDescription)"
            }
            return false
        }
    }
}

#Preview {
    AddToActivityTypeView(user: BaseUserDTO.danielAgapov)
} 
