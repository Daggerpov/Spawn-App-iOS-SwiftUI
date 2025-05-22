//
//  AddFriendToTagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-13.
//

import SwiftUI

struct AddFriendToTagsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddFriendToTagsViewModel(
        userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID(),
        apiService: MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService()
    )
    
    let friendId: UUID
    @State private var searchText: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add to Tag")
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
                
                TextField("Search tags", text: $searchText)
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
            
            // Tags list
            if viewModel.isLoading {
                ProgressView()
                    .padding()
                Spacer()
            } else if viewModel.tags.isEmpty {
                VStack {
                    Text("You don't have any tags yet")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button(action: {
                        viewModel.showCreateTagSheet = true
                    }) {
                        Text("Create a Tag")
                            .foregroundColor(.white)
                            .padding()
                            .background(universalAccentColor)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredTags) { tag in
                        Button(action: {
                            Task {
                                let success = await viewModel.addFriendToTag(friendId: friendId, tagId: tag.id)
                                if success {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                TagBubble(tag: tag.asFullFriendTag, isSelected: false)
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(universalAccentColor)
                                    .font(.title3)
                            }
                            .contentShape(Rectangle())
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(PlainListStyle())
            }
            
            // Cancel button
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
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.fetchAllData()
            }
        }
        .sheet(isPresented: $viewModel.showCreateTagSheet) {
            CreatingTagRowView(creationStatus: .constant(.creating))
                .environmentObject(TagsViewModel(
                    apiService: MockAPIService.isMocking ? MockAPIService(userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()) : APIService(),
                    userId: UserAuthViewModel.shared.spawnUser?.id ?? UUID()
                ))
                .padding()
        }
    }
    
    private var filteredTags: [FriendTagDTO] {
        if searchText.isEmpty {
            return viewModel.tags
        } else {
            return viewModel.tags.filter { tag in
                tag.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// Extension to convert FriendTagDTO to FullFriendTagDTO
extension FriendTagDTO {
    var asFullFriendTag: FullFriendTagDTO {
        return FullFriendTagDTO(
            id: self.id,
            displayName: self.displayName,
            colorHexCode: self.colorHexCode,
            friends: nil,
            isEveryone: self.isEveryone
        )
    }
}

struct AddFriendToTagsView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagsView(friendId: UUID())
    }
} 
