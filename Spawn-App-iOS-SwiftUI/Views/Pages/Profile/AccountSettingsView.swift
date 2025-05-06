import SwiftUI

struct AccountSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject var userAuth = UserAuthViewModel.shared
    @State private var showDeleteConfirmation = false
    
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
                    .foregroundColor(.black)
                
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
                    // Authentication section
                    SettingsSection(title: "Authentication") {
                        // Only show change password option for email-based accounts
                        if userAuth.authProvider == .email {
                            NavigationLink(destination: ChangePasswordView()) {
                                HStack {
                                    Image(systemName: "lock.circle")
                                        .font(.system(size: 18))
                                        .foregroundColor(.black)
                                        .frame(width: 24, height: 24)
                                    
                                    Text("Change Password")
                                        .font(.body)
                                        .foregroundColor(.black)
                                    
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
                    
                    // Permanent Actions section
                    SettingsSection(title: "Permanent Actions") {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Text("Delete Account")
                                    .font(.body)
                                    .foregroundColor(.red)
                                
                                Spacer()
                                
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
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
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Account"),
                message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    Task {
                        await userAuth.deleteAccount()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}


@available(iOS 17, *)
#Preview {
    AccountSettingsView()
} 
