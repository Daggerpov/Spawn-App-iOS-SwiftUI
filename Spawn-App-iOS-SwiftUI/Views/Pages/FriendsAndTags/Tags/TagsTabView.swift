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
		VStack {
			VStack(alignment: .leading, spacing: 15) {
				Text("TAGS")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				AddTagButtonView(
					creationStatus: $creationStatus, color: universalAccentColor
				)
				.environmentObject(viewModel)
			}
			Spacer()
			Spacer()
			tagsSection
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
		.padding()
	}
}

extension TagsTabView {
	var tagsSection: some View {
		Group {
			ScrollView {
				VStack(spacing: 15) {
					ForEach(viewModel.tags) { friendTag in
						TagRow(
							friendTag: friendTag,
							addFriendToTagButtonPressedCallback:
								addFriendToTagButtonPressedCallback
						)
						.background(
							RoundedRectangle(cornerRadius: 12)
								.fill(
									Color(hex: friendTag.colorHexCode)
										.opacity(0.5)
								)
								.cornerRadius(
									universalRectangleCornerRadius
								)
						)
						.environmentObject(viewModel)
					}
				}
			}
		}
	}
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	TagsTabView(userId: UUID(), addFriendToTagButtonPressedCallback: {_ in }).environmentObject(appCache)
}
