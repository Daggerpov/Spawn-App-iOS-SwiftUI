//
//  FriendSearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/17/25.
//

import SwiftUI
import Combine

struct FriendSearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var viewModel = FriendSearchViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.system(size: 20))
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Search bar
            SearchView(searchPlaceholderText: "Search for friends...", viewModel: searchViewModel)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 16)
            
            // Search results or recently spawned with
            ScrollView {
                if searchViewModel.isSearching {
                    searchResultsView
                } else {
                    recentlySpawnedWithView
                }
            }
            
            Spacer()
        }
        .background(universalBackgroundColor)
        .onAppear {
            Task {
                await viewModel.fetchRecentlySpawnedWith()
                viewModel.connectSearchViewModel(searchViewModel)
            }
        }
    }
    
    var searchResultsView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.searchResults) { user in
                FriendRowView(user: user)
            }
            
            if viewModel.searchResults.isEmpty && searchViewModel.searchText.count > 0 {
                Text("No results found")
                    .font(.onestRegular(size: 16))
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 24)
            }
        }
        .padding(.horizontal, 16)
    }
    
    var recentlySpawnedWithView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recently Spawned With")
                    .font(.onestMedium(size: 16))
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                Button(action: {
                    // Handle show all
                }) {
                    Text("Show All")
                        .font(.onestRegular(size: 14))
                        .foregroundColor(universalSecondaryColor)
                }
            }
            .padding(.horizontal, 16)
            
            if viewModel.recentlySpawnedWith.isEmpty {
                Text("No recent spawns found")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalAccentColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            } else {
                ForEach(viewModel.recentlySpawnedWith) { user in
                    FriendRowView(user: user)
                }
            }
        }
    }
}

struct FriendRowView: View {
    let user: BaseUserDTO
    
    var body: some View {
        HStack {
            // Profile picture
            if let pfpUrl = user.profilePicture {
                if MockAPIService.isMocking {
                    Image(pfpUrl)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
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
                }
            } else {
                Circle()
                    .fill(.gray)
                    .frame(width: 50, height: 50)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(FormatterService.shared.formatName(user: user))
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalAccentColor)
                Text("@\(user.username)")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(Color.gray)
            }
            .padding(.leading, 8)
            
            Spacer()
            
            Button(action: {
                // Add friend button action
            }) {
                Text("Add +")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalSecondaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(universalSecondaryColor, lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

class FriendSearchViewModel: ObservableObject {
    @Published var recentlySpawnedWith: [BaseUserDTO] = []
    @Published var searchResults: [BaseUserDTO] = []
    private var allUsers: [BaseUserDTO] = []
    
    func fetchRecentlySpawnedWith() async {
        // In a real app, this would fetch from API
        // For now, use mock data
        DispatchQueue.main.async {
            self.recentlySpawnedWith = BaseUserDTO.mockUsers
            self.allUsers = BaseUserDTO.mockUsers
        }
    }
    
    func connectSearchViewModel(_ searchViewModel: SearchViewModel) {
        searchViewModel.$debouncedSearchText
            .sink { [weak self] searchText in
                self?.performSearch(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func performSearch(searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        let lowercasedSearchText = searchText.lowercased()
        searchResults = allUsers.filter { user in
            let name = FormatterService.shared.formatName(user: user).lowercased()
            let username = user.username.lowercased()
            
            return name.contains(lowercasedSearchText) || username.contains(lowercasedSearchText)
        }
    }
}

#Preview {
    FriendSearchView()
}
