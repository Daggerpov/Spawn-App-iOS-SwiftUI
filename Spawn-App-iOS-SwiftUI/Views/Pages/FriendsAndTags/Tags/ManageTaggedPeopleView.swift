//
//  ManageTaggedPeopleView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-11.
//

import SwiftUI

struct ManageTaggedPeopleView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCache: AppCache
    @StateObject var viewModel: TaggedPeopleSuggestionsViewModel
    @State private var searchText = ""
    
    var tag: FullFriendTagDTO
    
    init(tag: FullFriendTagDTO) {
        self.tag = tag
        let userId = UserAuthViewModel.shared.spawnUser?.id ?? UUID()
        let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: userId) : APIService()
        self._viewModel = StateObject(wrappedValue: TaggedPeopleSuggestionsViewModel(
            userId: userId,
            tagId: tag.id,
            apiService: apiService
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.black)
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
            .padding(.bottom, 8)
            
            ScrollView {
                // Suggested section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Suggested")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        if !viewModel.suggestedFriends.isEmpty {
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
                    
                    if viewModel.isLoading && viewModel.suggestedFriends.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.suggestedFriends.isEmpty {
                        Text("No suggestions available")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Filter suggested friends based on search text
                        let filteredSuggestions = searchText.isEmpty ? viewModel.suggestedFriends :
                            viewModel.suggestedFriends.filter { friend in
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
                            ForEach(filteredSuggestions) { friend in
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
                                            await viewModel.addFriendToTag(friend)
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
                
                // Added friends section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Added (\(viewModel.addedFriends.count))")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.addedFriends.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else if viewModel.addedFriends.isEmpty {
                        Text("No friends added to this tag yet")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        // Filter added friends based on search text
                        let filteredAdded = searchText.isEmpty ? viewModel.addedFriends :
                            viewModel.addedFriends.filter { friend in
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
                            ForEach(filteredAdded) { friend in
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
                                    
                                    // Checkmark icon to show added
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.removeFriendFromTag(friend)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                            
                            if filteredAdded.count > 6 {
                                Button(action: {
                                    // Show more friends
                                }) {
                                    Text("Show more")
                                        .foregroundColor(universalAccentColor)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding()
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(universalBackgroundColor)
        .task {
            await viewModel.fetchAllData()
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    ManageTaggedPeopleView(tag: FullFriendTagDTO.close)
        .environmentObject(appCache)
} 
