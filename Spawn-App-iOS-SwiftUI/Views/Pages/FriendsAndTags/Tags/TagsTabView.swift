//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
	@StateObject var viewModel: TagsViewModel
	@State private var creationStatus: CreationStatus = .notCreating
    @Environment(\.dismiss) private var dismiss
    
    // Computed property to filter out the "everyone" tag
    private var displayTags: [FullFriendTagDTO] {
        return viewModel.tags.filter { !$0.isEveryone }
    }

	var addFriendToTagButtonPressedCallback: (UUID) -> Void

	init(
		userId: UUID,
		addFriendToTagButtonPressedCallback: @escaping (UUID) -> Void
	) {
		self.addFriendToTagButtonPressedCallback =
			addFriendToTagButtonPressedCallback
		let vm = TagsViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: userId) : APIService(), userId: userId)
		self._viewModel = StateObject(wrappedValue: vm)
	}

	// Function to refresh tags data
	func refreshTags() async {
		await viewModel.fetchAllData()
	}

	var body: some View {
		VStack(spacing: 0) {
            // Header with safe area handling
            ZStack(alignment: .top) {
                // Background color that extends into safe area
                universalBackgroundColor.ignoresSafeArea(edges: .top)
                
                // Header content with padding for safe area
                VStack(spacing: 0) {
                    // This creates space for the status bar
                    Color.clear.frame(height: getSafeAreaTopInset())
                    
                    // Actual header content
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        
                        Spacer()
                        
                        Text("Tags")
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
            }
            
            if displayTags.isEmpty && viewModel.isLoading == false {
                emptyStateView
            } else {
                // Tags content
                VStack(alignment: .leading, spacing: 15) {
                    AddTagButtonView(
                        creationStatus: $creationStatus, color: universalAccentColor
                    )
                    .environmentObject(viewModel)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                tagsSection
            }
		}
		.onAppear {
			Task {
				await viewModel.fetchAllData()
			}
            
            // Add observer for friendsAddedToTag notification
            NotificationCenter.default.addObserver(
                forName: .friendsAddedToTag,
                object: nil,
                queue: .main
            ) { notification in
                Task {
                    // If there's a specific tag ID that was updated, we could handle that here
                    // For now, refresh all tags
                    print("TagsTabView received friendsAddedToTag notification")
                    await refreshTags()
                }
            }
		}
        .onDisappear {
            // Remove the observer when view disappears
            NotificationCenter.default.removeObserver(self, name: .friendsAddedToTag, object: nil)
        }
		.onChange(of: creationStatus) { newValue in
			if newValue == .notCreating {
				Task {
					await viewModel.fetchAllData()
				}
			}
		}
		.background(universalBackgroundColor)
        .navigationBarHidden(true)
	}
    
    // Helper to get safe area inset for the top of the screen
    private func getSafeAreaTopInset() -> CGFloat {
        // Default height that works for most devices with notches
        return 47
    }
}

extension TagsTabView {
    var emptyStateView: some View {
        VStack(spacing: 25) {
            Spacer()
            
            // Circle for animation placeholder
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray.opacity(0.5))
                .frame(width: 200, height: 200)
                .overlay(
                    Text("[insert rive\nanimation here]")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                )
            
            // No Tags text
            Text("No Tags Yet!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description text
            Text("Friend tags are the best way to streamline the flow for inviting groups of friends to hang out.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Create First Tag button
            Button(action: {
                creationStatus = .creating
            }) {
                HStack {
                    Image(systemName: "plus")
                    Text("Create First Tag")
                        .fontWeight(.medium)
                }
                .foregroundColor(.green)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.green, style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
            }
            
            Spacer()
            Spacer()
        }
        .padding()
    }

	var tagsSection: some View {
		ScrollView {
            VStack(spacing: 15) {
                ForEach(displayTags) { friendTag in
                    NavigationLink(destination: TagDetailView(tag: friendTag)) {
                        ZStack {
                            // Rounded rectangle with tag color
                            RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                                .fill(Color(hex: friendTag.colorHexCode))
                                .frame(height: 120)
                            
                            // Content overlay
                            VStack(alignment: .leading) {
                                HStack {
                                    // Tag name
                                    Text(friendTag.displayName)
                                        .foregroundColor(.white)
                                        .font(.system(size: 32, weight: .bold))
                                        .padding(.leading)
                                    
                                    Spacer()
                                }
                                .padding(.top, 15)
                                
                                Spacer()
                                
                                // Tag member count and preview
                                HStack {
                                    // Number of people text
                                    Text("\(friendTag.friends?.count ?? 0) people")
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.leading)
                                        .opacity(0.8)
                                    
                                    Spacer()
                                    
                                    // Friend avatars preview
                                    TagFriendsPreview(friendTag: friendTag, viewModel: viewModel)
                                        .padding(.trailing)
                                }
                                .padding(.bottom, 15)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
		}
	}
}

// MARK: - Friend Preview Component

struct TagFriendsPreview: View {
    var friendTag: FullFriendTagDTO
    @ObservedObject var viewModel: TagsViewModel
    
    // Computed properties to use throughout the view
    private var displayedFriends: [BaseUserDTO] {
        return (friendTag.friends ?? []).prefix(2).map { $0 }
    }
    
    private var remainingCount: Int {
        return (friendTag.friends?.count ?? 0) - displayedFriends.count
    }

    var body: some View {
        HStack(spacing: -5) {
            // Show only up to 2 friend avatars
            ForEach(Array(displayedFriends.enumerated()), id: \.element.id) { index, friend in
                ProfileImageView(userId: friend.id, urlString: friend.profilePicture, viewModel: viewModel)
            }
            
            // Show "+X" indicator if there are more than 2 friends
            if remainingCount > 0 {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 30, height: 30)
                    
                    Text("+\(remainingCount)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(hex: friendTag.colorHexCode))
                }
            }
        }
    }
}

// MARK: - Profile Image Component with Caching

struct ProfileImageView: View {
    var userId: UUID
    var urlString: String?
    @ObservedObject var viewModel: TagsViewModel
    
    var body: some View {
        ZStack {
            if let urlString = urlString {
                if MockAPIService.isMocking {
                    Image(urlString)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                } else {
                    // Get URL from cache if available, otherwise use the provided URL
                    let finalURLString = viewModel.getProfilePictureURL(for: userId) ?? urlString
                    
                    AsyncImage(url: URL(string: finalURLString)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    .id("profile-\(finalURLString)")
                }
            } else {
                // Fallback for no profile picture
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.gray.opacity(0.5)))
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	TagsTabView(userId: UUID(), addFriendToTagButtonPressedCallback: {_ in })
}
