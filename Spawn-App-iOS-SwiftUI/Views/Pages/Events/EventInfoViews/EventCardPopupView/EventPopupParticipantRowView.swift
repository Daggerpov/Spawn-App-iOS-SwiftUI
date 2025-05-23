//
//  EventPopupParticipantRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/20/25.
//

import SwiftUI

struct EventPopupParticipantRowView: View {
    var event: FullFeedEventDTO
    @Binding var isParticipating: Bool
    
    
    
    var body: some View {
        HStack(alignment: .center) {
            
            Button(action: {/* Spawn In! */}) {
                let buttonText: String = isParticipating ? "Going" : "Spawn In!"
                let buttonTextColor: Color = isParticipating ? figmaGreen700 : figmaSoftBlue
                HStack {
                    if isParticipating {
                        CheckIcon()
                    } else {
                        StarIcon()
                    }
                    Text(buttonText)
                        
                }
                .font(.onestSemiBold(size: 18))
                .foregroundColor(buttonTextColor)
                .padding(.horizontal, 36)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 2)
                
                
                
            }
            Spacer()
            // Participants Avatars (placeholder)
            ParticipantsImagesView(event: event)
        }
        .padding(.horizontal)
        .padding(.bottom, 18)
    }
}

struct StarIcon: View {
    var body: some View {
        Text(Image(systemName: "star.circle")) // replace with correct SF Symbol name
            .font(.custom("SFProDisplay", size: 16))
            .foregroundColor(figmaSoftBlue)
            .frame(width: 20, height: 19)
    }
}

struct CheckIcon: View {
    var body: some View {
        Text(Image(systemName: "checkmark.circle"))
            .font(.custom("SFProDisplay", size: 16))
            .foregroundColor(figmaGreen700)
            .frame(width: 20, height: 19)
    }
}
