//
//  ManageTaggedPeopleView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-11.
//

import SwiftUI

struct ManageTaggedPeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var suggestionsViewModel: TaggedPeopleSuggestionsViewModel
    @ObservedObject var tagsViewModel: TagsViewModel
    @State private var searchText = ""
    @State private var showAllAdded = false
    
    var tagId: UUID
    
    // Computed property to get the current tag data from ViewModel
    private var tag: FullFriendTagDTO {
        tagsViewModel.tags.first(where: { $0.id == tagId }) ?? FullFriendTagDTO.empty
    }
    
    init(tagsViewModel: TagsViewModel, tagId: UUID) {
        self.tagsViewModel = tagsViewModel
        self.tagId = tagId
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
        self._suggestionsViewModel = StateObject(wrappedValue: TaggedPeopleSuggestionsViewModel(
            userId: userId,
            tagId: tagId,
            apiService: apiService
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with tag name
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Tags / \(tag.displayName) / People")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Spacer to balance the back button
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.clear)
            }
            .foregroundColor(universalAccentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                
                TextField("Search friends", text: $searchText)
                    .padding(8)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            ScrollView {
                // Suggested section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Suggested")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if !suggestionsViewModel.suggestedFriends.isEmpty {
                            Button(action: {
                                // Toggle the expansion
                            }) {
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    if suggestionsViewModel.isLoading && suggestionsViewModel.suggestedFriends.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if suggestionsViewModel.suggestedFriends.isEmpty {
                        Text("No suggestions available")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Filter suggested friends based on search text
                        let filteredSuggestions = searchText.isEmpty ? suggestionsViewModel.suggestedFriends :
                            suggestionsViewModel.suggestedFriends.filter { friend in
                                let name = friend.name?.lowercased() ?? ""
                                let username = friend.username.lowercased()
                                return name.contains(searchText.lowercased()) || 
                                       username.contains(searchText.lowercased())
                            }
                        
                        if filteredSuggestions.isEmpty {
                            Text("No suggestions match your search")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            // Limit to 3 suggestions
                            ForEach(filteredSuggestions.prefix(3)) { friend in
                                HStack {
                                    // Profile image
                                    if let pfpUrl = friend.profilePicture {
                                        AsyncImage(url: URL(string: pfpUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
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
                                    
                                    // Name and username
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.name ?? "")
                                            .font(.headline)
                                        
                                        Text("@\(friend.username)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Add button
                                    Button(action: {
                                        Task {
                                            await suggestionsViewModel.addFriendToTag(friend)
                                            // Also update the main tags view model
                                            await tagsViewModel.fetchAllData()
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(universalAccentColor)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Added friends section - Get from the current tag object
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Added (\(tag.friends?.count ?? 0))")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if tagsViewModel.isLoading && (tag.friends?.isEmpty ?? true) {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if tag.friends?.isEmpty ?? true {
                        Text("No friends added to this tag yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Filter added friends based on search text
                        let filteredAdded = searchText.isEmpty ? (tag.friends ?? []) :
                            (tag.friends ?? []).filter { friend in
                                let name = friend.name?.lowercased() ?? ""
                                let username = friend.username.lowercased()
                                return name.contains(searchText.lowercased()) || 
                                      username.contains(searchText.lowercased())
                            }
                        
                        if filteredAdded.isEmpty {
                            Text("No added friends match your search")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            // Limit to 6 added friends or show all if showAllAdded is true
							let displayedFriends = showAllAdded ? filteredAdded : Array(filteredAdded.prefix(6))

                            ForEach(displayedFriends) { friend in
                                HStack {
                                    // Profile image
                                    if let pfpUrl = friend.profilePicture {
                                        AsyncImage(url: URL(string: pfpUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
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
                                    
                                    // Name and username
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.name ?? "")
                                            .font(.headline)
                                        
                                        Text("@\(friend.username)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    // Remove button
                                    Button(action: {
                                        Task {
                                            await tagsViewModel.removeFriendFromFriendTag(friendUserId: friend.id, friendTagId: tagId)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            }
                            
                            // Show more/less button if there are more than 6 friends
                            if (tag.friends?.count ?? 0) > 6 {
                                Button(action: {
                                    showAllAdded.toggle()
                                }) {
                                    Text(showAllAdded ? "Show Less" : "Show More")
                                        .font(.subheadline)
                                        .foregroundColor(universalAccentColor)
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Load suggestions and fetch latest tag data
            Task {
				await suggestionsViewModel.fetchSuggestedFriends()
                await tagsViewModel.fetchAllData()
            }
            
            // Add observer for friendsAddedToTag notification
            NotificationCenter.default.addObserver(
                forName: .friendsAddedToTag,
                object: nil,
                queue: .main
            ) { notification in
                Task {
                    await tagsViewModel.fetchAllData()
                }
            }
        }
        .onDisappear {
            // Remove observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .friendsAddedToTag, object: nil)
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
    }
}

@available(iOS 17, *)
#Preview {
    let viewModel = TagsViewModel(apiService: MockAPIService(userId: UUID()), userId: UUID())
    return ManageTaggedPeopleView(tagsViewModel: viewModel, tagId: FullFriendTagDTO.close.id)
} 
