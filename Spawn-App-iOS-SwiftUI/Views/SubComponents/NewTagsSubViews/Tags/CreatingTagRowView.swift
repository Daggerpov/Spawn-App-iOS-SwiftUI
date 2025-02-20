//
//  CreatingTagRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-22.
//

import SwiftUI

struct CreatingTagRowView: View {
	@EnvironmentObject var viewModel: TagsViewModel

	@Binding var creationStatus: CreationStatus

	// Friend Tag Creation Properties:
	@State private var displayName: String = ""
	@State private var colorHexCode: String = universalAccentColorHexCode

	var body: some View {
		VStack {
			HStack {
				Group {
					TextField("Enter Name", text: $displayName)
						.backgroundStyle(Color(hex: colorHexCode))
						.underline()

					Button(action: {
						Task {
							await viewModel.upsertTag(
								displayName: displayName,
								colorHexCode: colorHexCode,
								upsertAction: .create)
						}

						creationStatus = .doneCreating
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
