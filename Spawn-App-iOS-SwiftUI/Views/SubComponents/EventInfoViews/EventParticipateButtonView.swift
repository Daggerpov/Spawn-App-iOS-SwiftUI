//
//  EventParticipateButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventParticipateButtonView: View {
    var toggleParticipationCallback: () -> Void
    var isParticipating: Bool
    var color: Color
    var body: some View {
        Circle()
            .frame(width: 40, height: 40)
            .foregroundColor(.white)
            .background(Color.white)
            .clipShape(Circle())
            .overlay(
                Button(action: {
                    toggleParticipationCallback()
                }) {
                    Image(systemName: isParticipating ? "checkmark" : "star.fill")
                        .resizable()
                        .frame(width: 17.5, height: 17.5)
                        .clipShape(Circle())
                        .shadow(radius: 20)
                        .foregroundColor(color)
                }
            )
    }
}
