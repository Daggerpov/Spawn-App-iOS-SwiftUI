import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Binding var showShareSheet: Bool
    @Environment(\.colorScheme) private var colorScheme
    let onClose: () -> Void
    let onBack: (() -> Void)?
    
    // State for drag gesture
    @State private var dragOffset: CGFloat = 0
    
    private var activityTitle: String {
        return viewModel.activity.title?.isEmpty == false ? viewModel.activity.title! : (viewModel.selectedActivityType?.title ?? "Activity")
    }
    
    var body: some View {
        ZStack() {
            VStack(spacing: 0) {
                // Header with back button and title
                headerView
                
                // Main content
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image("success-check")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                        
                        Text("Success!")
                            .font(Font.custom("Onest", size: 32).weight(.semibold))
                            .foregroundColor(.white)
                        Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 80)
                    
                    Spacer()
                    
                    // Share with your network button
                    Button(action: {
                        // Add haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        showShareSheet = true
                    }) {
                        Image("share_with_network_button")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 280)
                    }
                    .padding(.bottom, 16)
                    
                    // Return to Home button
                    Button(action: {
                        // Add haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        onClose()
                    }) {
                        HStack(spacing: 8) {
                            Text("Return to Home")
                                .font(Font.custom("Onest", size: 16).weight(.medium))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                        .frame(height: 43)
                        .cornerRadius(100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .inset(by: 1)
                                .stroke(Color(red: 0.82, green: 0.80, blue: 0.80), lineWidth: 1)
                        )
                    }
                    .shadow(
                        color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2
                    )
                    .padding(.bottom, 120)
                }
            }
            
            // Share drawer overlay
            if showShareSheet {
                shareDrawerOverlay
            }
        }
        .background(Color(red: 0.12, green: 0.12, blue: 0.12))
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Back button
            if let onBack = onBack {
                ActivityBackButton {
                    onBack()
                }
                .padding(.leading, 24)
            }
            
            Spacer()
            
            // Title
            Text("Confirm")
                .font(.onestSemiBold(size: 20))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer for balance
            if onBack != nil {
                Color.clear
                    .frame(width: 44, height: 44)
                    .padding(.trailing, 24)
            }
        }
        .padding(.top, 50)
        .padding(.bottom, 12)
    }
    
    // MARK: - Share Drawer Overlay
    private var shareDrawerOverlay: some View {
        ZStack() {
            // Background overlay
            Rectangle()
                .foregroundColor(.clear)
                .frame(width: 428, height: 926)
                .background(Color(red: 0, green: 0, blue: 0).opacity(0.60))
                .offset(x: 0, y: 0)
                .onTapGesture {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showShareSheet = false
                    }
                }
            
            // Share menu content
            ZStack() {
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: 50, height: 4)
                    .background(Color(red: 0.56, green: 0.52, blue: 0.52))
                    .cornerRadius(100)
                    .offset(x: 0, y: -104)
                HStack(spacing: 32) {
                    Text("Share this Spawn")
                        .font(Font.custom("Onest", size: 20).weight(.semibold))
                        .lineSpacing(24)
                        .foregroundColor(.white)
                }
                .frame(width: 375)
                .offset(x: 2.50, y: -65)
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 134, height: 5)
                        .background(Color(red: 0.56, green: 0.52, blue: 0.52))
                        .cornerRadius(100)
                }
                .padding(EdgeInsets(top: 8, leading: 147, bottom: 8, trailing: 147))
                .frame(width: 428)
                .offset(x: 0, y: 107.50)
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
                            ZStack {
                                Circle()
                                    .fill(Color(red: 0.52, green: 0.49, blue: 0.49))
                                    .frame(width: 64, height: 64)
                                Image("imessage")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.white)
                            }
                            Text("Message")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(Color(red: 0.82, green: 0.80, blue: 0.80))
                        }
                        .frame(width: 65)
                    }
                }
                .frame(width: 368)
                .offset(x: -1, y: 17.50)
            }
            .frame(width: 428, height: 236)
            .background(Color(red: 0.12, green: 0.12, blue: 0.12))
            .cornerRadius(20)
            .shadow(
                color: Color(red: 0, green: 0, blue: 0, opacity: 0.10), radius: 32
            )
            .offset(x: 0, y: 250)
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
