import SwiftUI

struct ActivityConfirmationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Binding var showShareSheet: Bool
    let onClose: () -> Void
    let onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Status bar area
                statusBarView
                
                // Main content
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Success icon placeholder
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 144, height: 144)
                        .overlay(
                            // You can add your success icon here
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.green)
                        )
                    
                    // Success message
                    VStack(spacing: 12) {
                        Text("Success!")
                            .font(.custom("Onest", size: 32))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        
                        Text("You've spawned in and \"\(activityTitle)\" is now live for your friends.")
                            .font(.custom("Onest", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 0.52, green: 0.49, blue: 0.49))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Share with network button
                        Button(action: {
                            showShareSheet = true
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
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
                        
                        // Return to home button
                        Button(action: onClose) {
                            HStack(spacing: 8) {
                                Text("Return to Home")
                                    .font(.custom("Onest", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
                            }
                            .padding(EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24))
                            .frame(height: 43)
                            .background(Color.clear)
                            .cornerRadius(100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 100)
                                    .stroke(Color(red: 0.15, green: 0.14, blue: 0.14), lineWidth: 1)
                            )
                        }
                        .shadow(color: Color.black.opacity(0.25), radius: 8, y: 2)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 20)
            }
            
            // Share drawer overlay
            if showShareSheet {
                shareDrawerOverlay
            }
        }
        .background(Color.white)
        .cornerRadius(44)
        .ignoresSafeArea()
    }
    
    // MARK: - Status Bar View
    private var statusBarView: some View {
        HStack {
            // Time
            Text("2:05")
                .font(.custom("SF Pro Text", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
            
            Spacer()
            
            // Status indicators placeholder
            HStack(spacing: 4) {
                // Signal, wifi, battery indicators would go here
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 192, height: 20)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(height: 37)
    }
    
    // MARK: - Share Drawer Overlay
    private var shareDrawerOverlay: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    showShareSheet = false
                }
            
            VStack {
                Spacer()
                
                // Share drawer
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color(red: 0.56, green: 0.52, blue: 0.52))
                        .frame(width: 50, height: 4)
                        .padding(.top, 12)
                    
                    // Share title
                    Text("Share this Spawn")
                        .font(.custom("Onest", size: 20))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                        .padding(.top, 24)
                    
                    // Share options
                    HStack(spacing: 32) {
                        // Share via
                        shareOption(
                            icon: "square.and.arrow.up",
                            title: "Share via",
                            action: {
                                showShareSheet = false
                                // Handle share via action
                            }
                        )
                        
                        // Copy link
                        shareOption(
                            icon: "doc.on.doc",
                            title: "Copy Link",
                            action: {
                                showShareSheet = false
                                // Handle copy link action
                            }
                        )
                        
                        // WhatsApp
                        shareOption(
                            imageName: "whatsapp",
                            title: "WhatsApp",
                            backgroundColor: Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50),
                            action: {
                                showShareSheet = false
                                // Handle WhatsApp share
                            }
                        )
                        
                        // iMessage
                        shareOption(
                            imageName: "imessage",
                            title: "iMessage",
                            action: {
                                showShareSheet = false
                                // Handle iMessage share
                            }
                        )
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 24)
                    
                    // Bottom handle
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color(red: 0.56, green: 0.52, blue: 0.52))
                        .frame(width: 134, height: 5)
                        .padding(.top, 40)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.10), radius: 32)
            }
        }
    }
    
    // MARK: - Helper Views
    private func shareOption(
        icon: String? = nil,
        imageName: String? = nil,
        title: String,
        backgroundColor: Color = Color(red: 0.88, green: 0.85, blue: 0.85),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Icon container
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 64, height: 64)
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 22))
                            .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    } else if let imageName = imageName {
                        Image(imageName)
                            .resizable()
                            .frame(width: 32, height: 32)
                    }
                }
                
                // Title
                Text(title)
                    .font(.custom("SF Pro Display", size: 16))
                    .foregroundColor(Color(red: 0.15, green: 0.14, blue: 0.14))
            }
        }
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