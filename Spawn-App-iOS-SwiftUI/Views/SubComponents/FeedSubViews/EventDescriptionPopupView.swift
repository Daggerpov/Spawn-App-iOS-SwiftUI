//
//  EventDescriptionPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-18.
//

import SwiftUI

struct EventDescriptionPopupView: View {
	var eventInPopup: Event?
	var colorInPopup: Color?

	var closeDescription: () -> Void

	@Binding var offset: CGFloat

    var body: some View {
		Group{
			if let event = eventInPopup, let color = colorInPopup {
				ZStack {
					Color(.black)
						.opacity(0.5)
						.onTapGesture {
							closeDescription()
						}

					EventDescriptionView(
						event: event,
						users: User.mockUsers,
						color: color
					)
					.fixedSize(horizontal: false, vertical: true)
					.padding()
					.background(.white)
					.clipShape(RoundedRectangle(cornerRadius: 20))
					.shadow(radius: 20)
					.padding(30)
					.offset(x: 0, y: offset)
					.onAppear {
						withAnimation(.spring()) {
							offset = 0
						}
					}
				}
				.ignoresSafeArea()
			}
		}
    }
}
