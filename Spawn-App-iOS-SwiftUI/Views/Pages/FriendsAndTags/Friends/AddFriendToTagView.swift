//
//  AddFriendToTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-07-13.
//

import SwiftUI

struct AddFriendToTagView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TagsViewModel(
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
                                await addFriendToTag(tagId: tag.id)
                            }
                        }) {
                            HStack {
                                TagBubble(tag: tag)
                                
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
            CreateTagView()
        }
    }
    
    private var filteredTags: [FriendTagDTO] {
        if searchText.isEmpty {
            return viewModel.tags
        } else {
            return viewModel.tags.filter { tag in
                tag.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func addFriendToTag(tagId: UUID) async {
        if let url = URL(string: APIService.baseURL + "friendTags/addFriendToTag") {
            do {
                let params = ["friendTagId": tagId.uuidString, "friendId": friendId.uuidString]
                let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: UUID()) : APIService()
                _ = try await apiService.sendDataNoBody(to: url, parameters: params)
                
                // Show success feedback
                await MainActor.run {
                    // Post notification that a friend was added to a tag
                    NotificationCenter.default.post(name: .friendAddedToTag, object: nil)
                    dismiss()
                }
            } catch {
                print("Error adding friend to tag: \(error.localizedDescription)")
            }
        }
    }
}

struct AddFriendToTagView_Previews: PreviewProvider {
    static var previews: some View {
        AddFriendToTagView(friendId: UUID())
    }
} 
