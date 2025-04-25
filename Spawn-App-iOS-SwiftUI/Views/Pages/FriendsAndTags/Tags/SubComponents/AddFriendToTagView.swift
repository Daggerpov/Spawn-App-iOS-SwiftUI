//
//  AddFriendToTagView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-06.
//

import SwiftUI

struct AddFriendToTagView: View {
	@ObservedObject var viewModel: AddFriendToTagViewModel
	var userId: UUID
	var friendTagId: UUID

	@StateObject var searchViewModel: SearchViewModel = SearchViewModel()
	var closeCallback: (() -> Void)?
	@State private var isLoading: Bool = true
	@State private var loadedFriends: [BaseUserDTO] = []

	init(userId: UUID, friendTagId: UUID, closeCallback: @escaping () -> Void) {
		self.userId = userId
		self.friendTagId = friendTagId
		self.closeCallback = closeCallback
		
		// Initialize view model
        let vm = AddFriendToTagViewModel(userId: userId, apiService: MockAPIService.isMocking
                                         ? MockAPIService(userId: userId)
                                         : APIService())
		self.viewModel = vm
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 20) {
			SearchView(
				searchPlaceholderText: "Search or add friends",
				viewModel: searchViewModel)
			
			ZStack {
				if isLoading {
					ProgressView()
						.frame(maxWidth: .infinity, maxHeight: 160)
						.padding()
				} else if loadedFriends.count > 0 {
					ScrollView {
						LazyVStack {
							ForEach(loadedFriends) { friend in
								FriendRowForAddingFriendsToTag(
									friend: friend, viewModel: viewModel
								)
								.padding(.horizontal)
							}
						}
					}
					.frame(maxHeight: 160)
				} else if let error = viewModel.errorMessage {
					VStack {
						Text(error)
							.foregroundColor(.red)
							.padding()
							.multilineTextAlignment(.center)
						
						Button("Retry") {
							Task {
								isLoading = true
								await viewModel.fetchAllData(friendTagId: friendTagId)
								await MainActor.run {
									loadedFriends = viewModel.friends
									isLoading = false
								}
							}
						}
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 8)
						.padding(.horizontal, 20)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.stroke(universalAccentColor, lineWidth: 1)
						)
					}
					.frame(maxWidth: .infinity, maxHeight: 160)
				} else {
					Text(
						"You've added all your friends to this tag! It's time to add some more friends!"
					)
					.foregroundColor(universalAccentColor)
					.padding()
					.multilineTextAlignment(.center)
					.frame(maxWidth: .infinity, maxHeight: 160)
				}
			}
			
			doneButtonView
		}
		.padding(20)
		.background(universalBackgroundColor)
		.task {
			await loadFriends()
		}
	}
	
	func loadFriends() async {
		isLoading = true
		await viewModel.fetchAllData(friendTagId: friendTagId)
		await MainActor.run {
			loadedFriends = viewModel.friends
			print("DEBUG isLoading set to false, friends count: \(loadedFriends.count)")
			isLoading = false
		}
	}
}

struct FriendRowForAddingFriendsToTag: View {
	var friend: BaseUserDTO
	@State private var isClicked: Bool
	@ObservedObject var viewModel: AddFriendToTagViewModel

	init(friend: BaseUserDTO, viewModel: AddFriendToTagViewModel) {
		self.friend = friend
		self.viewModel = viewModel
		let isAlreadySelected = viewModel.selectedFriends.contains { $0.id == friend.id }
		self._isClicked = State(initialValue: isAlreadySelected)
	}

	var body: some View {
		Button(action: {
			// TODO: add to selected friends
			isClicked.toggle()
			viewModel.toggleFriendSelection(friend)
		}) {
			HStack {
				if let pfpUrl = friend.profilePicture {
					AsyncImage(url: URL(string: pfpUrl)) {
						image in
						image
							.ProfileImageModifier(imageType: .tagFriends)
					} placeholder: {
						Circle()
							.fill(Color.gray)
							.frame(width: 35, height: 35)
					}
				} else {
					Circle()
						.fill(Color.gray)
						.frame(width: 35, height: 35)
				}

				Image(systemName: "star.fill")
					.font(.system(size: 10))
				Text(FormatterService.shared.formatName(user: friend))
					.font(.headline)
				Spacer()
			}
			.foregroundColor(isClicked ? .white : universalAccentColor)
			.frame(maxWidth: .infinity)
			.padding(6)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(
						isClicked
							? universalAccentColor
							: universalBackgroundColor
								.opacity(0.5)
					)
					.cornerRadius(
						universalRectangleCornerRadius
					)
			)
		}
	}
}

extension AddFriendToTagView {
	var doneButtonView: some View {
		Button(action: {
			Task {
				await viewModel.addSelectedFriendsToTag(
					friendTagId: friendTagId)
				
				// Wait a brief moment to ensure the server has processed the request
				try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
				
				// Call the close callback after all operations are complete
				await MainActor.run {
					closeCallback?()
				}
			}
		}) {
			HStack {
				Text("done")
					.font(.headline)
			}
			.padding(.vertical)
			.foregroundColor(.white)
			.frame(maxWidth: .infinity)
			.background(
				RoundedRectangle(cornerRadius: 12)
					.fill(universalAccentColor)
					.cornerRadius(
						universalRectangleCornerRadius
					)
			)
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	AddFriendToTagView(userId: UUID(), friendTagId: UUID(), closeCallback: {}).environmentObject(appCache)
}
