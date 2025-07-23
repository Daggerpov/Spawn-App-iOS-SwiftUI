//
//  InviteView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteView: View {
    let user: BaseUserDTO
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var activityCreationViewModel = ActivityCreationViewModel.shared
    @StateObject private var searchViewModel = SearchViewModel()
    
    // Add view models for friends
    @StateObject private var friendsViewModel: FriendsTabViewModel
    @ObservedObject private var appCache = AppCache.shared

    init(user: BaseUserDTO) {
        self.user = user

        // Initialize the view models with _: syntax for StateObject
        self._friendsViewModel = StateObject(
            wrappedValue: FriendsTabViewModel(
                userId: user.id,
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService()
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("Invite friends!")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 30)

                // Friends section
                ScrollView {
                    VStack(spacing: 20) {
                        // Invited section
                        if !activityCreationViewModel.selectedFriends.isEmpty {
                            invitedFriendsSection
                        }

                        // Suggested friends section - now using real friends data
                        friendsListSection
                    }
                    .padding(.horizontal)
                }

                // Search bar at bottom
                VStack {
                    // Search bar
                    SearchView(searchPlaceholderText: "Search", viewModel: searchViewModel)
                        .padding(.top)

                    // Done button
                    Button(action: {
                        dismiss()
                    }) {
                        Text(
                            "Done Inviting (\(activityCreationViewModel.selectedFriends.count) friends)"
                        )
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(universalSecondaryColor)
                        .cornerRadius(25)
                        .padding(.horizontal)
                        .padding(.bottom, 15)
                    }
                }
                .background(universalBackgroundColor)
            }
            .background(universalBackgroundColor)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                }
            )
            .onAppear {
                friendsViewModel.connectSearchViewModel(searchViewModel)
                
                if appCache.friends.isEmpty {
                    Task {
                        await friendsViewModel.fetchAllData()
                    }
                } else {
                                    // Use cached friends data
                friendsViewModel.friends = appCache.getCurrentUserFriends()
                friendsViewModel.filteredFriends = appCache.getCurrentUserFriends()
                }
            }
        }
    }
    
    // Invited friends section
    var invitedFriendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Invited")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.leading, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(activityCreationViewModel.selectedFriends) { friend in
                        Button(action: {
                            if let index = activityCreationViewModel.selectedFriends.firstIndex(where: { $0.id == friend.id }) {
                                activityCreationViewModel.selectedFriends.remove(at: index)
                            }
                        }) {
                            HStack(spacing: 4) {
                                if let profilePicUrl = friend.profilePicture,
                                    let url = URL(string: profilePicUrl)
                                {
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 30, height: 30)
                                    }
                                } else {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 30, height: 30)
                                }
                                
                                // Use FormatterService to display name
                                if let displayName = friend.name {
                                    Text(displayName.isEmpty ? (friend.username ?? "User") : displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                } else {
                                    Text(friend.username ?? "User")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    
                                }
                                
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(universalSecondaryColor)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    // Friends list section with real data and improved search
    var friendsListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Friends")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.leading, 10)

            VStack(spacing: 15) {
                if friendsViewModel.friends.isEmpty {
                    Text("You have no friends yet")
                        .foregroundColor(.gray)
                        .padding(.vertical)
                } else {
                    // Use filtered friends directly from the view model
                    let filteredFriends = searchViewModel.searchText.isEmpty ? 
                        friendsViewModel.friends : 
                        friendsViewModel.friends.filter { friend in
                            let searchText = searchViewModel.searchText.lowercased()
                            return (friend.username ?? "").lowercased().contains(searchText) ||
                                (friend.name?.lowercased().contains(searchText) ?? false) ||
                                (friend.email?.lowercased().contains(searchText) ?? false)
                        }
                    
                    if filteredFriends.isEmpty {
                        Text("No friends match your search")
                            .foregroundColor(.gray)
                            .padding(.vertical)
                    } else {
                        ForEach(filteredFriends) { friend in
                            FriendListRow(
                                friend: friend,
                                isSelected: activityCreationViewModel.selectedFriends
                                    .contains(friend)
                            )
                            .onTapGesture {
                                toggleFriendSelection(friend)
                            }
                        }
                    }
                }
            }
        }
    }

    private func toggleFriendSelection(_ friend: FullFriendUserDTO) {
        if activityCreationViewModel.selectedFriends.contains(friend) {
            activityCreationViewModel.selectedFriends.removeAll {
                $0.id == friend.id
            }
        } else {
            activityCreationViewModel.selectedFriends.append(friend)
        }
    }
}

// Friend Row Component - renamed to avoid conflict
struct FriendListRow: View {
    let friend: FullFriendUserDTO
    let isSelected: Bool

    var body: some View {
        HStack {
            if let profilePicUrl = friend.profilePicture,
                let url = URL(string: profilePicUrl)
            {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 50, height: 50)
                }
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading) {
                // Use FormatterService to format the name
                let fullName = FormatterService.shared.formatName(user: friend)
                Text(fullName == "No Name" ? (friend.username ?? "User") : fullName)
                    .font(.headline)
                    .foregroundColor(universalAccentColor)

                Text("@\(friend.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            Image(
                systemName: isSelected ? "checkmark.circle.fill" : "plus.circle"
            )
            .resizable()
            .frame(width: 30, height: 30)
            .foregroundColor(isSelected ? .green : universalSecondaryColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .background(isSelected ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(10)
    }
}

// Add this explicit cast extension to help with type compatibility
extension FullFriendUserDTO {
    // This allows FullFriendUserDTO to be used where BaseUserDTO is expected
    var asBaseUser: BaseUserDTO {
        return BaseUserDTO(
            id: self.id,
            username: self.username,
            profilePicture: self.profilePicture,
            name: self.name,
            bio: self.bio,
            email: self.email
        )
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    InviteView(user: .danielAgapov).environmentObject(appCache)
}
