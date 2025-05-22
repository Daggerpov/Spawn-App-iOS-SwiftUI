//
//  DeepLinkManager.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI
import Combine

enum DeepLinkTarget: Equatable {
    case none
    case profile(userId: UUID)
    
    static func == (lhs: DeepLinkTarget, rhs: DeepLinkTarget) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case let (.profile(lhsId), .profile(rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

class DeepLinkManager: ObservableObject {
    static let shared = DeepLinkManager()
    
    @Published var currentDeepLinkTarget: DeepLinkTarget = .none
    @Published var navigateToDeepLink: Bool = false
    
    private init() {}
    
    func handleDeepLink(url: URL) {
        guard url.scheme == "spawn" else { return }
        
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let path = components?.path ?? ""
        
        if path.hasPrefix("/profile/") {
            // Extract user ID from path
            let userIdString = String(path.dropFirst("/profile/".count))
            if let userId = UUID(uuidString: userIdString) {
                // Set the deep link target
                DispatchQueue.main.async {
                    self.currentDeepLinkTarget = .profile(userId: userId)
                    self.navigateToDeepLink = true
                }
            }
        }
    }
    
    func reset() {
        currentDeepLinkTarget = .none
        navigateToDeepLink = false
    }
} 