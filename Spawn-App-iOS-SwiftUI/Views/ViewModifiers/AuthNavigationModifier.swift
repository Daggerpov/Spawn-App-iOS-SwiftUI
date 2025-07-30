import SwiftUI

/// A ViewModifier that handles auth navigation destinations to eliminate code duplication
struct AuthNavigationModifier: ViewModifier {
    @ObservedObject var userAuth: UserAuthViewModel
    
    func body(content: Content) -> some View {
        content
            // Navigation destinations are handled by the parent NavigationStack in LaunchView
            // No need to duplicate them here
    }
}

/// Helper ViewModifier for consistent auth navigation styling
private struct AuthNavigationStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitle("")
            .navigationBarHidden(true)
    }
}

// MARK: - View Extensions

extension View {
    /// Applies auth navigation handling to any view
    func withAuthNavigation(_ userAuth: UserAuthViewModel) -> some View {
        self.modifier(AuthNavigationModifier(userAuth: userAuth))
    }
    
    /// Applies consistent auth navigation styling
    fileprivate func withAuthNavigationStyle() -> some View {
        self.modifier(AuthNavigationStyleModifier())
    }
} 