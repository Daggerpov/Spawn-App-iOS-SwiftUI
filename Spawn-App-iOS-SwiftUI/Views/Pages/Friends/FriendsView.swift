//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-24.
//

import SwiftUI

struct FriendsView: View {
    let user: BaseUserDTO
    @ObservedObject var viewModel: FriendsTabViewModel
    
    // Deep link parameters
    @Binding var deepLinkedProfileId: UUID?
    @Binding var shouldShowDeepLinkedProfile: Bool
    @State private var isFetchingDeepLinkedProfile = false
    
    init(user: BaseUserDTO, viewModel: FriendsTabViewModel? = nil, deepLinkedProfileId: Binding<UUID?> = .constant(nil), shouldShowDeepLinkedProfile: Binding<Bool> = .constant(false)) {
        self.user = user
        self._deepLinkedProfileId = deepLinkedProfileId
        self._shouldShowDeepLinkedProfile = shouldShowDeepLinkedProfile
        
        if let existingViewModel = viewModel {
            self.viewModel = existingViewModel
        } else {
            // Fallback for when no view model is provided (like in previews)
            self.viewModel = FriendsTabViewModel(
                userId: user.id,
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService())
        }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        FriendRequestNavButtonView
                        Spacer()
                    }
                    .padding(.horizontal)

                    FriendsTabView(user: user, viewModel: viewModel)
                }
                .padding()
                .background(universalBackgroundColor)
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchIncomingFriendRequests()
            }
            
            // Handle deep link if one is pending when view appears
            if shouldShowDeepLinkedProfile, let profileId = deepLinkedProfileId {
                handleDeepLinkedProfile(profileId)
            }
        }
        .onChange(of: shouldShowDeepLinkedProfile) { shouldShow in
            if shouldShow, let profileId = deepLinkedProfileId {
                handleDeepLinkedProfile(profileId)
            }
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleDeepLinkedProfile(_ profileId: UUID) {
        print("🎯 FriendsView: Handling deep linked profile: \(profileId)")
        
        guard !isFetchingDeepLinkedProfile else {
            print("⚠️ FriendsView: Already fetching deep linked profile, ignoring")
            return
        }
        
        isFetchingDeepLinkedProfile = true
        
        Task {
            do {
                // Fetch the profile from the API
                print("🔄 FriendsView: Fetching profile from API")
                let apiService: IAPIService = MockAPIService.isMocking ? MockAPIService(userId: user.id) : APIService()
                
                guard let url = URL(string: "\(APIService.baseURL)users/\(profileId)") else {
                    throw APIError.URLError
                }
                
                let parameters = [
                    "requestingUserId": user.id.uuidString
                ]
                let fetchedUser: BaseUserDTO = try await apiService.fetchData(from: url, parameters: parameters)
                
                print("✅ FriendsView: Successfully fetched deep linked profile: \(fetchedUser.name ?? fetchedUser.username)")
                
                // Navigate to the profile
                await MainActor.run {
                    let profileView = ProfileView(user: fetchedUser)
                    
                    // Get the current window and present the profile
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        
                        let hostingController = UIHostingController(rootView: profileView)
                        rootViewController.present(hostingController, animated: true)
                    }
                    
                    // Clean up deep link state
                    shouldShowDeepLinkedProfile = false
                    deepLinkedProfileId = nil
                    isFetchingDeepLinkedProfile = false
                    
                    print("🎯 FriendsView: Successfully navigated to profile")
                }
                
            } catch {
                print("❌ FriendsView: Failed to fetch deep linked profile: \(error)")
                print("❌ FriendsView: Error details - Profile ID: \(profileId), Error: \(error.localizedDescription)")
                
                await MainActor.run {
                    shouldShowDeepLinkedProfile = false
                    deepLinkedProfileId = nil
                    isFetchingDeepLinkedProfile = false
                }
                
                // Show error to user via InAppNotificationManager
                await MainActor.run {
                    InAppNotificationManager.shared.showNotification(
                        title: "Unable to open profile",
                        message: "The profile you're trying to view might not exist or you might not have permission to view it.",
                        type: .error
                    )
                }
            }
        }
    }
}

struct BaseFriendNavButtonView: View {
    var iconImageName: String
    var topText: String
    var bottomText: String

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(topText)
                        .onestSubheadline()
                        .multilineTextAlignment(.leading)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.bottom, 6)
                    Spacer()
                }
                HStack {
                    Text(bottomText)
                        .onestSmallText()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: true, vertical: false)
                        .lineLimit(1)
                    Spacer()
                }
            }
            .font(.caption)
            .foregroundColor(.white)
            .padding(.leading, 8)
            .padding(.vertical, 8)
            Image(iconImageName)
                .resizable()
                .frame(width: 50, height: 50)
        }
        .background(universalSecondaryColor)
        .cornerRadius(12)
    }
}

extension FriendsView {
    var FriendRequestNavButtonView: some View {
        NavigationLink(destination: {
            FriendRequestsView(userId: user.id)
        }) {
            HStack {
                HStack(spacing: 8) {
                    Text("Friend Requests")
                        .font(Font.custom("Onest", size: 17).weight(.semibold))
                        .foregroundColor(.white)
                    
                    // Only show red indicator if there are friend requests
                    if viewModel.incomingFriendRequests.count > 0 {
                        VStack(spacing: 10) {
                            Text("\(viewModel.incomingFriendRequests.count)")
                                .font(Font.custom("Onest", size: 12).weight(.semibold))
                                .lineSpacing(14.40)
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 7, leading: 11, bottom: 7, trailing: 11))
                        .frame(width: 20, height: 20)
                        .background(Color(red: 1, green: 0.45, blue: 0.44))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
                
                Text("View All >")
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.80))
            }
            .padding(16)
            .background(Color(red: 0.33, green: 0.42, blue: 0.93))
            .cornerRadius(12)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    FriendsView(user: .danielAgapov).environmentObject(appCache)
}
