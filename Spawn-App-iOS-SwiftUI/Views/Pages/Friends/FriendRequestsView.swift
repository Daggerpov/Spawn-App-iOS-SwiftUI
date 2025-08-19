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
            headerView
            contentView
            Spacer()
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchFriendRequests()
        }
        .overlay(successDrawerOverlay)
        .onChange(of: showSuccessDrawer) { isPresented in
            if !isPresented {
                Task { await viewModel.fetchFriendRequests() }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .friendRequestsDidChange)) { _ in
            Task { await viewModel.fetchFriendRequests() }
        }
        .navigationDestination(isPresented: $navigateToAddToActivityType) {
            if let friend = acceptedFriend {
                AddToActivityTypeView(user: friend)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
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
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.incomingFriendRequests.isEmpty && viewModel.sentFriendRequests.isEmpty {
                    emptyStateView
                } else {
                    friendRequestsContent
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ProgressView()
            .padding()
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        Text("No friend requests")
            .foregroundColor(.gray)
            .padding(.top, 40)
    }
    
    // MARK: - Friend Requests Content
    private var friendRequestsContent: some View {
        VStack(spacing: 0) {
            incomingFriendRequestsSection
            sectionDivider
            sentFriendRequestsSection
        }
    }
    
    // MARK: - Incoming Friend Requests Section
    private var incomingFriendRequestsSection: some View {
        Group {
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
                                handleAcceptRequest(request)
                            },
                            onRemove: {
                                handleDeclineRequest(request)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Section Divider
    private var sectionDivider: some View {
        Group {
            if !viewModel.incomingFriendRequests.isEmpty && !viewModel.sentFriendRequests.isEmpty {
                Divider()
                    .background(universalPlaceHolderTextColor)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - Sent Friend Requests Section
    private var sentFriendRequestsSection: some View {
        Group {
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
                        SentFriendRequestItemView(
                            friendRequest: request,
                            onRemove: {
                                handleCancelSentRequest(request)
                            }
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
            }
        }
    }
    
    // MARK: - Success Drawer Overlay
    private var successDrawerOverlay: some View {
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
    }
    
    // MARK: - Helper Methods
    private func handleAcceptRequest(_ request: FetchFriendRequestDTO) {
        // Set acceptedFriend BEFORE calling respondToFriendRequest
        // because that method immediately removes the request from the array
        acceptedFriend = request.senderUser
        Task {
            await viewModel.respondToFriendRequest(requestId: request.id, action: .accept)
            // Show success drawer after successful acceptance
            showSuccessDrawer = true
        }
    }
    
    private func handleDeclineRequest(_ request: FetchFriendRequestDTO) {
        Task {
            await viewModel.respondToFriendRequest(requestId: request.id, action: .decline)
        }
    }
    
    private func handleCancelSentRequest(_ request: FetchSentFriendRequestDTO) {
        Task {
            await viewModel.respondToFriendRequest(requestId: request.id, action: .cancel)
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

struct SentFriendRequestItemView: View {
    let friendRequest: FetchSentFriendRequestDTO
    let onRemove: () -> Void
    @State private var hasRemoved = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Clickable profile section
            NavigationLink(destination: ProfileView(user: friendRequest.receiverUser)) {
                HStack(spacing: 12) {
                    // Profile picture
                    if MockAPIService.isMocking {
                        if let pfp = friendRequest.receiverUser.profilePicture {
                            Image(pfp)
                                .ProfileImageModifier(imageType: .friendsListView)
                        }
                    } else {
                        if let pfpUrl = friendRequest.receiverUser.profilePicture {
                            CachedProfileImage(
                                userId: friendRequest.receiverUser.id,
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
                        Text(FormatterService.shared.formatName(user: friendRequest.receiverUser))
                            .font(.headline)
                            .foregroundColor(universalAccentColor)
                        
                        Text("@\(friendRequest.receiverUser.username ?? "username")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Cancel button
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
