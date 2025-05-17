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
            // Header
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
                        HStack {
                            Text(friendTag.displayName)
                                .foregroundColor(.white)
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.leading)
                            
                            Spacer()
                            
                            // Show tag friends preview
                            TagFriendsPreview(friends: friendTag.friends)
                                .padding(.trailing)
                        }
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                                .fill(Color(hex: friendTag.colorHexCode).opacity(0.5))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
		}
	}
}

struct TagFriendsPreview: View {
    var friends: [BaseUserDTO]?
    
    // Computed properties to use throughout the view
    private var displayedFriends: [BaseUserDTO] {
        return (friends ?? []).prefix(3).map { $0 }
    }
    
    private var remainingCount: Int {
        return (friends?.count ?? 0) - displayedFriends.count
    }
    
    private var trailingPadding: CGFloat {
        return min(CGFloat(displayedFriends.count) * 15, 45) + (remainingCount > 0 ? 30 : 0)
    }

    var body: some View {
        HStack {
            ZStack {
                // Show only up to 3 friends
                ForEach(
                    Array(displayedFriends.enumerated().reversed()), id: \.element.id
                ) { index, friend in
                    if let pfpUrl = friend.profilePicture {
                        AsyncImage(url: URL(string: pfpUrl)) { image in
                            image
                                .ProfileImageModifier(imageType: .eventParticipants)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 25, height: 25)
                        }
                        .offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
                    } else {
                        Circle()
                            .fill(.gray)
                            .frame(width: 25, height: 25)
                            .offset(x: CGFloat(index) * 15)  // Adjust overlap spacing
                    }
                }
                
                // Show "+X" indicator if there are more than 3 friends
                if remainingCount > 0 {
                    Text("+\(remainingCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 25, height: 25)
                        .background(Circle().fill(universalAccentColor))
                        .offset(x: 45)  // Position after the 3rd friend
                }
            }
            .padding(.trailing, trailingPadding)
            
            // Add the chevron indicator
            Image(systemName: "chevron.right")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .bold))
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	TagsTabView(userId: UUID(), addFriendToTagButtonPressedCallback: {_ in }).environmentObject(appCache)
}
