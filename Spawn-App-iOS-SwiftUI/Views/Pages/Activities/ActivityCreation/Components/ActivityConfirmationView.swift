import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Binding var showShareSheet: Bool
    @Environment(\.colorScheme) private var colorScheme
    let onClose: () -> Void
    let onBack: (() -> Void)?
    
    // State for drag gesture
    @State private var dragOffset: CGFloat = 0
    
    // Colors based on theme
    private var backgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.12, green: 0.12, blue: 0.12) : .white
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : Color(red: 0.11, green: 0.11, blue: 0.11)
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? Color(red: 0.82, green: 0.80, blue: 0.80) : Color(red: 0.15, green: 0.14, blue: 0.14)
    }
    
    private var buttonBackgroundColor: Color {
        colorScheme == .dark ? Color(red: 0.52, green: 0.49, blue: 0.49) : Color(red: 0.88, green: 0.85, blue: 0.85)
    }
    
    private var overlayColor: Color {
        colorScheme == .dark ? Color(red: 0, green: 0, blue: 0).opacity(0.6) : Color(red: 1, green: 1, blue: 1).opacity(0.60)
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status bar area (simplified - remove double time)
                statusBarView
                
                // Main content
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Success icon placeholder
                    ZStack {}
                        .frame(width: 144, height: 144)
                        .offset(y: -131)
                    
                    // Success message
                    VStack(spacing: 12) {
                        Text("Success!")
                            .font(.custom("Onest", size: 32))
                            .fontWeight(.semibold)
                            .foregroundColor(primaryTextColor)
                        
                        Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
                            .font(.custom("Onest", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                            .multilineTextAlignment(.center)
                    }
                    .offset(y: 17.5)
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 70) {
                        // Share with network button
                        Button(action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                            impactGenerator.impactOccurred()
                            showShareSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Text("􀈂")
                                    .font(.custom("SF Pro Display", size: 24))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Share with your network")
                                    .font(.custom("Onest", size: 20))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            .padding(EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24))
                            .background(Color(red: 0.26, green: 0.38, blue: 1))
                            .cornerRadius(100)
                        }
                        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 2)
                        .offset(x: 0.5, y: 120.5)
                        
                        // Return to home button
                        Button(action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                            onClose()
                        }) {
                            HStack(spacing: 8) {
                                Text("Return to Home")
                                    .font(.custom("Onest", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(secondaryTextColor)
                            }
                            .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                            .frame(height: 43)
                            .background(Color.clear)
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .inset(by: 1)
                                    .stroke(secondaryTextColor, lineWidth: 1)
                            )
                        }
                        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 2)
                        .offset(y: 190.5)
                    }
                    
                    Spacer()
                }
            }
            
            // Overlay when share sheet is shown
            if showShareSheet {
                overlayColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showShareSheet = false
                        }
                    }
            }
            
            // Share drawer
            if showShareSheet {
                shareDrawerOverlay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor)
        .cornerRadius(44)
        .ignoresSafeArea()
    }
    
    // MARK: - Status Bar View
    private var statusBarView: some View {
        HStack {
            // Time (single instance)
            Text("2:05")
                .font(.custom("SF Pro Text", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(primaryTextColor)
            
            Spacer()
            
            // Status indicators
            Rectangle()
                .fill(Color.black)
                .frame(width: 192, height: 20)
                .cornerRadius(30)
        }
        .padding(.horizontal, 24)
        .frame(height: 37)
        .offset(y: -444.5)
    }
    
    // MARK: - Share Drawer Overlay
    private var shareDrawerOverlay: some View {
        VStack {
            Spacer()
            
            // Share drawer
            VStack(spacing: 0) {
                // Drag handle
                Rectangle()
                    .fill(Color(red: 0.56, green: 0.52, blue: 0.52))
                    .frame(width: 50, height: 4)
                    .cornerRadius(100)
                    .offset(y: -104)
                
                // Share title
                Text("Share this Spawn")
                    .font(.custom("Onest", size: 20))
                    .fontWeight(.semibold)
                    .lineSpacing(24)
                    .foregroundColor(primaryTextColor)
                    .frame(width: 375)
                    .offset(x: 2.5, y: -65)
                
                // Share options
                HStack(spacing: 32) {
                    // Share via
                    shareOption(
                        systemIcon: "􀈂",
                        title: "Share via",
                        action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                            showShareSheet = false
                            shareViaSystem()
                        }
                    )
                    
                    // Copy link
                    shareOption(
                        systemIcon: "􀉣",
                        title: "Copy Link",
                        action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                            showShareSheet = false
                            copyLink()
                        }
                    )
                    
                    // WhatsApp
                    shareOption(
                        title: "WhatsApp",
                        backgroundColor: Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50),
                        action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                            showShareSheet = false
                            shareViaWhatsApp()
                        }
                    )
                    
                    // iMessage
                    shareOption(
                        title: "iMessage",
                        action: {
                            // Add haptic feedback
                            let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                            impactGenerator.impactOccurred()
                            showShareSheet = false
                            shareViaIMessage()
                        }
                    )
                }
                .frame(width: 368)
                .offset(x: -1, y: 17.5)
                
                // Bottom handle
                Rectangle()
                    .fill(Color(red: 0.56, green: 0.52, blue: 0.52))
                    .frame(width: 134, height: 5)
                    .cornerRadius(100)
                    .offset(y: 107.5)
            }
            .frame(width: 428, height: 236)
            .background(backgroundColor)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.10), radius: 32)
            .offset(y: max(0, dragOffset))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow dragging down
                        if value.translation.y > 0 {
                            dragOffset = value.translation.y
                        }
                    }
                    .onEnded { value in
                        // If dragged down enough, dismiss
                        if value.translation.y > 100 {
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
    
    // MARK: - Helper Views
    private func shareOption(
        systemIcon: String? = nil,
        title: String,
        backgroundColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon container
                ZStack {
                    if let systemIcon = systemIcon {
                        Text(systemIcon)
                            .font(.custom("SF Pro Display", size: 24))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    } else {
                        // Empty for WhatsApp and iMessage (would need actual icons)
                        ZStack {}
                    }
                }
                .frame(width: 64, height: 64)
                .background(backgroundColor ?? buttonBackgroundColor)
                .cornerRadius(systemIcon == "􀉣" ? 94.12 : (title == "WhatsApp" ? 88.89 : (title == "iMessage" ? 98.46 : 100)))
                .padding(systemIcon == "􀉣" ? 11.29 : (title == "WhatsApp" ? 10.67 : 12))
                
                // Title
                Text(title)
                    .font(.custom("SF Pro Display", size: 16))
                    .foregroundColor(secondaryTextColor)
            }
            .frame(width: title == "Copy Link" ? 68 : (title == "WhatsApp" ? 72 : (title == "iMessage" ? 65 : 64)))
        }
    }
    
    // MARK: - Share Functions
    private func shareViaSystem() {
        let activity = viewModel.activity
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
        let activity = viewModel.activity
        let url = generateShareURL(for: activity)
        UIPasteboard.general.string = url.absoluteString
        
        // Provide haptic feedback
        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
        impactGenerator.impactOccurred()
        
        // TODO: Add toast notification for "Link copied to clipboard"
    }
    
    private func shareViaWhatsApp() {
        let activity = viewModel.activity
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
        let activity = viewModel.activity
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
    
    private var activityTitle: String {
        return viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Activity")
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var showShareSheet: Bool = false
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityConfirmationView(
        showShareSheet: $showShareSheet,
        onClose: {
            print("Close tapped")
        },
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(appCache)
} 