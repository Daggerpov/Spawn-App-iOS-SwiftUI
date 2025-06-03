import SwiftUI

struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ActivityCreationViewModel
    
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
                .foregroundColor(.primary)
                .padding(.top, 16)
                .padding(.bottom, 32)
            
            // Share options grid
            HStack(spacing: 40) {
                ShareOption(
                    icon: "square.and.arrow.up", 
                    label: "Share via",
                    backgroundColor: Color.gray.opacity(0.15),
                    iconColor: .primary,
                    action: {
                        shareViaSystem()
                    }
                )
                
                ShareOption(
                    icon: "link", 
                    label: "Copy Link",
                    backgroundColor: Color.gray.opacity(0.15),
                    iconColor: .primary,
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
        .background(Color(.systemBackground))
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
    }
    
    private func shareViaSystem() {
        let activity = viewModel.activity
        let activityURL = generateShareURL(for: activity)
        let activityVC = UIActivityViewController(
            activityItems: [activityURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = rootVC.view
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func copyLink() {
        let activity = viewModel.activity
        let url = generateShareURL(for: activity)
        UIPasteboard.general.string = url.absoluteString
        // Show a toast or feedback that the link was copied
    }
    
    private func shareViaWhatsApp() {
        let activity = viewModel.activity
        let url = generateShareURL(for: activity)
        let whatsappURL = URL(string: "whatsapp://send?text=\(url.absoluteString)")!
        
        if UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL)
        }
    }
    
    private func shareViaIMessage() {
        let activity = viewModel.activity
        let url = generateShareURL(for: activity)
        let smsURL = URL(string: "sms:&body=\(url.absoluteString)")!
        
        if UIApplication.shared.canOpenURL(smsURL) {
            UIApplication.shared.open(smsURL)
        }
    }
    
    private func generateShareURL(for activity: ActivityCreationDTO) -> URL {
        // Replace this with your actual deep link URL generation
        return URL(string: "https://spawn.app/activity/\(activity.id.uuidString)")!
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
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(iconColor)
                        }
                    }
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
} 