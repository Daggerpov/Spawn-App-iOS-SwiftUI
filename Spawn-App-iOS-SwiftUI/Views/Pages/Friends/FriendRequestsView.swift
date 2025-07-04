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
                    } else if viewModel.friendRequests.isEmpty {
                        Text("No friend requests")
                            .foregroundColor(.gray)
                            .padding(.top, 40)
                    } else {
                        ForEach(viewModel.friendRequests) { request in
                            FriendRequestItemView(
                                friendRequest: request,
                                onAccept: {
                                    Task {
                                        await viewModel.respondToFriendRequest(requestId: request.id, action: .accept)
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
            }
            
            Spacer()
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchFriendRequests()
        }
    }
}

struct FriendRequestItemView: View {
    let friendRequest: FetchFriendRequestDTO
    let onAccept: () -> Void
    let onRemove: () -> Void
    @State private var hasAccepted = false
    @State private var hasRemoved = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            if MockAPIService.isMocking {
                if let pfp = friendRequest.senderUser.profilePicture {
                    Image(pfp)
                        .ProfileImageModifier(imageType: .friendsListView)
                }
            } else {
                if let pfpUrl = friendRequest.senderUser.profilePicture {
                    AsyncImage(url: URL(string: pfpUrl)) { image in
                        image.ProfileImageModifier(imageType: .friendsListView)
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
            }
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(FormatterService.shared.formatName(user: friendRequest.senderUser))
                    .font(.headline)
                
                Text("@\(friendRequest.senderUser.username)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button(action: {
                    hasAccepted = true
                    onAccept()
                }) {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(hasAccepted ? universalBackgroundColor : authPageBackgroundColor)
                        )
                }
                
                Button(action: {
                    hasRemoved = true
                    onRemove()
                }) {
                    Text("Remove")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(universalAccentColor)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(universalBackgroundColor.opacity(0.9))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(universalPlaceHolderTextColor, lineWidth: 1)
                                )
                        )
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