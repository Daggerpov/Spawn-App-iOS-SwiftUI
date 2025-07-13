import SwiftUI

struct ActivityTypeFriendSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCache: AppCache
    @State private var searchText = ""
    @State private var selectedFriends: Set<UUID> = []
    @State private var isLoading = false
    
    let activityTypeDTO: ActivityTypeDTO
    let onComplete: (ActivityTypeDTO) -> Void
    
    var body: some View {
        ZStack {
            // Background - now adaptive
            universalBackgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search bar
                searchBarView
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                // Friends list
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Your Friends header
                        friendsHeaderView
                        
                        // Friends list
                        if filteredFriends.isEmpty {
                            emptyStateView
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredFriends, id: \.id) { friend in
                                    friendRowView(friend: friend)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            
            // Loading overlay
            if isLoading {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: universalAccentColor))
                        .scaleEffect(1.5)
                    
                    Text("Creating activity type...")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalAccentColor)
                        .padding(.top, 16)
                }
            }
        }
        .navigationTitle("Select friends to add to this type")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { saveActivityType() }) {
                    Text("Save")
                        .font(.onestSemiBold(size: 16))
                        .foregroundColor(figmaBlue)
                }
                .disabled(isLoading)
            }
        }
    }
    
    // MARK: - View Components
    
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(universalPlaceHolderTextColor)
            
            TextField("Search by name or handle...", text: $searchText)
                .font(.onestMedium(size: 16))
                .foregroundColor(universalAccentColor)
                .placeholder(when: searchText.isEmpty) {
                    Text("Search by name or handle...")
                        .font(.onestMedium(size: 16))
                        .foregroundColor(universalPlaceHolderTextColor)
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(universalPlaceHolderTextColor, lineWidth: 0.5)
        )
    }
    
    private var friendsHeaderView: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Text("Your Friends (\(availableFriends.count))")
                .font(.onestMedium(size: 16))
                .foregroundColor(universalPlaceHolderTextColor)
            
            Spacer()
            
            Button(action: {
                if selectedFriends.isEmpty {
                    // Select all
                    selectedFriends = Set(availableFriends.map { $0.id })
                } else {
                    // Clear selection
                    selectedFriends.removeAll()
                }
            }) {
                if selectedFriends.isEmpty {
                    Text("Select All")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(figmaBlue)
                } else {
                    Text("Clear Selected (\(selectedFriends.count))")
                        .font(.onestMedium(size: 14))
                        .foregroundColor(figmaBittersweetOrange)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("No friends found")
                .font(.onestMedium(size: 16))
                .foregroundColor(universalPlaceHolderTextColor)
            
            Text("Try adjusting your search or add some friends!")
                .font(.onestMedium(size: 14))
                .foregroundColor(universalPlaceHolderTextColor)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    private func friendRowView(friend: FullFriendUserDTO) -> some View {
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
                    .shadow(color: Color.black.opacity(0.25), radius: 4.06, x: 0, y: 1.62)
                    
                    // Name and username
                    VStack(alignment: .leading, spacing: 2) {
                        Text(friend.name ?? "Unknown")
                            .font(.onestSemiBold(size: 14))
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(friend.username)")
                            .font(.onestSemiBold(size: 14))
                            .foregroundColor(universalAccentColor)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if selectedFriends.contains(friend.id) {
                    Circle()
                        .fill(Color(red: 0.19, green: 0.85, blue: 0.59))
                        .frame(width: 27, height: 27)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        )
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 27, height: 27)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.52, green: 0.49, blue: 0.49), lineWidth: 0.71)
                        )
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
    
    private var availableFriends: [FullFriendUserDTO] {
        appCache.friends
    }
    
    private var filteredFriends: [FullFriendUserDTO] {
        if searchText.isEmpty {
            return availableFriends
        }
        
        return availableFriends.filter { friend in
            let name = friend.name?.lowercased() ?? ""
            let username = friend.username.lowercased()
            let search = searchText.lowercased()
            
            return name.contains(search) || username.contains(search)
        }
    }
    
    // MARK: - Methods
    
    private func toggleFriendSelection(_ friend: FullFriendUserDTO) {
        if selectedFriends.contains(friend.id) {
            selectedFriends.remove(friend.id)
        } else {
            selectedFriends.insert(friend.id)
        }
    }
    
    private func saveActivityType() {
        isLoading = true
        
        // Convert selected friend IDs to BaseUserDTO objects
        let selectedFriendObjects = appCache.friends.compactMap { friend in
            if selectedFriends.contains(friend.id) {
                return BaseUserDTO.from(friendUser: friend)
            }
            return nil
        }
        
        // Create updated activity type with selected friends
        let updatedActivityType = ActivityTypeDTO(
            id: activityTypeDTO.id,
            title: activityTypeDTO.title,
            icon: activityTypeDTO.icon,
            associatedFriends: selectedFriendObjects,
            orderNum: activityTypeDTO.orderNum,
            isPinned: activityTypeDTO.isPinned
        )
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            onComplete(updatedActivityType)
            dismiss()
        }
    }
}

@available(iOS 17, *)
#Preview {
    ActivityTypeFriendSelectionView(
        activityTypeDTO: ActivityTypeDTO.createNew(),
        onComplete: { _ in }
    )
    .environmentObject(AppCache.shared)
} 