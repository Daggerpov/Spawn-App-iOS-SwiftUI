import SwiftUI
import GoogleSignIn
import Foundation

/// Property wrapper that enables authenticated previews
/// This wrapper automatically handles authentication in preview environments
@available(iOS 17, *)
@propertyWrapper
struct Previewable<Value> {
    var wrappedValue: Value
    
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
        
        // Initialize authentication when the property wrapper is created
        // This ensures authentication happens before preview rendering
        Task {
            await PreviewAuthHelper.shared.authenticateIfNeeded()
        }
    }
}

/// Helper class that handles authentication for previews
@available(iOS 17, *)
class PreviewAuthHelper {
    static let shared = PreviewAuthHelper()
    private var hasAttemptedAuth = false
    
    private init() {}
    
    func authenticateIfNeeded() async {
        // Only attempt authentication once
        guard !hasAttemptedAuth else { return }
        hasAttemptedAuth = true
        
        // If already logged in with a spawn user, no need to authenticate again
        if UserAuthViewModel.shared.isLoggedIn && UserAuthViewModel.shared.spawnUser != nil {
            return
        }
        
        // Use environment variables for credentials if available
        if let credentials = loadCredentials() {
            print("🔐 Preview: Using stored credentials for authentication")
            await signInWithCredentials(credentials)
        }
    }
    
    private func loadCredentials() -> AuthCredentials? {
        // Check for credentials file first (gitignored)
        if let fileURL = getCredentialsFileURL(), 
           let data = try? Data(contentsOf: fileURL),
           let credentials = try? JSONDecoder().decode(AuthCredentials.self, from: data) {
            return credentials
        }
        
        // Fallback to environment variables if file doesn't exist
        guard let email = ProcessInfo.processInfo.environment["SPAWN_AUTH_EMAIL"],
              let userId = ProcessInfo.processInfo.environment["SPAWN_AUTH_USER_ID"] else {
            return nil
        }
        
        return AuthCredentials(email: email, userId: userId)
    }
    
    private func getCredentialsFileURL() -> URL? {
        let fileManager = FileManager.default
        
        // Get the document directory for the app
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentDirectory.appendingPathComponent("preview_credentials.json")
    }
    
    private func signInWithCredentials(_ credentials: AuthCredentials) async {
        // Set the required properties in UserAuthViewModel
        await MainActor.run {
            let viewModel = UserAuthViewModel.shared
            viewModel.email = credentials.email
            viewModel.externalUserId = credentials.userId
            viewModel.isLoggedIn = true
            viewModel.authProvider = .google
            
            // Force fetch user with these credentials
            Task {
                await viewModel.spawnFetchUserIfAlreadyExists()
            }
        }
    }
}

/// Structure to hold authentication credentials
struct AuthCredentials: Codable {
    let email: String
    let userId: String
}

// Helper method to create a credentials file from values
@available(iOS 17, *)
extension PreviewAuthHelper {
    static func saveCredentials(email: String, userId: String) {
        let credentials = AuthCredentials(email: email, userId: userId)
        guard let fileURL = shared.getCredentialsFileURL() else { return }
        
        do {
            let data = try JSONEncoder().encode(credentials)
            try data.write(to: fileURL)
            print("✅ Preview credentials saved to: \(fileURL.path)")
        } catch {
            print("❌ Failed to save preview credentials: \(error)")
        }
    }
}

// Extension to help with environment object injection in previews
@available(iOS 17, *)
extension View {
    func withPreviewEnvironment() -> some View {
        Task {
            await PreviewAuthHelper.shared.authenticateIfNeeded()
        }
        
        return self
            .environmentObject(UserAuthViewModel.shared)
            .environmentObject(AppCache.shared)
    }
} 