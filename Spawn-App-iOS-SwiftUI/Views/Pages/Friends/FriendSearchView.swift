//
//  FriendSearchView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 5/17/25.
//

import SwiftUI
import Combine

// Define the different modes the view can operate in
enum FriendListDisplayMode {
    case search
    case allFriends
    case recentlySpawnedWith
}



struct FriendSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var searchViewModel = SearchViewModel()
    @StateObject private var viewModel: FriendsTabViewModel
    
    // Mode determines what content to display
    var displayMode: FriendListDisplayMode
    
    init(userId: UUID? = nil, displayMode: FriendListDisplayMode = .search) {
        let id = userId ?? (UserDefaults.standard.string(forKey: "currentUserId").flatMap { UUID(uuidString: $0) } ?? UUID())
        self._viewModel = StateObject(wrappedValue: FriendsTabViewModel(
            userId: id,
            apiService: MockAPIService.isMocking ? MockAPIService(userId: id) : APIService())
        )
        self.displayMode = displayMode
    }
    
    // Title based on display mode
    private var titleText: String {
        switch displayMode {
        case .search:
            return "Find Friends"
        case .allFriends:
            return "Your Friends"
        case .recentlySpawnedWith:
            return "Recently Spawned With"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (simplified to match TagDetailView)
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                }
                
                Spacer()
                
                Text(titleText)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Empty view to balance the back button
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.clear)
            }
            .foregroundColor(universalAccentColor)
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Search bar
            if displayMode == .search || displayMode == .allFriends {
                SearchBarView(
                    searchText: $searchViewModel.searchText,
                    isSearching: $searchViewModel.isSearching,
                    placeholder: "Search for friends"
                )
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Content based on display mode
            ScrollView {
                VStack(spacing: 16) {
                    switch displayMode {
                    case .search:
                        if searchViewModel.searchText.isEmpty {
                            recentlySpawnedWithView
                        } else {
                            searchResultsView
                        }
                    case .allFriends:
                        allFriendsView
                    case .recentlySpawnedWith:
                        recentlySpawnedWithView
                    }
                }
                .padding(.top, 16)
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    // Load appropriate data based on display mode
                    switch displayMode {
                    case .search:
                        await viewModel.fetchRecentlySpawnedWith()
                    case .allFriends:
                        await viewModel.fetchAllData()
                    case .recentlySpawnedWith:
                        await viewModel.fetchRecentlySpawnedWith()
                    }
                    
                    viewModel.connectSearchViewModel(searchViewModel)
                }
            }
        }
        .background(universalBackgroundColor)
    }
    

    
    var searchResultsView: some View {
        VStack(spacing: 16) {
            // Background for loading state
            Color.clear.frame(width: 0, height: 0)
                .background(universalBackgroundColor)
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 24)
                    .background(universalBackgroundColor)
            } else if viewModel.searchResults.isEmpty && searchViewModel.searchText.count > 0 {
                Text("No results found")
                    .font(.onestRegular(size: 16))
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 24)
            } else {
                ForEach(viewModel.searchResults) { user in
                    FriendRowView(user: user, viewModel: viewModel)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(universalBackgroundColor)
    }
    
    var allFriendsView: some View {
        VStack(spacing: 16) {
            // Background for loading state
            Color.clear.frame(width: 0, height: 0)
                .background(universalBackgroundColor)
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 24)
                    .background(universalBackgroundColor)
            } else if viewModel.filteredFriends.isEmpty {
                Text("No friends found")
                    .font(.onestRegular(size: 16))
                    .foregroundColor(universalAccentColor)
                    .padding(.top, 24)
            } else {
                ForEach(viewModel.filteredFriends) { friend in
					FriendRowView(friend: friend, viewModel: viewModel)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(universalBackgroundColor)
    }
    
    var recentlySpawnedWithView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Background for loading state
            Color.clear.frame(width: 0, height: 0)
                .background(universalBackgroundColor)
            if viewModel.isLoading {
                ProgressView()
                    .padding(.top, 24)
                    .background(universalBackgroundColor)
            } else if viewModel.recentlySpawnedWith.isEmpty {
                Text("No recent spawns found")
                    .font(.onestRegular(size: 14))
                    .foregroundColor(universalAccentColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
            } else {
                ForEach(viewModel.recentlySpawnedWith, id: \.user.id) { recentUser in
                    FriendRowView(user: recentUser.user, viewModel: viewModel)
                        .padding(.horizontal, 16)
                }
            }
        }
        .background(universalBackgroundColor)
    }
}

