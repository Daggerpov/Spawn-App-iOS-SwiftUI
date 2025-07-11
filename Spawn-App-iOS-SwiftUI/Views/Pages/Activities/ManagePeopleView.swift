import SwiftUI

struct ManagePeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var friendsViewModel: FriendsTabViewModel
    @StateObject private var activityTypeViewModel: ActivityTypeViewModel
    @ObservedObject var activityCreationViewModel = ActivityCreationViewModel.shared
    @State private var searchText = ""
    @State private var selectedFriends: Set<UUID> = []
    @State private var isSuggestedCollapsed = false
    
    let user: BaseUserDTO
    let activityTitle: String
    let activityTypeDTO: ActivityTypeDTO? // Add optional activity type for managing existing activity types
    
    init(user: BaseUserDTO, activityTitle: String = "Activity", activityTypeDTO: ActivityTypeDTO? = nil) {
        self.user = user
        self.activityTitle = activityTitle
        self.activityTypeDTO = activityTypeDTO
        self._friendsViewModel = StateObject(
            wrappedValue: FriendsTabViewModel(
                userId: user.id,
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService()
            )
        )
        self._activityTypeViewModel = StateObject(
            wrappedValue: ActivityTypeViewModel(
                userId: user.id,
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService()
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                universalBackgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, 12)
                    
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Search bar
                            searchBarView
                            
                            // Suggested friends section
                            if !suggestedFriends.isEmpty {
                                suggestedFriendsSection
                            }
                            
                            // Added friends section
                            if !addedFriends.isEmpty {
                                addedFriendsSection
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            friendsViewModel.connectSearchViewModel(searchViewModel)
            loadFriendsData()
            
            // Initialize selected friends based on context
            if let activityTypeDTO = activityTypeDTO {
                // For managing existing activity type - use associated friends
                selectedFriends = Set(activityTypeDTO.associatedFriends.map { $0.id })
            } else {
                // For activity creation - use activity creation view model
                selectedFriends = Set(activityCreationViewModel.selectedFriends.map { $0.id })
            }
        }
        .onDisappear {
            // Only update the activity creation view model if we're in activity creation mode
            if activityTypeDTO == nil {
                let selectedFriendObjects = friendsViewModel.friends.filter { selectedFriends.contains($0.id) }
                activityCreationViewModel.selectedFriends = selectedFriendObjects
            } else {
                // For activity type management, save changes to the activity type
                saveActivityTypeChanges()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 32) {
            // Back button
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(universalAccentColor)
            }
            
            // Title
            Text("Manage People - \(activityTitle)")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(universalAccentColor)
                .lineLimit(1)
            
            // Spacer to balance the layout
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Search Bar View
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(figmaBlack300)
            
            TextField("Search by name or handle...", text: $searchText)
                .font(.onestMedium(size: 16))
                .foregroundColor(universalAccentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(figmaBlack300, lineWidth: 0.5)
        )
    }
    
    // MARK: - Suggested Friends Section
    private var suggestedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                Text("Suggested")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isSuggestedCollapsed.toggle()
                    }
                }) {
                    Image(systemName: isSuggestedCollapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 16))
                        .foregroundColor(universalAccentColor)
                }
            }
            
            if !isSuggestedCollapsed {
                VStack(spacing: 12) {
                    ForEach(suggestedFriends.prefix(3), id: \.id) { friend in
                        friendRowView(friend: friend, isSelected: false)
                    }
                }
            }
        }
    }
    
    // MARK: - Added Friends Section
    private var addedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Text("Added (\(addedFriends.count))")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(figmaBlack300)
                
                Spacer()
                
                Button(action: {
                    selectedFriends.removeAll()
                }) {
                    Text("Clear Selection")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(figmaBlue)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(addedFriends, id: \.id) { friend in
                    friendRowView(friend: friend, isSelected: true)
                }
            }
        }
    }
    
    // MARK: - Friend Row View
    private func friendRowView(friend: FullFriendUserDTO, isSelected: Bool) -> some View {
        Button(action: {
            toggleFriendSelection(friend)
        }) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Profile picture
                    AsyncImage(url: URL(string: friend.profilePicture ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .shadow(
                        color: Color.black.opacity(0.25), 
                        radius: 4.06, 
                        x: 0, 
                        y: 1.62
                    )
                    
                    // Name and username
                    VStack(alignment: .leading, spacing: 2) {
                        Text(FormatterService.shared.formatName(user: friend.asBaseUser))
                            .font(.onestSemiBold(size: 14))
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(friend.username)")
                            .font(.onestSemiBold(size: 14))
                            .foregroundColor(universalAccentColor)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(figmaGreen)
                } else {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 24))
                        .foregroundColor(figmaBlack300)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    private var suggestedFriends: [FullFriendUserDTO] {
        let filtered = filteredFriends.filter { !selectedFriends.contains($0.id) }
        return Array(filtered.prefix(3))
    }
    
    private var addedFriends: [FullFriendUserDTO] {
        return filteredFriends.filter { selectedFriends.contains($0.id) }
    }
    
    private var filteredFriends: [FullFriendUserDTO] {
        if searchText.isEmpty {
            return friendsViewModel.friends
        }
        
        return friendsViewModel.friends.filter { friend in
            let name = friend.name?.lowercased() ?? ""
            let username = friend.username.lowercased()
            let search = searchText.lowercased()
            
            return name.contains(search) || username.contains(search)
        }
    }
    
    // MARK: - Methods
    private func loadFriendsData() {
        if AppCache.shared.friends.isEmpty {
            Task {
                await friendsViewModel.fetchAllData()
            }
        } else {
            friendsViewModel.friends = AppCache.shared.friends
            friendsViewModel.filteredFriends = AppCache.shared.friends
        }
    }
    
    private func toggleFriendSelection(_ friend: FullFriendUserDTO) {
        if selectedFriends.contains(friend.id) {
            selectedFriends.remove(friend.id)
        } else {
            selectedFriends.insert(friend.id)
        }
    }
    
    private func saveActivityTypeChanges() {
        guard let activityTypeDTO = activityTypeDTO else { return }
        
        // Get the original friend IDs
        let originalFriendIds = Set(activityTypeDTO.associatedFriends.map { $0.id })
        
        // Check if there are any changes to save
        if selectedFriends == originalFriendIds {
            print("No changes to save for activity type: \(activityTypeDTO.title)")
            return
        }
        
        // Create updated associated friends list
        let updatedAssociatedFriends = friendsViewModel.friends
            .filter { selectedFriends.contains($0.id) }
            .map { $0.asBaseUser }
        
        // Create updated activity type DTO
        let updatedActivityTypeDTO = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: activityTypeDTO.title,
            icon: activityTypeDTO.icon,
            associatedFriends: updatedAssociatedFriends,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
        
        // Update the activity type using the view model
        activityTypeViewModel.optimisticallyUpdateActivityType(updatedActivityTypeDTO)
        
        print("✅ Saved changes to activity type: \(activityTypeDTO.title)")
        print("   Updated associated friends count: \(updatedAssociatedFriends.count)")
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    ManagePeopleView(user: .danielAgapov, activityTitle: "Chill", activityTypeDTO: nil)
} 