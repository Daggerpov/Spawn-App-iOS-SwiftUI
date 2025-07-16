import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var userAuth = UserAuthViewModel.shared
    @State private var showDeleteConfirmation = false
    @State private var showLogoutConfirmation = false
    
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
                
                Text("Account Settings")
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
                    // Account Information section
                    SettingsSection(title: "Account Information") {
                        // User Email with Provider Icon
                        HStack {
                            // Provider Icon
                            Group {
                                switch userAuth.authProvider {
                                case .google:
                                    Image("google_logo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 18, height: 18)
                                case .apple:
                                    Image(systemName: "applelogo")
                                        .font(.system(size: 18))
                                        .foregroundColor(universalAccentColor)
                                case .email, .none:
                                    Image(systemName: "envelope.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(universalAccentColor)
                                }
                            }
                            .frame(width: 24, height: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userAuth.spawnUser?.email ?? userAuth.email ?? "No email")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                
                                Text(providerDisplayName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        .frame(height: 44)
                    }
                    
                    // Authentication section
                    SettingsSection(title: "Authentication") {
                        // Only show change password option for email-based accounts
                        if userAuth.authProvider == .email {
                            NavigationLink(destination: ChangePasswordView()) {
                                HStack {
                                    Image(systemName: "lock.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(universalAccentColor)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Change Password")
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
                    }
                    
                    // Account Actions section
                    SettingsSection(title: "Account Actions") {
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 18))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 24, height: 24)
                                
                                Text("Log Out")
                                    .font(.body)
                                    .foregroundColor(universalAccentColor)
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .frame(height: 44)
                        }
                    }
                    
                    // Permanent Actions section
                    SettingsSection(title: "Permanent Actions") {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                    .font(.system(size: 18))
                                    .foregroundColor(.red)
                                    .frame(width: 24, height: 24)
                                
                                Text("Delete Account")
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Spacer()
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
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await userAuth.deleteAccount()
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Log Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) {
                userAuth.signOut()
            }
        } message: {
            Text("Are you sure you want to log out of your account?")
        }
    }
    
    // Helper computed property for provider display name
    private var providerDisplayName: String {
        switch userAuth.authProvider {
        case .google:
            return "Google Account"
        case .apple:
            return "Apple ID"
        case .email:
            return "Email Account"
        case .none:
            return "Unknown Provider"
        }
    }
}

@available(iOS 17, *)
#Preview {
    AccountSettingsView()
} 
