//
//  FriendRequestsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-17.
//

import SwiftUI

struct FriendRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: FriendRequestsViewModel
    @State private var showSuccessDrawer = false
    @State private var acceptedFriend: BaseUserDTO?
    @State private var navigateToAddToActivityType = false
    
    init(userId: UUID) {
        self._viewModel = StateObject(wrappedValue: FriendRequestsViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(universalAccentColor)
                }
                
                Spacer()
                
                Text("Friend Requests")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Empty view to balance the back button
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            // Friend request list
            ScrollView {
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding()
					                    } else if viewModel.incomingFriendRequests.isEmpty && viewModel.sentFriendRequests.isEmpty {
                        Text("No friend requests")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        // Incoming friend requests section
                        if !viewModel.incomingFriendRequests.isEmpty {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Received")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(universalAccentColor)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                ForEach(viewModel.incomingFriendRequests) { request in
                                    FriendRequestItemView(
                                        friendRequest: request,
                                        isIncoming: true,
                                        onAccept: {
                                            Task {
                                                await viewModel.respondToFriendRequest(requestId: request.id, action: .accept)
                                                // Show success drawer after successful acceptance
                                                acceptedFriend = request.senderUser
                                                showSuccessDrawer = true
                                            }
                                        },
                                        onRemove: {
                                            Task {
                                                await viewModel.respondToFriendRequest(requestId: request.id, action: .decline)
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                        
                        // Divider between sections
                        if !viewModel.incomingFriendRequests.isEmpty && !viewModel.sentFriendRequests.isEmpty {
                            Divider()
                                .background(universalPlaceHolderTextColor)
                                .padding(.horizontal)
                                .padding(.vertical, 16)
                        }
                        
                        // Sent friend requests section
                        if !viewModel.sentFriendRequests.isEmpty {
                            VStack(spacing: 0) {
                                HStack {
                                    Text("Sent")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(universalAccentColor)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 12)
                                
                                ForEach(viewModel.sentFriendRequests) { request in
                                    FriendRequestItemView(
                                        friendRequest: request,
                                        isIncoming: false,
                                        onAccept: {
                                            // No action for sent requests
                                        },
                                        onRemove: {
                                            Task {
                                                await viewModel.respondToFriendRequest(requestId: request.id, action: .cancel)
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                }
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchFriendRequests()
        }
        .overlay(
            // Success drawer overlay
            Group {
                if showSuccessDrawer, let friend = acceptedFriend {
                    FriendRequestSuccessDrawer(
                        friendUser: friend,
                        isPresented: $showSuccessDrawer,
                        onAddToActivityType: {
                            navigateToAddToActivityType = true
                        }
                    )
                }
            }
        )
        .navigationDestination(isPresented: $navigateToAddToActivityType) {
            if let friend = acceptedFriend {
                AddToActivityTypeView(user: friend)
            }
        }
    }
}

struct FriendRequestItemView: View {
    let friendRequest: FetchFriendRequestDTO
    let isIncoming: Bool
    let onAccept: () -> Void
    let onRemove: () -> Void
    @State private var hasAccepted = false
    @State private var hasRemoved = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Clickable profile section
            NavigationLink(destination: ProfileView(user: friendRequest.senderUser)) {
                HStack(spacing: 12) {
                    // Profile picture
                    if MockAPIService.isMocking {
                        if let pfp = friendRequest.senderUser.profilePicture {
                            Image(pfp)
                                .ProfileImageModifier(imageType: .friendsListView)
                        }
                    } else {
                        if let pfpUrl = friendRequest.senderUser.profilePicture {
                            CachedProfileImage(
                                userId: friendRequest.senderUser.id,
                                url: URL(string: pfpUrl),
                                imageType: .friendsListView
                            )
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 50, height: 50)
                        }
                    }
                    
                    // User info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(FormatterService.shared.formatName(user: friendRequest.senderUser))
                            .font(.headline)
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(friendRequest.senderUser.username ?? "username")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if isIncoming {
                    Button(action: {
                        hasAccepted = true
                        onAccept()
                    }) {
                        Text("Accept")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(hasAccepted ? Color.gray : universalSecondaryColor)
                            )
                    }
                    .disabled(hasAccepted)
                    
                    Button(action: {
                        hasRemoved = true
                        onRemove()
                    }) {
                        Text("Remove")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(universalAccentColor)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(universalAccentColor, lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(hasRemoved)
                } else {
                    Button(action: {
                        hasRemoved = true
                        onRemove()
                    }) {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(universalAccentColor)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(universalAccentColor, lineWidth: 1)
                                    )
                            )
                    }
                    .disabled(hasRemoved)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    NavigationStack {
        FriendRequestsView(userId: UUID())
    }.environmentObject(appCache)
} 
