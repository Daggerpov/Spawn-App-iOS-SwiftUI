//
//  EventCreationPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-18.
//

import SwiftUI

struct EventCreationPopupView: View {
	var user: User

	var closeCreation: () -> Void

	@Binding var offset: CGFloat

    var body: some View {
		ZStack {
			Color(.black)
				.opacity(0.5)
				.onTapGesture {
					closeCreation()
				}

			VStack{
				Spacer()
				EventCreationView(creatingUser: user)
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
				Spacer()
			}
		}
		.ignoresSafeArea()
    }
}
