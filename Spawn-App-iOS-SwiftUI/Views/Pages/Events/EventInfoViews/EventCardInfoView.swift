//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/10/25.
//


import SwiftUI

struct EventCardInfoView: View {
    var event: FullFeedEventDTO
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                if let profilePicture = event.creatorUser.profilePicture {
                    AsyncImage(url: URL(string: profilePicture)) {
                        image in
                        image
                            .ProfileImageModifier(
                                imageType: .eventParticipants)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 24, height: 24)
                    }
                    
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 24, height: 24)
                }
                Text("@\(event.creatorUser.username)")
                    .font(.onestMedium(size: 13))
                    .foregroundColor(.white)
            
                
                Spacer()
            }
            if let description = event.note {
                HStack {
                    Text(description)
                        .font(.onestRegular(size: 13))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(2)
                    Spacer()
                }
                
            }
        }
        .padding(8)
        .background(eventCardInfoCapsuleColor)
        .cornerRadius(10)
    }
}
