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
                            
                            // Activity type grid
                            activityTypeGrid
                            
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
            Text("Save")
                .font(.onestBold(size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(universalSecondaryColor)
                .cornerRadius(16)
        }
        .disabled(selectedActivityTypes.isEmpty)
        .opacity(selectedActivityTypes.isEmpty ? 0.6 : 1.0)
    }
    
    private func toggleSelection(for activityType: ActivityTypeDTO) {
        if selectedActivityTypes.contains(activityType.id) {
            selectedActivityTypes.remove(activityType.id)
        } else {
            selectedActivityTypes.insert(activityType.id)
        }
    }
    
    private func saveSelectedActivityTypes() async {
        // This would typically make an API call to save the user's activity type associations
        // For now, we'll just dismiss the view
        await MainActor.run {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ActivityTypeSelectionCard: View {
    let activityType: ActivityTypeDTO
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon
                Text(activityType.icon)
                    .font(.onestBold(size: 34))
                    .foregroundColor(.white)
                
                VStack(spacing: 2) {
                    // Title
                    Text(activityType.title)
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(.white)
                    
                    // People count
                    Text("\(activityType.associatedFriends.count) people")
                        .font(.onestRegular(size: 13))
                        .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                }
            }
            .padding(16)
            .frame(width: 111, height: 111)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? universalSecondaryColor : Color(red: 0.24, green: 0.23, blue: 0.23))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// ViewModel for managing activity types
class AddToActivityTypeViewModel: ObservableObject {
    @Published var activityTypes: [ActivityTypeDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadActivityTypes() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // In a real app, this would fetch from an API
            // For now, we'll use mock data with predefined activity types
            let mockTypes = [
                ActivityTypeDTO(id: UUID(), title: "Run", icon: "🏃‍♂️", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(3)), orderNum: 0),
                ActivityTypeDTO(id: UUID(), title: "Cook", icon: "🧑‍🍳", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(5)), orderNum: 1),
                ActivityTypeDTO(id: UUID(), title: "Gaming", icon: "🎮", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(4)), orderNum: 2),
                ActivityTypeDTO(id: UUID(), title: "Work", icon: "💻", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(6)), orderNum: 3),
                ActivityTypeDTO(id: UUID(), title: "Study", icon: "📖", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(2)), orderNum: 4),
                ActivityTypeDTO(id: UUID(), title: "Basketball", icon: "🏀", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(7)), orderNum: 5),
                ActivityTypeDTO(id: UUID(), title: "Dance", icon: "🕺", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(3)), orderNum: 6),
                ActivityTypeDTO(id: UUID(), title: "Hike", icon: "🏔️", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(5)), orderNum: 7),
                ActivityTypeDTO(id: UUID(), title: "Food", icon: "🍣", associatedFriends: Array(BaseUserDTO.mockUsers.prefix(4)), orderNum: 8)
            ]
            
            await MainActor.run {
                self.activityTypes = mockTypes
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

#Preview {
    AddToActivityTypeView(user: BaseUserDTO.danielAgapov)
} 