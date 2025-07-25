import SwiftUI

/// A ViewModifier that handles auth navigation destinations to eliminate code duplication
struct AuthNavigationModifier: ViewModifier {
    @ObservedObject var userAuth: UserAuthViewModel
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: .constant(userAuth.navigationState != .none)) {
                authNavigationDestination()
            }
    }
    
    @ViewBuilder
    private func authNavigationDestination() -> some View {
        switch userAuth.navigationState {
        case .signIn:
            SignInView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .userDetailsInput(let isOAuthUser):
            UserDetailsInputView(isOAuthUser: isOAuthUser)
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .userOptionalDetailsInput:
            UserOptionalDetailsInputView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .contactImport:
            ContactImportView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .userTermsOfService:
            UserToS()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .feedView:
            if let loggedInSpawnUser = userAuth.spawnUser {
                ContentView(user: loggedInSpawnUser)
                    .withAuthNavigationStyle()
                    .onAppear { userAuth.navigationState = .none }
            } else {
                EmptyView()
            }
            
        case .accountNotFound:
            AccountNotFoundView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .register:
            RegisterInputView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .loginInput:
            LoginInputView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .welcome:
            WelcomeView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .onboardingContinuation:
            OnboardingContinuationView()
                .withAuthNavigationStyle()
                .onAppear { userAuth.navigationState = .none }
                
        case .phoneNumberInput:
            // Add your phone number input view here when implemented
            EmptyView()
                .onAppear { userAuth.navigationState = .none }
                
        case .verificationCode:
            // Add your verification code view here when implemented
            EmptyView()
                .onAppear { userAuth.navigationState = .none }
                
        case .none:
            EmptyView()
        }
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