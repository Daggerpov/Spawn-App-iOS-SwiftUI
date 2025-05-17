//
//  TagDetailView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-11.
//

import SwiftUI

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appCache: AppCache
    var tag: FullFriendTagDTO
    @State private var showAddFriendToTagView: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with tag name
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Text("Tags / \(tag.displayName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Menu button
                    Button(action: {
                        // Show options menu (future implementation)
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Tag visual element (pink circle with people)
                VStack {
                    ZStack {
                        // Tag circle background
                        Circle()
                            .fill(Color(hex: tag.colorHexCode).opacity(0.5))
                            .frame(width: 240, height: 240)
                        
                        // Tag name text
                        VStack {
                            Text(tag.displayName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(tag.friends?.count ?? 0) people")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // People icons overlapping
                        if let friends = tag.friends, !friends.isEmpty {
                            HStack(spacing: -10) {
                                ForEach(friends.prefix(3)) { friend in
                                    if let pfpUrl = friend.profilePicture {
                                        AsyncImage(url: URL(string: pfpUrl)) { image in
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 40, height: 40)
                                                .clipShape(Circle())
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        } placeholder: {
                                            Circle()
                                                .fill(Color.gray)
                                                .frame(width: 40, height: 40)
                                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color.gray)
                                            .frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    }
                                }
                                
                                if (tag.friends?.count ?? 0) > 3 {
                                    ZStack {
                                        Circle()
                                            .fill(universalAccentColor)
                                            .frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        
                                        Text("+\((tag.friends?.count ?? 0) - 3)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .offset(y: 60)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 60)
                }
                
                // People section header
                HStack {
                    Text("People (\(tag.friends?.count ?? 0))")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Button(action: {
                        // Show all action (future implementation)
                    }) {
                        Text("Show All")
                            .font(.subheadline)
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal)
                
                // People list
                ScrollView {
                    VStack(spacing: 0) {
                        if let friends = tag.friends, !friends.isEmpty {
                            ForEach(friends) { friend in
                                HStack {
                                    // Profile image
                                    if let pfpUrl = friend.profilePicture {
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
                                    
                                    // Options button
                                    Button(action: {
                                        // Show options (future implementation)
                                    }) {
                                        Image(systemName: "ellipsis")
                                            .font(.title3)
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                
                                Divider()
                            }
                        } else {
                            VStack(spacing: 20) {
                                Text("No people in this tag yet")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                                
                                Text("Tap the + button to add friends to this tag")
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddFriendToTagView = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(universalAccentColor)
                                .frame(width: 60, height: 60)
                                .shadow(radius: 3)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .sheet(isPresented: $showAddFriendToTagView) {
            AddFriendToTagView(
                userId: appCache.currentUser?.id ?? UUID(), // Use the current user ID from appCache
                friendTagId: tag.id,
                closeCallback: {
                    showAddFriendToTagView = false
                    // Handle any refresh needed after adding friends
                }
            )
            .presentationDragIndicator(.visible)
            .presentationDetents([.height(400)])
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    TagDetailView(tag: FullFriendTagDTO.close)
        .environmentObject(appCache)
} 