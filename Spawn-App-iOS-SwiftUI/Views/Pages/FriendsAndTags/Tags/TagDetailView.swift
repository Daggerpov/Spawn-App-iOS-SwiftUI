//
//  TagDetailView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-11.
//

import SwiftUI

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismiss
    // Access AppCache as a singleton
    @State private var showAddFriendsToTagView: Bool = false
    @State private var showActionSheet: Bool = false
    @State private var showManageTaggedPeopleView: Bool = false
    @State private var showRenameTagView: Bool = false
    @State private var showChangeTagColorView: Bool = false
    @State private var showDeleteTagConfirmation: Bool = false
    
    var tag: FullFriendTagDTO
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with tag name
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Text("Tags / \(tag.displayName)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Menu button
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.primary)
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
                        
                        // Tag name and count
                        VStack(spacing: 4) {
                            Text(tag.displayName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(tag.friends?.count ?? 0) people")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // People icons overlapping
                        if let friends = tag.friends, !friends.isEmpty {
                            HStack(spacing: -8) {
                                ForEach(friends.prefix(2)) { friend in
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
                                
                                if (tag.friends?.count ?? 0) > 2 {
                                    ZStack {
                                        Circle()
                                            .fill(.white)
                                            .frame(width: 40, height: 40)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        
                                        Text("+\((tag.friends?.count ?? 0) - 2)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Color(hex: tag.colorHexCode))
                                    }
                                }
                            }
                            .offset(y: -70)
                            .offset(x: 40)
                        }
                    }
                    .padding(.top, 20)
                }
                
                // People section header
                HStack {
                    Text("People (\(tag.friends?.count ?? 0))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        showManageTaggedPeopleView = true
                    }) {
                        Text("Show All")
                            .font(.subheadline)
                            .foregroundColor(universalAccentColor)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
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
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(friend.name ?? "First Last")
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
                                            .font(.system(size: 20))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                
                                Divider()
                                    .padding(.leading, 16)
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
                
                Spacer(minLength: 60) // Add space for tab bar and floating button
            }
            .background(universalBackgroundColor)
            .navigationBarHidden(true)
            
            // Tab bar at bottom
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(0..<5) { index in
                        VStack {
                            Image(systemName: tabBarIcons[index])
                                .font(.system(size: 24))
                                .foregroundColor(.gray)
                            
                            if index == 3 {
                                Rectangle()
                                    .frame(width: 30, height: 2)
                                    .cornerRadius(1)
                                    .foregroundColor(universalAccentColor)
                                    .padding(.top, 4)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .background(universalBackgroundColor)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color.gray.opacity(0.3)),
                    alignment: .top
                )
            }
            
            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddFriendsToTagView = true
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
                    .padding(.bottom, 60) // Adjust to position above tab bar
                }
            }
            
            // Show action sheet if active
            if showActionSheet {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showActionSheet = false
                    }
                
                TagActionSheet(
                    tag: tag,
                    onRenameTag: {
                        // Handle rename tag action
                        showRenameTagView = true
                    },
                    onChangeTagColor: {
                        // Handle change tag color action
                        showChangeTagColorView = true
                    },
                    onManageTaggedPeople: {
                        // Handle manage tagged people action
                        showManageTaggedPeopleView = true
                    },
                    onDeleteTag: {
                        // Handle delete tag action
                        showDeleteTagConfirmation = true
                    },
                    onDismiss: {
                        showActionSheet = false
                    }
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .sheet(isPresented: $showAddFriendsToTagView) {
            // Using AddFriendsToTagView for adding multiple friends to this tag
            NavigationView {
                AddFriendsToTagView(friendTagId: tag.id)
                    .onDisappear {
                        // Refresh data if needed after adding friends
                        // You might want to add additional refresh logic here
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showManageTaggedPeopleView) {
            ManageTaggedPeopleView(tag: tag)
        }
        .alert("Delete Tag", isPresented: $showDeleteTagConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete tag implementation would go here
                // For example:
                // Task {
                //     await tagsViewModel.deleteTag(id: tag.id)
                //     dismiss()
                // }
            }
        } message: {
            Text("Are you sure you want to delete this tag? This action cannot be undone.")
        }
        // Add other sheets for rename tag and change tag color here when implemented
    }
    
    // Tab bar icons
    private let tabBarIcons = [
        "house", "paperplane", "plus.square", "list.bullet", "person.circle"
    ]
}

@available(iOS 17, *)
#Preview {
    TagDetailView(tag: FullFriendTagDTO.close)
} 