// Unified FriendRowView that can work with either BaseUserDTO or FullFriendUserDTO
struct FriendRowView: View {
    var user: Nameable? = nil
    var friend: FullFriendUserDTO? = nil
    var viewModel: FriendsTabViewModel
    @State private var isAdded: Bool = false
    
    var body: some View {
        HStack {
            // Profile picture - works with either user or friend
            let profilePicture = user?.profilePicture ?? friend?.profilePicture
            
            // Extract the appropriate user object for navigation
			let userForProfile: Nameable = user ?? friend ?? user!
            
            // Create NavigationLink around the profile picture
            NavigationLink(destination: ProfileView(user: userForProfile)) {
                if let pfpUrl = profilePicture {
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
            }
            
            // Navigation link for name and username
            NavigationLink(destination: ProfileView(user: userForProfile)) {
                VStack(alignment: .leading, spacing: 2) {
                    // Works with either user or friend
                    if let user = user {
                        Text(FormatterService.shared.formatName(user: user))
                            .font(.onestRegular(size: 14))
                            .foregroundColor(universalAccentColor)
                        Text("@\(user.username)")
                            .font(.onestRegular(size: 14))
                            .foregroundColor(Color.gray)
                    } else if let friend = friend {
                        Text(FormatterService.shared.formatName(user: friend))
                            .font(.onestRegular(size: 14))
                            .foregroundColor(universalAccentColor)
                        Text("@\(friend.username)")
                            .font(.onestRegular(size: 14))
                            .foregroundColor(Color.gray)
                    }
                }
                .padding(.leading, 8)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Different controls depending on the context
            if let friend = friend, !isAdded {
                // Show add button for non-friends
                Button(action: {
                    isAdded = true
                    Task {
                        await viewModel.addFriend(friendUserId: friend.id)
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
        }
        .padding(.vertical, 8)
    }
}

class FriendSearchViewModel: ObservableObject {
    @Published var recentlySpawnedWith: [RecentlySpawnedUserDTO] = []
    @Published var searchResults: [BaseUserDTO] = []
    @Published var errorMessage: String = ""
    @Published var isLoading: Bool = false
    
    private var apiService: IAPIService
    private let userId: UUID
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: UUID, apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.userId = userId
        self.apiService = apiService
    }
    
    @MainActor
    func fetchRecentlySpawnedWith() async {
        isLoading = true
        defer { isLoading = false }
        
        // In a real app, fetch recently spawned with users from API
        if MockAPIService.isMocking {
            // Create mock RecentlySpawnedUserDTO objects using BaseUserDTO.mockUsers
            self.recentlySpawnedWith = BaseUserDTO.mockUsers.map { user in
                RecentlySpawnedUserDTO(user: user, dateTime: Date())
            }
            return
        }
        
        do {
            // API endpoint for getting recently spawned with users
            guard let url = URL(string: APIService.baseURL + "users/\(userId)/recent-users") else {
                errorMessage = "Invalid URL"
                return
            }
            
            let fetchedUsers: [RecentlySpawnedUserDTO] = try await apiService.fetchData(from: url, parameters: nil)
            await MainActor.run {
                self.recentlySpawnedWith = fetchedUsers
            }
        } catch {
            errorMessage = "Failed to fetch recently spawned with users: \(error.localizedDescription)"
            self.recentlySpawnedWith = []
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
    FriendSearchView(userId: UUID(), displayMode: .allFriends)
}
