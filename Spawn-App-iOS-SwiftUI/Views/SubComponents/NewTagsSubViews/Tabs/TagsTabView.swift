//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
	@ObservedObject var viewModel: TagsViewModel
	@State private var creationStatus: CreationStatus = .notCreating

	var addFriendToTagButtonPressedCallback: (UUID) -> Void

	init(
		userId: UUID,
		addFriendToTagButtonPressedCallback: @escaping (UUID) -> Void
	) {
		self.addFriendToTagButtonPressedCallback =
			addFriendToTagButtonPressedCallback
		self.viewModel = TagsViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService(userId: userId) : APIService(), userId: userId)
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
				await viewModel.fetchTags()
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

#Preview {
	TagsTabView(userId: UUID(), addFriendToTagButtonPressedCallback: {_ in })
}
