//
//  AddTagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct AddTagButtonView: View {
	@State private var isCreatingTag: Bool = false
	@EnvironmentObject var viewModel: TagsViewModel

	var color: Color

	var body: some View {
		VStack {
			Button(action: {
				toggleIsCreatingTag()
				Task {
					await viewModel.createTag()
				}
			}) {
				RoundedRectangle(cornerRadius: 12)
					.stroke(
						color, style: StrokeStyle(lineWidth: 2, dash: [4])
					)
					.frame(height: 50)
					.overlay(
						Image(systemName: "plus")
							.font(.system(size: 24, weight: .bold))
							.foregroundColor(color)
					)
					.padding(.horizontal, 10)
					.padding(.vertical, 5)
					.padding(.bottom, 10)
			}
			if isCreatingTag {
				CreatingTagRowView()
			}
		}
	}

	private func toggleIsCreatingTag() {
		if isCreatingTag {
			isCreatingTag = false
		} else {
			isCreatingTag = true
		}
	}
}
