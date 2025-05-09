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
    @ObservedObject var eventCreationViewModel = EventCreationViewModel.shared
    @StateObject private var searchViewModel = SearchViewModel()
    
    // Add view models for friends and tags
    @StateObject private var friendsViewModel: FriendsTabViewModel
    @StateObject private var tagsViewModel: TagsViewModel
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

        self._tagsViewModel = StateObject(
            wrappedValue: TagsViewModel(
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService(),
                userId: user.id
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                Text("Invite tags and friends!")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 30)

                // Tags section
                ScrollView {
                    VStack(spacing: 20) {
                        // Floating tags - these should be dynamically rendered from real tags
                        tagsCloudView

                        // Invited section
                        if !eventCreationViewModel.selectedFriends.isEmpty {
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
                            "Done Inviting (\(eventCreationViewModel.selectedFriends.count) friends, \(eventCreationViewModel.selectedTags.count) tags)"
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
                .background(Color(.systemBackground))
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
                // Use cached tags and friends if available
                if !appCache.userTags.isEmpty {
                    // Convert FriendTagDTO to FullFriendTagDTO if needed
                    Task {
                        await tagsViewModel.fetchTags()
                    }
                } else {
                    Task {
                        await tagsViewModel.fetchTags()
                    }
                }
                
                friendsViewModel.connectSearchViewModel(searchViewModel)
                
                if appCache.friends.isEmpty {
                    Task {
                        await friendsViewModel.fetchAllData()
                    }
                } else {
                    // Use cached friends data
                    friendsViewModel.friends = appCache.friends
                    friendsViewModel.filteredFriends = appCache.friends
                }
            }
        }
    }

    // Tag cloud with improved floating arrangement to match Figma
    var tagsCloudView: some View {
        VStack {
            if tagsViewModel.tags.isEmpty {
                Text("You have no tags yet")
                    .foregroundColor(.gray)
                    .padding(.vertical)
            } else {
                // Group the tags into rows with staggering
                VStack(alignment: .leading, spacing: 20) {
                    // First row
                    HStack(spacing: 0) {
                        Spacer().frame(width: 10)
                        ForEach(tagsViewModel.tags.prefix(2), id: \.id) { tag in
                            TagBubble(
                                tag: tag,
                                isSelected: eventCreationViewModel.selectedTags
                                    .contains(tag)
                            )
                            .padding(.horizontal, 5)
                            .onTapGesture {
                                toggleTagSelection(tag)
                            }
                        }
                        Spacer()
                    }

                    // Second row with different staggering
                    if tagsViewModel.tags.count > 2 {
                        HStack(spacing: 0) {
                            Spacer().frame(width: 40)
                            ForEach(
                                Array(
                                    tagsViewModel.tags.dropFirst(2).prefix(2)
                                ),
                                id: \.id
                            ) { tag in
                                TagBubble(
                                    tag: tag,
                                    isSelected: eventCreationViewModel
                                        .selectedTags.contains(tag)
                                )
                                .padding(.horizontal, 5)
                                .onTapGesture {
                                    toggleTagSelection(tag)
                                }
                            }
                            Spacer()
                        }
                    }

                    // Third row with different staggering
                    if tagsViewModel.tags.count > 4 {
                        HStack(spacing: 0) {
                            Spacer().frame(width: 20)
                            ForEach(
                                Array(
                                    tagsViewModel.tags.dropFirst(4).prefix(2)
                                ),
                                id: \.id
                            ) { tag in
                                TagBubble(
                                    tag: tag,
                                    isSelected: eventCreationViewModel
                                        .selectedTags.contains(tag)
                                )
                                .padding(.horizontal, 5)
                                .onTapGesture {
                                    toggleTagSelection(tag)
                                }
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
    }

    private func toggleTagSelection(_ tag: FullFriendTagDTO) {
        if let index = eventCreationViewModel.selectedTags.firstIndex(where: { $0.id == tag.id }) {
            // Tag exists in selectedTags, remove it
            eventCreationViewModel.selectedTags.remove(at: index)
        } else {
            // Tag does not exist in selectedTags, add it
            eventCreationViewModel.selectedTags.append(tag)
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
                HStack(spacing: 15) {
                    ForEach(eventCreationViewModel.selectedFriends) { friend in
                        VStack {
                            if let profilePicUrl = friend.profilePicture,
                                let url = URL(string: profilePicUrl)
                            {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 60, height: 60)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 60, height: 60)
                            }

                            Text(friend.username)
                                .font(.caption)
                                .foregroundColor(universalAccentColor)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }

    // Friends list section with real data
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
                    ForEach(friendsViewModel.filteredFriends) { friend in
                        FriendListRow(
                            friend: friend,
                            isSelected: eventCreationViewModel.selectedFriends
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

    private func toggleFriendSelection(_ friend: FullFriendUserDTO) {
        if eventCreationViewModel.selectedFriends.contains(friend) {
            eventCreationViewModel.selectedFriends.removeAll {
                $0.id == friend.id
            }
        } else {
            eventCreationViewModel.selectedFriends.append(friend)
        }
    }
}

// TagBubble Component
struct TagBubble: View {
    let tag: FullFriendTagDTO
    let isSelected: Bool

    var body: some View {
        Text("+ \(tag.displayName)")
            .foregroundColor(isSelected ? .white : Color(hex: tag.colorHexCode))
            .padding(.vertical, 8)
            .padding(.horizontal, 15)
            .background(
                Group {
                    if isSelected {
                        Capsule().fill(Color(hex: tag.colorHexCode))
                    } else {
                        Capsule().stroke(
                            Color(hex: tag.colorHexCode),
                            style: StrokeStyle(lineWidth: 1, dash: [5])
                        )
                    }
                }
            )
            .overlay(
                Group {
                    if isSelected {
                        HStack {
                            Spacer()
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.trailing, 5)
                        }
                    }
                }
            )
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
                Text(friend.username)
                    .font(.headline)
                    .foregroundColor(universalAccentColor)

                Text("@\(friend.email.split(separator: "@").first ?? "")")
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
            firstName: self.firstName,
            lastName: self.lastName,
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
