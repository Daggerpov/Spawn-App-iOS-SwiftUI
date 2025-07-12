import SwiftUI

struct InAppNotificationView: View {
    let title: String
    let message: String
    let notificationType: NotificationType
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile circle/icon
            Circle()
                .fill(profileIconColor.opacity(0.5))
                .frame(width: 36, height: 36)
                .shadow(
                    color: Color.black.opacity(0.25),
                    radius: 3.22,
                    y: 1.29
                )
            
            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("Onest", size: 11).weight(.medium))
                    .foregroundColor(titleColor)
                
                Text(message)
                    .font(.custom("Onest", size: 16).weight(.bold))
                    .foregroundColor(messageColor)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.25),
            radius: 8,
            y: 2
        )
        .onTapGesture {
            onDismiss()
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        onDismiss()
                    }
                }
        )
    }
    
    // MARK: - Color Helpers
    
    private var backgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.24, green: 0.23, blue: 0.23)
        case .light:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        @unknown default:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        }
    }
    
    private var titleColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.60)
        case .light:
            return Color.black.opacity(0.60)
        @unknown default:
            return Color.black.opacity(0.60)
        }
    }
    
    private var messageColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.80)
        case .light:
            return Color.black.opacity(0.80)
        @unknown default:
            return Color.black.opacity(0.80)
        }
    }
    
    private var profileIconColor: Color {
        switch notificationType {
        case .friendRequest:
            return Color(red: 0.33, green: 0.42, blue: 0.93) // Blue
        case .activityInvite:
            return Color(red: 1, green: 0.45, blue: 0.44) // Coral
        case .activityUpdate:
            return Color(red: 0.50, green: 0.23, blue: 0.27) // Maroon
        case .chat:
            return Color(red: 0.35, green: 0.93, blue: 0.88) // Teal
        case .welcome:
            return Color(red: 0.87, green: 0.61, blue: 1) // Purple
        case .error:
            return Color(red: 0.93, green: 0.26, blue: 0.26) // Red
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        InAppNotificationView(
            title: "New Activity Update",
            message: "Chill has been updated by Dhrishty",
            notificationType: .activityUpdate,
            onDismiss: {}
        )
        .preferredColorScheme(.light)
        
        InAppNotificationView(
            title: "Friend Request",
            message: "John wants to be your friend",
            notificationType: .friendRequest,
            onDismiss: {}
        )
        .preferredColorScheme(.dark)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
} 