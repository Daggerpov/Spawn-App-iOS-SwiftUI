//
//  ActivityTypeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/31/25.
//
import SwiftUI

struct ActivityTypeCardView: View {
    var activityType: ActivityTypeDTO
    var onTap: ((ActivityTypeDTO) -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation states for 3D effect
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    // Adaptive background color (solid colors instead of gradients)
    private var adaptiveBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(hex: "#2C2C2C")
        case .light:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        @unknown default:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        }
    }
    
    // Adaptive text color
    private var adaptiveTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white
        case .light:
            return Color(red: 0.07, green: 0.07, blue: 0.07)
        @unknown default:
            return Color(red: 0.07, green: 0.07, blue: 0.07)
        }
    }

    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            // Execute action with slight delay for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let onTap = onTap {
                    print("🔘 ActivityTypeCardView '\(activityType.title)' button tapped")
                    onTap(activityType)
                } else {
                    print("❌ ActivityTypeCardView '\(activityType.title)' button tapped but onTap is nil")
                }
            }
        }) {
            VStack(spacing: 4) {
                Text(activityType.icon)
                    .font(Font.custom("Onest", size: 34).weight(.bold))
                    .foregroundColor(adaptiveTextColor)
                Text(activityType.title)
                    .font(Font.custom("Onest", size: 16).weight(.semibold))
                    .foregroundColor(adaptiveTextColor)
            }
            .padding(16)
            .frame(width: 85, height: 115)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(adaptiveBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                colorScheme == .dark ? 
                                    Color.white.opacity(0.1) : 
                                    Color.clear, 
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(scale)
            .shadow(
                color: Color.black.opacity(0.15),
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
            scale = pressing ? 0.95 : 1.0
            
            // Additional haptic feedback for press down
            if pressing {
                let selectionGenerator = UISelectionFeedbackGenerator()
                selectionGenerator.selectionChanged()
            }
        }, perform: {})
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
