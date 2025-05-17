//
//  FriendSearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/17/25.
//

import SwiftUI
import Combine

struct FriendSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var viewModel: FriendSearchViewModel
    
    init(userId: UUID? = nil) {
        let id = userId ?? (UserDefaults.standard.string(forKey: "currentUserId").flatMap { UUID(uuidString: $0) } ?? UUID())
        self._viewModel = StateObject(wrappedValue: FriendSearchViewModel(userId: id))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.black)
                            .font(.system(size: 20))
                    }
                    
                    Spacer()
                    
                    Text("Find Friends")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Empty view to balance the back button
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Search bar
                SearchView(searchPlaceholderText: "Search for friends...", viewModel: searchViewModel)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
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
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await viewModel.fetchRecentlySpawnedWith()
                    viewModel.connectSearchViewModel(searchViewModel)
                }
            }
        }
    }
    
    var searchResultsView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.searchResults) { user in
                FriendRowView(user: user, viewModel: viewModel)
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
                    FriendRowView(user: user, viewModel: viewModel)
                }
            }
        }
    }
}

struct FriendRowView: View {
    let user: BaseUserDTO
    let viewModel: FriendSearchViewModel
    @State private var isAdded: Bool = false
    
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
                isAdded = true
                Task {
                    await viewModel.addFriend(friendUserId: user.id)
                }
            }) {
                Text(isAdded ? "Request Sent" : "Add +")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(isAdded ? Color.gray : universalSecondaryColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isAdded ? Color.gray : universalSecondaryColor, lineWidth: 1)
                    )
            }
            .disabled(isAdded)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

class FriendSearchViewModel: ObservableObject {
    @Published var recentlySpawnedWith: [BaseUserDTO] = []
    @Published var searchResults: [BaseUserDTO] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var apiService: IAPIService
    private let userId: UUID
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: UUID, apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.userId = userId
        self.apiService = apiService
        
        if MockAPIService.isMocking {
            self.recentlySpawnedWith = BaseUserDTO.mockUsers
        }
    }
    
    @MainActor
    func fetchRecentlySpawnedWith() async {
        isLoading = true
        defer { isLoading = false }
        
        // In a real app, fetch recently spawned with users from API
        if MockAPIService.isMocking {
            self.recentlySpawnedWith = BaseUserDTO.mockUsers
            return
        }
        
        do {
            // API endpoint for getting recently spawned with users
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/recently-spawned-with") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedUsers: [BaseUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            self.recentlySpawnedWith = fetchedUsers
        } catch {
            errorMessage = "Failed to fetch recently spawned with users: \(error.localizedDescription)"
            // Use mock data for development
            self.recentlySpawnedWith = BaseUserDTO.mockUsers
        }
    }
    
    func connectSearchViewModel(_ searchViewModel: SearchViewModel) {
        searchViewModel.$debouncedSearchText
            .sink { [weak self] searchText in
                Task {
                    await self?.performSearch(searchText: searchText)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func performSearch(searchText: String) async {
        if searchText.isEmpty {
            searchResults = []
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        if MockAPIService.isMocking {
            // Filter mock data for testing
            let lowercasedSearchText = searchText.lowercased()
            searchResults = BaseUserDTO.mockUsers.filter { user in
                let name = FormatterService.shared.formatName(user: user).lowercased()
                let username = user.username.lowercased()
                
                return name.contains(lowercasedSearchText) || username.contains(lowercasedSearchText)
            }
            return
        }
        
        do {
            // API endpoint for searching users: /api/v1/users/search?query={searchText}
            guard let url = URL(string: APIService.baseURL + "users/search") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedUsers: [BaseUserDTO] = try await apiService.fetchData(
                from: url, 
                parameters: ["query": searchText]
            )
            self.searchResults = fetchedUsers
        } catch {
            errorMessage = "Failed to search users: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func addFriend(friendUserId: UUID) async {
        do {
            let createdFriendRequest = CreateFriendRequestDTO(
                id: UUID(),
                senderUserId: userId,
                receiverUserId: friendUserId
            )
            
            // API endpoint for creating friend request: /api/v1/friend-requests
            guard let url = URL(string: APIService.baseURL + "friend-requests") else {
                errorMessage = "Invalid URL"
                return
            }
            
            _ = try await self.apiService.sendData(
                createdFriendRequest, to: url, parameters: nil)
        } catch {
            errorMessage = "Failed to send friend request: \(error.localizedDescription)"
        }
    }
}

#Preview {
    FriendSearchView(userId: UUID())
}
