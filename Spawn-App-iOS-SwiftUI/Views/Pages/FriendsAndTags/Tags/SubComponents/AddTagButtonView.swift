//
//  AddTagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/25/24.
//

import SwiftUI

struct AddTagButtonView: View {
	@Binding var creationStatus: CreationStatus
    
	var closeCallback: (() -> Void)?
	var friendTagId: UUID?

	var color: Color

	var body: some View {
		VStack {
			Button(action: {
				if creationStatus == .creating {
					creationStatus = .notCreating
				} else {
					creationStatus = .creating
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
			if creationStatus == .creating {
				CreatingTagRowView(creationStatus: $creationStatus)
					.background(
						RoundedRectangle(cornerRadius: 12)
							.fill(
								color
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

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
	@Previewable @State var creationStatus: CreationStatus = .creating
	AddTagButtonView(
		creationStatus: $creationStatus,
		color: Color(universalAccentColor)
	)
}
