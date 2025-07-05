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
    @Environment(\.colorScheme) private var colorScheme
    
    // Convert ActivityTypeDTO to ActivityType for selection
    private var mappedActivityType: ActivityType? {
        ActivityType.allCases.first { $0.rawValue == activityType.title }
    }
    
    // Adaptive background gradient for dark mode
    private var adaptiveBackgroundGradient: LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#2C2C2C"), 
                    Color(hex: "#3A3A3A"), 
                    Color(hex: "#404040")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: figmaGreyGradientColors.reversed()),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        @unknown default:
            return LinearGradient(
                gradient: Gradient(colors: figmaGreyGradientColors.reversed()),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Adaptive text color
    private var adaptiveTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white
        case .light:
            return universalAccentColor
        @unknown default:
            return universalAccentColor
        }
    }
    
    var body: some View {
        Button(action: {
            if let mappedType = mappedActivityType, let onTap = onTap {
                onTap(mappedType)
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(adaptiveBackgroundGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .dark ? 
                                    Color.white.opacity(0.1) : 
                                    Color.clear, 
                                lineWidth: 1
                            )
                    )
                
                VStack(spacing: 8) {
                    Text(activityType.icon)
                        .font(.system(size: 26))
                    Text(activityType.title)
                        .font(.onestRegular(size: 13))
                        .foregroundColor(adaptiveTextColor)
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
        VStack {
            ActivityTypeCardView(activityType: mockActivityType)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.light)
            
            ActivityTypeCardView(activityType: mockActivityType)
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
