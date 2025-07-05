//
//  ActivityTypeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import SwiftUI

struct ActivityTypeCardView: View {
    var activityType: ActivityTypeDTO
    var onTap: ((ActivityType) -> Void)? = nil
    
    // Convert ActivityTypeDTO to ActivityType for selection
    private var mappedActivityType: ActivityType? {
        ActivityType.allCases.first { $0.rawValue == activityType.title }
    }
    
    var body: some View {
        Button(action: {
            if let mappedType = mappedActivityType, let onTap = onTap {
                onTap(mappedType)
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: figmaGreyGradientColors.reversed()),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                VStack(spacing: 8) {
                    Text(activityType.icon)
                        .font(.system(size: 26))
                    Text(activityType.title)
                        .font(.onestRegular(size: 13))
                        .foregroundColor(universalAccentColor)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 85, height: 113)
    }
}

#if DEBUG
struct ActivityTypeCardView_Previews: PreviewProvider {
    static var previews: some View {
        let mockActivityType = ActivityTypeDTO.mockActiveActivityType
        ActivityTypeCardView(activityType: mockActivityType)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif
