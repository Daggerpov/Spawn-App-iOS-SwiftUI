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

	init(user: User) {
		self.viewModel = TagsViewModel(
			apiService: MockAPIService.isMocking
			? MockAPIService(userId: user.id) : APIService(), user: user)
	}

	var body: some View {
		VStack {
			VStack(alignment: .leading, spacing: 15) {
				Text("TAGS")
					.font(.headline)
					.foregroundColor(universalAccentColor)

				AddTagButtonView(creationStatus: $creationStatus, color: universalAccentColor)
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
						TagRow(friendTag: friendTag)
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
					}
				}
			}
		}
	}
}
