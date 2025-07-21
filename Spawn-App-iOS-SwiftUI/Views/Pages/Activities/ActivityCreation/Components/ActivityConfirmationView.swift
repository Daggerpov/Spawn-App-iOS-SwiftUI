import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @ObservedObject var themeService = ThemeService.shared
    @Binding var showShareSheet: Bool
    @Environment(\.colorScheme) private var colorScheme
    let onClose: () -> Void
    let onBack: (() -> Void)?
    
    // State for drag gesture
    @State private var dragOffset: CGFloat = 0
    
    // MARK: - Adaptive Colors
    private var adaptiveBackgroundColor: Color {
        universalBackgroundColor(from: themeService, environment: colorScheme)
    }
    
    private var adaptiveTextColor: Color {
        universalAccentColor(from: themeService, environment: colorScheme)
    }
    
    private var adaptiveSecondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var adaptiveButtonBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var adaptiveReturnButtonTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var adaptiveOverlayColor: Color {
        switch colorScheme {
        case .dark:
            return Color.black.opacity(0.60)
        case .light:
            return Color.black.opacity(0.40)
        @unknown default:
            return Color.black.opacity(0.40)
        }
    }
    
    private var adaptiveShareDrawerBackground: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .light:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        @unknown default:
            return Color(red: 0.95, green: 0.93, blue: 0.93)
        }
    }
    
    private var adaptiveShareDrawerHandleColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.56, green: 0.52, blue: 0.52)
        case .light:
            return Color(red: 0.70, green: 0.67, blue: 0.67)
        @unknown default:
            return Color(red: 0.70, green: 0.67, blue: 0.67)
        }
    }
    
    private var adaptiveShareButtonBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        case .light:
            return Color(red: 0.85, green: 0.82, blue: 0.82)
        @unknown default:
            return Color(red: 0.85, green: 0.82, blue: 0.82)
        }
    }
    
    private var adaptiveShareButtonTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.82, green: 0.80, blue: 0.80)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
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
                            .font(Font.custom("Onest", size: 48).weight(.semibold))
                            .foregroundColor(adaptiveTextColor)
                        Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
                            .font(Font.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(adaptiveSecondaryTextColor)
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
                                .foregroundColor(adaptiveReturnButtonTextColor)
                        }
                        .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                        .frame(height: 43)
                        .cornerRadius(100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .inset(by: 1)
                                .stroke(adaptiveButtonBorderColor, lineWidth: 1)
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
        .background(adaptiveBackgroundColor)
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
                .foregroundColor(adaptiveTextColor)
            
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
                .background(adaptiveOverlayColor)
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
                    .background(adaptiveShareDrawerHandleColor)
                    .cornerRadius(100)
                    .offset(x: 0, y: -104)
                HStack(spacing: 32) {
                    Text("Share this Spawn")
                        .font(Font.custom("Onest", size: 20).weight(.semibold))
                        .lineSpacing(24)
                        .foregroundColor(adaptiveTextColor)
                }
                .frame(width: 375)
                .offset(x: 2.50, y: -65)
                VStack(alignment: .leading, spacing: 10) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 134, height: 5)
                        .background(adaptiveShareDrawerHandleColor)
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
                                    .fill(adaptiveShareButtonBackgroundColor)
                                    .frame(width: 64, height: 64)
                                Image("share_via_button")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                            Text("Share via")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(adaptiveShareButtonTextColor)
                        }
                        .frame(width: 64)
                    }
                    
                    // Copy Link button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        shareViaLink()
                        // Delay dismissing the sheet to allow notification to show
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showShareSheet = false
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(adaptiveShareButtonBackgroundColor)
                                    .frame(width: 64, height: 64)
                                Image("copy_link_button")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                            }
                            Text("Copy Link")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(adaptiveShareButtonTextColor)
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
                                .foregroundColor(adaptiveShareButtonTextColor)
                        }
                        .frame(width: 72)
                    }
                    
                    // iMessage button
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        showShareSheet = false
                        shareViaSMS()
                    }) {
                        VStack(spacing: 8) {
							Image("imessage_for_sharing")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: 64, height: 64)
                            Text("Message")
                                .font(Font.custom("SF Pro Display", size: 14))
                                .foregroundColor(adaptiveShareButtonTextColor)
                        }
                        .frame(width: 65)
                    }
                }
                .frame(width: 368)
                .offset(x: -1, y: 17.50)
            }
            .frame(width: 428, height: 236)
            .background(adaptiveShareDrawerBackground)
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
        generateShareURL(for: activity) { activityURL in
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
                    popover.sourceRect = topController?.view.bounds ?? CGRect.zero
                }
                
                topController?.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    private func shareViaLink() {
        let activity = viewModel.activity
        generateShareURL(for: activity) { url in
            UIPasteboard.general.string = url.absoluteString
            
            // Show success notification
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                InAppNotificationManager.shared.showNotification(
                    title: "Link copied to clipboard",
                    message: "Activity link has been copied to your clipboard",
                    type: .success,
                    duration: 5.0
                )
            }
        }
    }
    
    private func shareViaWhatsApp() {
        let activity = viewModel.activity
        generateShareURL(for: activity) { url in
            let shareText = "Join me for \"\(activity.title ?? "an activity")\"! \(url.absoluteString)"
            
            if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let whatsappURL = URL(string: "whatsapp://send?text=\(encodedText)") {
                
                if UIApplication.shared.canOpenURL(whatsappURL) {
                    UIApplication.shared.open(whatsappURL)
                } else {
                    print("WhatsApp not installed or URL scheme not supported")
                }
            }
        }
    }
    
    private func shareViaSMS() {
        let activity = viewModel.activity
        generateShareURL(for: activity) { url in
            let shareText = "Join me for \"\(activity.title ?? "an activity")\"! \(url.absoluteString)"
            
            if let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
               let smsURL = URL(string: "sms:?body=\(encodedText)") {
                
                if UIApplication.shared.canOpenURL(smsURL) {
                    UIApplication.shared.open(smsURL)
                } else {
                    print("SMS not available")
                }
            }
        }
    }
    
    private func generateShareURL(for activity: ActivityCreationDTO, completion: @escaping (URL) -> Void) {
        // Use the centralized Constants for share URL generation with share codes
        ServiceConstants.generateActivityShareCodeURL(for: activity.id) { url in
            completion(url ?? ServiceConstants.generateActivityShareURL(for: activity.id))
        }
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
