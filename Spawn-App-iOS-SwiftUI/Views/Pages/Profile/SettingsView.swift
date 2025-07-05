import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var userAuth = UserAuthViewModel.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(universalAccentColor)
                        .font(.title3)
                }
                
                Spacer()
                
                Text("Settings & Preferences")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                // Empty view for balance
                Color.clear.frame(width: 24, height: 24)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 16)
            
            // Settings sections
            ScrollView {
                VStack(spacing: 24) {
                    // Account Settings
                    SettingsSection(title: "Account Settings") {
                        NavigationLink(destination: AccountSettingsView()) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("Account")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                    }
                    
                    // Appearance
                    SettingsSection(title: "Appearance") {
                        NavigationLink(destination: AppearanceSettingsView()) {
                            HStack {
                                Image(systemName: "paintpalette")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("Color Scheme")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                        
                        #if DEBUG
                        // Debug options can be added here
                        #endif
                    }
                    
                    // Notifications
                    SettingsSection(title: "Notifications") {
                        NavigationLink(destination: NotificationSettingsView()) {
                            HStack {
                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("Push Notifications")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                    }
                    
                    // Contact Us
                    SettingsSection(title: "Contact Us") {
                        if let userId = userAuth.spawnUser?.id, let email = userAuth.spawnUser?.email {
                            NavigationLink(destination: FeedbackView(userId: userId, email: email)) {
                                HStack {
                                    Image(systemName: "message")
                                        .font(.system(size: 18))
                                        .foregroundColor(universalAccentColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Send us feedback")
                                        .font(.body)
                                        .foregroundColor(universalAccentColor)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                }
                                .padding(.horizontal)
                                .frame(height: 44)
                            }
                        } else {
                            SettingsRow(icon: "message", title: "Send us feedback", showDisclosure: true) {
                                // Fallback if user data not available
                            }
                        }
                        
                        SettingsRow(icon: "star", title: "Rate Spawn", showDisclosure: true) {
                            // Navigate to rate app
                        }
                    }
                    
                    // Socials
                    SettingsSection(title: "Socials") {
                        SettingsRow(icon: "instagram", isSystemIcon: false, title: "Instagram", showDisclosure: true, externalLink: true) {
                            if let url = URL(string: "https://instagram.com/spawnapp") {
                                UIApplication.shared.open(url)
                            }
                        }
                    }
                    
                    // Authentication
                    SettingsSection(title: "Authentication") {
                        Button(action: {
                            userAuth.signOut()
                        }) {
                            HStack {
                                Text("Log Out")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(universalAccentColor)
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(universalBackgroundColor)
        .navigationBarHidden(true)
        .alert(item: $userAuth.activeAlert) { alertType in
            switch alertType {
            case .deleteConfirmation:
                return Alert(
                    title: Text("Delete Account"),
                    message: Text(
                        "Are you sure you want to delete your account? This action cannot be undone."
                    ),
                    primaryButton: .destructive(Text("Delete")) {
                        Task {
                            await userAuth.deleteAccount()
                        }
                    },
                    secondaryButton: .cancel()
                )
            case .deleteSuccess:
                return Alert(
                    title: Text("Account Deleted"),
                    message: Text(
                        "Your account has been successfully deleted."
                    ),
                    dismissButton: .default(Text("OK")) {
                        userAuth.signOut()
                    }
                )
            case .deleteError:
                return Alert(
                    title: Text("Error"),
                    message: Text(
                        "Failed to delete your account. Please try again later."
                    ),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            VStack(spacing: 1) {
                content
            }
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    var isSystemIcon: Bool = true
    let title: String
    var showDisclosure: Bool = false
    var externalLink: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(universalAccentColor)
                        .frame(width: 24, height: 24)
                } else {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                if showDisclosure {
                    if externalLink {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 44)
        }
    }
}

@available(iOS 17, *)
#Preview {
    SettingsView()
} 
