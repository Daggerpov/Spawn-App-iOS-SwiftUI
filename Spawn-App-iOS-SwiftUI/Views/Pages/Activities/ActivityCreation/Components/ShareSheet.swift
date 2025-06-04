import SwiftUI

struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.vertical, 8)
            
            Text("Share this Spawn")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(universalAccentColor)
                .padding(.top, 16)
                .padding(.bottom, 32)
            
            // Share options grid
            HStack(spacing: 40) {
                ShareOption(
                    icon: "square.and.arrow.up", 
                    label: "Share via",
                    backgroundColor: Color.gray.opacity(0.15),
                    iconColor: universalAccentColor,
                    action: {
                        shareViaSystem()
                    }
                )
                
                ShareOption(
                    icon: "link", 
                    label: "Copy Link",
                    backgroundColor: Color.gray.opacity(0.15),
                    iconColor: universalAccentColor,
                    action: {
                        copyLink()
                    }
                )
                
                ShareOption(
                    imageName: "whatsapp",
                    label: "WhatsApp",
                    backgroundColor: Color.green,
                    iconColor: .white,
                    action: {
                        shareViaWhatsApp()
                    }
                )
                
                ShareOption(
                    imageName: "imessage",
                    label: "iMessage",
                    backgroundColor: Color.green,
                    iconColor: .white,
                    action: {
                        shareViaIMessage()
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }
    
    private func shareViaSystem() {
        let activity = ActivityCreationViewModel.shared.activity
        let activityURL = generateShareURL(for: activity)
        
		let shareText = "Join me for \"\(activity.title ?? "an activity")\"! \(activityURL.absoluteString)"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            
            var topController = window.rootViewController
            while let presentedViewController = topController?.presentedViewController {
                topController = presentedViewController
            }
            
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topController?.view
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            topController?.present(activityVC, animated: true)
        }
    }
    
    private func copyLink() {
        let activity = ActivityCreationViewModel.shared.activity
        let url = generateShareURL(for: activity)
        UIPasteboard.general.string = url.absoluteString
        
        // Provide haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Show a toast or feedback that the link was copied
        // You might want to add a toast notification here
    }
    
    private func shareViaWhatsApp() {
        let activity = ActivityCreationViewModel.shared.activity
        let url = generateShareURL(for: activity)
        let shareText = "Join me for \"\(activity.title ?? "an activity")\"! \(url.absoluteString)"
        
        if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)") {
            
            if UIApplication.shared.canOpenURL(whatsappURL) {
                UIApplication.shared.open(whatsappURL)
            } else {
                // WhatsApp not installed, fallback to share sheet
                shareViaSystem()
            }
        }
    }
    
    private func shareViaIMessage() {
        let activity = ActivityCreationViewModel.shared.activity
        let url = generateShareURL(for: activity)
        let shareText = "Join me for \"\(activity.title ?? "an activity")\"! \(url.absoluteString)"
        
        if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let smsURL = URL(string: "sms:&body=\(encodedText)") {
            
            if UIApplication.shared.canOpenURL(smsURL) {
                UIApplication.shared.open(smsURL)
            } else {
                // Messages not available, fallback to share sheet
                shareViaSystem()
            }
        }
    }
    
    private func generateShareURL(for activity: ActivityCreationDTO) -> URL {
        // Use the centralized Constants for share URL generation
        return ServiceConstants.generateActivityShareURL(for: activity.id)
    }
}

struct ShareOption: View {
    let icon: String?
    let imageName: String?
    let label: String
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void
    
    init(
        icon: String? = nil,
        imageName: String? = nil,
        label: String,
        backgroundColor: Color,
        iconColor: Color,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.imageName = imageName
        self.label = label
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 64, height: 64)
                    .overlay {
                        if let systemIcon = icon {
                            Image(systemName: systemIcon)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(iconColor)
                        } else if let imageName = imageName {
                            Image(imageName)
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(iconColor)
                        }
                    }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(universalAccentColor)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17.0, *)
#Preview {
    ShareSheet()
}
