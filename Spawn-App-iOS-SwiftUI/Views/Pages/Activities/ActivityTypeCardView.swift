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
        VStack(spacing: 4) {
            Text(activityType.icon)
                .font(Font.custom("Onest", size: 34).weight(.bold))
                .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
            Text(activityType.title)
                .font(Font.custom("Onest", size: 14).weight(.semibold))
                .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                .lineLimit(2)
                .truncationMode(.tail)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .frame(
            minWidth: 85,
            maxWidth: .infinity,
            minHeight: 115,
        )
        .background(Color(red: 0.95, green: 0.93, blue: 0.93))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.95, green: 0.93, blue: 0.93), lineWidth: 1) // "border"
                .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: -2) // dark shadow top
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.white.opacity(0.7), radius: 4, x: 0, y: 4) // light shadow bottom
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
        .animation(.easeInOut(duration: 0.15), value: scale)
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .onTapGesture {
            // Haptic feedback
            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
            impactGenerator.impactOccurred()
            
            if let onTap = onTap {
                print("🔘 ActivityTypeCardView '\(activityType.title)' button tapped")
                onTap(activityType)
            } else {
                print("❌ ActivityTypeCardView '\(activityType.title)' button tapped but onTap is nil")
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        scale = 0.95
                        
                        // Haptic feedback for press down
                        let selectionGenerator = UISelectionFeedbackGenerator()
                        selectionGenerator.selectionChanged()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    scale = 1.0
                }
        )
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
