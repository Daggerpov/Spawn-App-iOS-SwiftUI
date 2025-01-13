//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
	@ObservedObject var viewModel: TagsTabViewModel

	init(user: User) {
		self.viewModel = TagsTabViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(), user: user)
	}

	var body: some View {
		VStack {
			VStack(alignment: .leading, spacing: 15) {
				Text("TAGS")
					.font(.headline)

				AddTagButton(color: universalAccentColor)
			}
			Spacer()
			Spacer()
			tagsSection
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
