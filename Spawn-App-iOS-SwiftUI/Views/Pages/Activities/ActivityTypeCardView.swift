//
//  ActivityTypeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import SwiftUI

struct ActivityTypeCardView: View {
    var activityType: ActivityTypeDTO
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(figmaGrey)
                .shadow(color: Color.black.opacity(0.07), radius: 1, x: 0, y: 1)
            VStack(spacing: 16) {
                Image(systemName: activityType.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                Text(activityType.title)
                    .font(.onestRegular(size: 20))
                    .foregroundColor(.black)
            }
        }
        .frame(width: 120, height: 170)
    }
}

#if DEBUG
struct ActivityTypeCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivityType = ActivityTypeDTO(
            id: UUID(),
            title: "Gym",
            icon: "dumbbell",
            associatedFriends: [],
            orderNum: 1
        )
        ActivityTypeCardView(activityType: mockActivityType)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
