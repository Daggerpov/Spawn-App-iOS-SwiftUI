//
//  TagsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct TagsTabView: View {
	@ObservedObject var viewModel: TagsViewModel

	init(user: User) {
		self.viewModel = TagsViewModel(
			apiService: MockAPIService.isMocking
				? MockAPIService() : APIService(), user: user)
	}

	var body: some View {
		VStack {
			VStack(alignment: .leading, spacing: 15) {
				Text("TAGS")
					.font(.headline)

				AddTagButtonView(color: universalAccentColor)
					.environmentObject(viewModel)
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
