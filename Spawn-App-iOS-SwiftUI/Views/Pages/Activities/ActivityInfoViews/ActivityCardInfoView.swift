//
//  ActivityCardInfoView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/10/25.
//


import SwiftUI

struct ActivityCardInfoView: View {
    var activity: FullFeedActivityDTO
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 8) {
                if let profilePicture = activity.creatorUser.profilePicture {
                    AsyncImage(url: URL(string: profilePicture)) {
                        image in
                        image
                            .ProfileImageModifier(
                                imageType: .activityParticipants)
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
                Text("@\(activity.creatorUser.username)")
                    .font(.onestMedium(size: 13))
                    .foregroundColor(.white)
            
                
                Spacer()
            }
            if let description = activity.note {
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
        .background(Color.white.opacity(0.13))
        .cornerRadius(10)
    }
}

@available(iOS 17.0, *)
#Preview {
    ActivityCardInfoView(activity: FullFeedActivityDTO.mockDinnerActivity)
        .padding()
        .background(Color.blue)
}
