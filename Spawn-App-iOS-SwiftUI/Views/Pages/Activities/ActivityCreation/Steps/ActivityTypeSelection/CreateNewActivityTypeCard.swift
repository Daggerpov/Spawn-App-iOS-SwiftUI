import SwiftUI

struct CreateNewActivityTypeCard: View {
    let onCreateNew: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.24, green: 0.23, blue: 0.23)
        case .light:
            return Color.white
        @unknown default:
            return Color.white
        }
    }
    
    private var adaptiveTextColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        @unknown default:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        }
    }
    
    private var adaptiveBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.5)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    var body: some View {
        Button(action: onCreateNew) {
            VStack(spacing: 8) {
                Image("create_new_activity_icon_activity_creation")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color(hex: colorsGreen700))
                
                Text("Create New Activity")
                    .font(Font.custom("Onest", size: 12).weight(.medium))
                    .foregroundColor(adaptiveTextColor)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(width: 116, height: 116)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(adaptiveBorderColor, lineWidth: 0.50, dashLengthValue: 5, dashSpacingValue: 5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Extensions
extension RoundedRectangle {
    func stroke(_ content: Color, lineWidth: CGFloat, dashLengthValue: CGFloat, dashSpacingValue: CGFloat) -> some View {
        self.stroke(content, style: StrokeStyle(lineWidth: lineWidth, dash: [dashLengthValue, dashSpacingValue]))
    }
}

