//
//  TagDetailView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-06-11.
//

import SwiftUI

struct TagDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: TagsViewModel
    // Access AppCache as a singleton
    @State private var showAddFriendsToTagView: Bool = false
    @State private var showActionSheet: Bool = false
    @State private var showManageTaggedPeopleView: Bool = false
    @State private var showRenameTagView: Bool = false
    @State private var showChangeTagColorView: Bool = false
    @State private var showDeleteTagConfirmation: Bool = false
    @State private var tagDisplayName: String = ""
    @State private var tagColorHex: String = ""
    @State private var showRemoveFriendAlert: Bool = false
    @State private var friendToRemove: BaseUserDTO? = nil
    
    // Initial tag data for reference
    var tagId: UUID
    
    // Computed property to get the current tag data from ViewModel
    private var tag: FullFriendTagDTO {
        viewModel.tags.first(where: { $0.id == tagId }) ?? FullFriendTagDTO.empty
    }

	// Initialize with TagsViewModel and tag ID
	init(viewModel: TagsViewModel, tagId: UUID) {
		self.viewModel = viewModel
		self.tagId = tagId
	}

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
                    }
                }
				.foregroundColor(universalAccentColor)
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
                                    
                                    // Remove friend button
                                    Button(action: {
                                        // Show confirmation alert instead of removing immediately
                                        friendToRemove = friend
                                        showRemoveFriendAlert = true
                                    }) {
                                        Image(systemName: "minus.circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(.red)
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
                        tagDisplayName = tag.displayName
                        showRenameTagView = true
                        showActionSheet = false
                    },
                    onChangeTagColor: {
                        // Handle change tag color action
                        tagColorHex = tag.colorHexCode
                        showChangeTagColorView = true
                        showActionSheet = false
                    },
                    onManageTaggedPeople: {
                        // Handle manage tagged people action
                        showManageTaggedPeopleView = true
                        showActionSheet = false
                    },
                    onDeleteTag: {
                        // Handle delete tag action
                        showDeleteTagConfirmation = true
                        showActionSheet = false
                    },
                    onDismiss: {
                        showActionSheet = false
                    }
                )
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .onAppear {
            // Ensure we have the latest data when view appears
            Task {
                await viewModel.fetchAllData()
            }
        }
        .sheet(isPresented: $showAddFriendsToTagView) {
            // Using AddFriendsToTagView for adding multiple friends to this tag
            NavigationView {
                AddFriendsToTagView(friendTagId: tagId)
                    .onDisappear {
                        // Refresh data after adding friends
                        Task {
                            await viewModel.fetchAllData()
                        }
                    }
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showManageTaggedPeopleView) {
            ManageTaggedPeopleView(tagsViewModel: viewModel, tagId: tagId)
                .onDisappear {
                    // Refresh data after managing tagged people
                    Task {
                        await viewModel.fetchAllData()
                    }
                }
        }
        .sheet(isPresented: $showRenameTagView) {
            // Rename tag view
            TagRenameView(
                displayName: $tagDisplayName,
                onSave: {
                    // Save the renamed tag
                    Task {
                        await viewModel.upsertTag(
                            id: tag.id,
                            displayName: tagDisplayName,
                            colorHexCode: tag.colorHexCode,
                            upsertAction: .update
                        )
                    }
                },
                onCancel: {
                    // Cancel renaming
                    tagDisplayName = tag.displayName
                }
            )
        }
        .sheet(isPresented: $showChangeTagColorView) {
            // Change tag color view
            TagColorPickerView(
                currentColorHex: $tagColorHex,
                onSave: {
                    // Save the color change
                    Task {
                        await viewModel.upsertTag(
                            id: tag.id,
                            displayName: tag.displayName,
                            colorHexCode: tagColorHex,
                            upsertAction: .update
                        )
                    }
                },
                onCancel: {
                    // Cancel color change
                    tagColorHex = tag.colorHexCode
                }
            )
        }
        .alert("Delete Tag", isPresented: $showDeleteTagConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // Delete tag implementation
                Task {
                    await viewModel.deleteTag(id: tag.id)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete this tag? This action cannot be undone.")
        }
        .alert("Remove from Tag", isPresented: $showRemoveFriendAlert) {
            Button("Cancel", role: .cancel) { 
                friendToRemove = nil
            }
            Button("Remove", role: .destructive) {
                // Remove friend from tag when confirmed
                if let friend = friendToRemove {
                    Task {
                        await viewModel.removeFriendFromFriendTag(friendUserId: friend.id, friendTagId: tag.id)
                    }
                    friendToRemove = nil
                }
            }
        } message: {
            Text("Are you sure you want to remove this person from the tag?")
        }
        // Listen for friendsAddedToTag notification
        .onReceive(NotificationCenter.default.publisher(for: .friendsAddedToTag)) { _ in
            // Refresh data when notification is received
            Task {
                await viewModel.fetchAllData()
            }
        }
    }
    

}

// Helper structures for tag management

struct TagRenameView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var displayName: String
    var onSave: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Tag Name", text: $displayName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("Rename Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(displayName.isEmpty)
                }
            }
        }
    }
}

struct TagColorPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var currentColorHex: String
    var onSave: () -> Void
    var onCancel: () -> Void
    
    // Predefined colors
    let colors = [
        "#FF6B6B", "#4ECDC4", "#F9DC5C", "#3A86FF", 
        "#8338EC", "#FF006E", "#FB5607", "#FFBE0B",
        "#06D6A0", "#118AB2", "#073B4C", "#7B2CBF"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // Current color preview
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: currentColorHex))
                    .frame(height: 80)
                    .padding()
                
                // Color grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                    ForEach(colors, id: \.self) { colorHex in
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(currentColorHex == colorHex ? Color.white : Color.clear, lineWidth: 3)
                            )
                            .onTapGesture {
                                currentColorHex = colorHex
                            }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Choose Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    let viewModel = TagsViewModel(apiService: MockAPIService(userId: UUID()), userId: UUID())
    return TagDetailView(viewModel: viewModel, tagId: FullFriendTagDTO.close.id)
} 
