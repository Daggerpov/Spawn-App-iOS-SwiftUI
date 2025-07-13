import SwiftUI

struct ProfileShareDrawer: View {
    let user: Nameable
    @Binding var showShareSheet: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    // State for drag gesture
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background overlay
            if showShareSheet {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showShareSheet = false
                        }
                    }
            }
            
            // Share sheet
            VStack(spacing: 16) {
                // Drag handle
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 134, height: 5)
                    .background(Color(red: 0.56, green: 0.52, blue: 0.52))
                    .cornerRadius(100)
                    .padding(.top, 12)
                
                // Title
                Text("Share Profile")
                    .font(.custom("Onest", size: 20).weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.top, 8)
                
                // Share options
                HStack(spacing: 32) {
                    // Share via button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        showShareSheet = false
                        shareViaSystem()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                    .frame(width: 64, height: 64)
                                Image("share_via_button")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                            Text("Share via")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .frame(width: 64)
                    }
                    
                    // Copy Link button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        showShareSheet = false
                        copyLink()
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                    .frame(width: 64, height: 64)
                                Image("copy_link_button")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                            Text("Copy Link")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .frame(width: 68)
                    }
                    
                    // WhatsApp button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        showShareSheet = false
                        shareViaWhatsApp()
                    }) {
                        VStack(spacing: 8) {
                            Image("whatsapp_logo_for_sharing")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                            Text("WhatsApp")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .frame(width: 72)
                    }
                    
                    // iMessage button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        showShareSheet = false
                        shareViaIMessage()
                    }) {
                        VStack(spacing: 8) {
                            Image("imessage_for_sharing")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                            Text("Message")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .frame(width: 65)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 236)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(20)
            .shadow(
                color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 32
            )
            .offset(y: showShareSheet ? 0 : UIScreen.main.bounds.height)
            .offset(y: max(0, dragOffset))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow dragging down
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        // If dragged down enough, dismiss
                        if value.translation.height > 100 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                showShareSheet = false
                                dragOffset = 0
                            }
                        } else {
                            // Snap back to position
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showShareSheet)
    }
    
    // MARK: - Share Functions
    private func shareViaSystem() {
        let profileURL = generateShareURL(for: user)
        let shareText = "Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn! \(profileURL.absoluteString)"

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
        let url = generateShareURL(for: user)
        
        // Clear the pasteboard first to avoid any contamination
        UIPasteboard.general.items = []
        
        // Set only the URL string to the pasteboard
        UIPasteboard.general.string = url.absoluteString
        
        // Provide haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // Show notification toast
        InAppNotificationManager.shared.showNotification(
            title: "Link copied to clipboard",
            message: "Profile link has been copied to your clipboard",
            type: .success
        )
    }
    
    private func shareViaWhatsApp() {
        let url = generateShareURL(for: user)
        let shareText = "Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn! \(url.absoluteString)"
        
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
        let url = generateShareURL(for: user)
        let shareText = "Check out \(FormatterService.shared.formatName(user: user))'s profile on Spawn! \(url.absoluteString)"
        
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
    
    private func generateShareURL(for user: Nameable) -> URL {
        // Use the centralized Constants for share URL generation
        return ServiceConstants.generateProfileShareURL(for: user.id)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var showShareSheet: Bool = true
    
    ProfileShareDrawer(
        user: BaseUserDTO.danielAgapov,
        showShareSheet: $showShareSheet
    )
} 