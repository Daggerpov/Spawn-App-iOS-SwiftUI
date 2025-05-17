//
//  PreviewAuthEnvironment.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-05-24.
//

import SwiftUI

/// Environment modifier that provides authentication for SwiftUI previews
struct PreviewAuthEnvironment: ViewModifier {
    let authViewModel: UserAuthViewModel
    
    init() {
        // Use a special preview API service implementation
        let previewAPIService = PreviewAPIService()
        
        // Create an instance of UserAuthViewModel with our preview API service
        self.authViewModel = UserAuthViewModel.previewInstance(apiService: previewAPIService)
        
        // Store this instance for global access in preview contexts
        #if DEBUG
        UserAuthViewModel.previewInstance = self.authViewModel
        
        // Set environment variable to identify preview context
        setenv("XCODE_RUNNING_FOR_PREVIEWS", "1", 1)
        #endif
    }
    
    func body(content: Content) -> some View {
        content
            .environmentObject(authViewModel)
    }
}

/// A mock API service specifically for previews that doesn't make real network requests
class PreviewAPIService: IAPIService {
    var errorMessage: String?
    var errorStatusCode: Int?
    
    // Token values that will be used in preview environment
    let previewAccessToken = "preview_access_token_for_testing"
    let previewRefreshToken = "preview_refresh_token_for_testing"
    
    init() {
        // Ensure tokens are saved to keychain on initialization
        setupPreviewTokens()
    }
    
    // Setup keychain with preview tokens
    private func setupPreviewTokens() {
        if let accessTokenData = previewAccessToken.data(using: .utf8),
           let refreshTokenData = previewRefreshToken.data(using: .utf8) {
            _ = KeychainService.shared.save(key: "accessToken", data: accessTokenData)
            _ = KeychainService.shared.save(key: "refreshToken", data: refreshTokenData)
            print("[PREVIEW] Saved preview tokens to keychain")
        }
    }
    
    // Special handling for auth endpoints
    private func handleAuthEndpoint(url: URL) -> (Bool, Data?) {
        let urlString = url.absoluteString
        
        // Check if this is an auth-related URL
        if urlString.contains("/auth/sign-in") || urlString.contains("/auth/make-user") {
            // Create mock HTTP response with auth headers
            let mockResponse = HTTPURLResponse(
                url: url,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Authorization": "Bearer \(previewAccessToken)",
                    "x-refresh-token": previewRefreshToken
                ]
            )
            
            // Return true to indicate this is an auth endpoint that was handled
            return (true, nil)
        }
        
        return (false, nil)
    }
    
    // Implement all required methods from IAPIService
    func fetchData<T>(from url: URL, parameters: [String : String]?) async throws -> T where T : Decodable {
        let (isAuthEndpoint, responseData) = handleAuthEndpoint(url: url)
        
        // Create mock data based on the requested type
        return createMockData(for: T.self)
    }
    
    func sendData<T, U>(_ object: T, to url: URL, parameters: [String : String]?) async throws -> U? where T : Encodable, U : Decodable {
        let (isAuthEndpoint, responseData) = handleAuthEndpoint(url: url)
        
        return createMockData(for: U.self)
    }
    
    func updateData<T, U>(_ object: T, to url: URL, parameters: [String : String]?) async throws -> U where T : Encodable, U : Decodable {
        return createMockData(for: U.self)
    }
    
    func patchData<T, U>(from url: URL, with object: T) async throws -> U where T : Encodable, U : Decodable {
        return createMockData(for: U.self)
    }
    
    func deleteData<T>(from url: URL, parameters: [String : String]?, object: T?) async throws where T : Encodable {
        // Do nothing for preview
    }
    
    func updateProfilePicture(_ imageData: Data, userId: UUID) async throws -> BaseUserDTO {
        return BaseUserDTO.danielAgapov
    }
    
    func sendMultipartFormData(_ formData: [String : Any], to url: URL) async throws -> Data {
        return Data()
    }
    
    func validateCache(_ cachedItems: [String : Date]) async throws -> [String : CacheValidationResponse] {
        return [:]
    }
    
    // Helper to create mock data for various types
    private func createMockData<T>(for type: T.Type) -> T {
        // Handle specific types we know about
        if type == BaseUserDTO.self {
            return BaseUserDTO.danielAgapov as! T
        }
        
        // For arrays, return empty array
        if let arrayType = type as? [Any].Type {
            return [] as! T
        }
        
        // For optional types, return nil
        if let optionalType = type as? OptionalProtocol.Type {
            return optionalType.nilValue as! T
        }
        
        // For other types, attempt to initialize with empty initializer or fall back to fatalError
        // This is a limitation of previews and won't affect runtime
        fatalError("Unable to create mock data for type \(type)")
    }
}

// Extension for UserAuthViewModel to create a preview instance
extension UserAuthViewModel {
    static func previewInstance(apiService: IAPIService) -> UserAuthViewModel {
        let previewViewModel = UserAuthViewModel(apiService: apiService)
        
        // Set up the view model with mock data
        previewViewModel.isLoggedIn = true
        previewViewModel.spawnUser = BaseUserDTO.danielAgapov
        previewViewModel.authProvider = .email
        previewViewModel.externalUserId = "preview_external_user_id"
        
        return previewViewModel
    }
}

// Extension to simplify applying the preview auth environment
extension View {
    func withPreviewAuth() -> some View {
        self.modifier(PreviewAuthEnvironment())
    }
}

// Preview-specific extension for SwiftUI's PreviewProvider
@available(iOS 17.0, *)
extension PreviewProvider {
    static var previewContent: some View {
        EmptyView().withPreviewAuth()
    }
} 