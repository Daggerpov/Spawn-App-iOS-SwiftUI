//
//  AddFriendToTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-12.
//

import SwiftUI

struct AddFriendToTagView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCache: AppCache
    @StateObject private var viewModel: AddFriendToTagViewModel
    @State private var searchText: String = ""
    
    init(friendTagId: UUID) {
        self._viewModel = StateObject(wrappedValue: AddFriendToTagViewModel(
            userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
            apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService()
        ))
        self.friendTagId = friendTagId
    }
    
    var friendTagId: UUID
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Friends to Tag")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search friends", text: $searchText)
                    .autocapitalization(.none)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Friends list
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            } else if viewModel.friends.isEmpty {
                VStack {
                    Text("No friends available to add")
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredFriends) { friend in
                        SelectableFriendRow(
                            friend: friend,
                            isSelected: viewModel.selectedFriends.contains(where: { $0.id == friend.id }),
                            action: {
                                viewModel.toggleFriendSelection(friend)
                            }
                        )
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // Action buttons
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Text("Cancel")
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                Button(action: {
                    Task {
                        await viewModel.addSelectedFriendsToTag(friendTagId: friendTagId)
                        dismiss()
                    }
                }) {
                    Text("Add \(viewModel.selectedFriends.count) Friends")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.selectedFriends.isEmpty ? Color.gray : universalAccentColor)
                        .cornerRadius(10)
                }
                .disabled(viewModel.selectedFriends.isEmpty)
            }
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.fetchAllData(friendTagId: friendTagId)
            }
        }
    }
    
    var filteredFriends: [BaseUserDTO] {
        if searchText.isEmpty {
            return viewModel.friends
        } else {
            return viewModel.friends.filter { friend in
                let name = friend.name ?? ""
                let username = friend.username
                return name.localizedCaseInsensitiveContains(searchText) || 
                       username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// Friend row component
struct SelectableFriendRow: View {
    let friend: BaseUserDTO
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Profile image
                if let pfpUrl = friend.profilePicture {
                    if MockAPIService.isMocking {
                        Image(pfpUrl)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
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
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                } else {
                    Circle()
                        .stroke(Color.gray, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddFriendToTagView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagView(friendTagId: UUID())
    }
} 
