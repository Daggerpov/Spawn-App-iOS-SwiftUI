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
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.vertical, 16)
            
            // Share options grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ShareOption(icon: "square.and.arrow.up", label: "Share via", action: {
                    shareViaSystem()
                })
                
                ShareOption(icon: "link", label: "Copy Link", action: {
                    copyLink()
                })
                
                ShareOption(
                    imageName: "whatsapp",
                    label: "WhatsApp",
                    tintColor: Color.green,
                    action: {
                        shareViaWhatsApp()
                    }
                )
                
                ShareOption(
                    imageName: "imessage",
                    label: "iMessage",
                    tintColor: Color.green,
                    action: {
                        shareViaIMessage()
                    }
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            Spacer()
        }
        .background(universalBackgroundColor)
        .presentationDetents([.height(200)])
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
    let tintColor: Color?
    let action: () -> Void
    
    init(
        icon: String? = nil,
        imageName: String? = nil,
        label: String,
        tintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.imageName = imageName
        self.label = label
        self.tintColor = tintColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let systemIcon = icon {
                            Image(systemName: systemIcon)
                                .foregroundColor(.primary)
                        } else if let imageName = imageName {
                            Image(imageName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(tintColor ?? .primary)
                        }
                    }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
} 