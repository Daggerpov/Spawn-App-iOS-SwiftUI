//
//  CreatingTagRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-22.
//

import SwiftUI

struct CreatingTagRowView: View {
	@EnvironmentObject var viewModel: TagsViewModel

	// Friend Tag Creation Properties:
	@State private var displayName: String = ""
	@State private var colorHexCode: String = universalAccentColorHexCode

	var body: some View {
		VStack {
			HStack {
				Group {
					TextField("Enter Name", text: $displayName)
						.underline()
					Button(action: {
						Task{
							await viewModel.createTag(displayName: displayName, colorHexCode: colorHexCode)
						}
						// TODO: fill in logic to create tag
						// TODO: fill in action to rename title later
					}) {
						Image(systemName: "checkmark")
					}
				}
				.foregroundColor(.white)
				.font(.title)
				.fontWeight(.semibold)

				Spacer()
			}
			.padding()
			.background(
				RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
					.fill(Color(hex: colorHexCode))
			)
			VStack(spacing: 15) {
				HStack {
					Spacer()
				}
				ColorOptions(currentSelectedColorHexCode: $colorHexCode)
			}
			.padding(.horizontal)
			.padding(.bottom)
		}
	}
}
