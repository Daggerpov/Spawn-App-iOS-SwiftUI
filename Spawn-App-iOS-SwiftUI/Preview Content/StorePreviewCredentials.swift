import SwiftUI

/// A utility view to save current authentication credentials for previews
/// Add this to any view temporarily to save your credentials after login
struct StorePreviewCredentialsButton: View {
    @ObservedObject var userAuth = UserAuthViewModel.shared
    @State private var showingConfirmation = false
    
    var body: some View {
        if #available(iOS 17, *) {
            Button("Save Auth for Previews") {
                if let userId = userAuth.externalUserId, let email = userAuth.email {
                    PreviewAuthHelper.saveCredentials(email: email, userId: userId)
                    showingConfirmation = true
                }
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            .alert("Preview Credentials Saved", isPresented: $showingConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your credentials have been saved for use in previews. They will not be committed to git.")
            }
            .opacity(userAuth.isLoggedIn && userAuth.spawnUser != nil ? 1.0 : 0.5)
            .disabled(!(userAuth.isLoggedIn && userAuth.spawnUser != nil))
        } else {
            Text("Requires iOS 17")
        }
    }
}

/// Add this to .gitignore to ensure credentials aren't committed
/// Spawn-App-iOS-SwiftUI/Preview Content/preview_credentials.json 