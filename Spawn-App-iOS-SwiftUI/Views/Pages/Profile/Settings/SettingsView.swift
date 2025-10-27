import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var userAuth = UserAuthViewModel.shared
    
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
                    
                    // Privacy & Safety
                    SettingsSection(title: "Privacy & Safety") {
                        NavigationLink(destination: BlockedUsersView()) {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.xmark")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("Blocked Users")
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
                        
                        NavigationLink(destination: MyReportsView()) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("My Reports")
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
                        
                        SettingsRow(icon: "star", title: "Rate Spawn", showDisclosure: false) {
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

// MARK: - Supporting Components
// All supporting view structs have been moved to separate files in SettingsView/
// - SettingsSection.swift
// - SettingsRow.swift

@available(iOS 17, *)
#Preview {
    SettingsView()
} 
