import SwiftUI

/// A ViewModifier that handles auth navigation destinations to eliminate code duplication
struct AuthNavigationModifier: ViewModifier {
    @ObservedObject var userAuth: UserAuthViewModel
    
    func body(content: Content) -> some View {
        content
            .navigationDestination(for: NavigationState.self) { state in
                switch state {
                case .welcome:
                    LaunchView()
                case .signIn:
                    SignInView()
                case .spawnIntro:
                    SpawnIntroView()
                case .register:
                    RegisterInputView()
                case .loginInput:
                    LoginInputView()
                case .accountNotFound:
                    AccountNotFoundView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                case .onboardingContinuation:
                    OnboardingContinuationView()
                case .userDetailsInput(let isOAuthUser):
                    UserDetailsInputView(isOAuthUser: isOAuthUser)
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                case .userOptionalDetailsInput:
                    UserOptionalDetailsInputView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                case .contactImport:
                    ContactImportView()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                case .userTermsOfService:
                    UserToS()
                        .navigationBarTitle("")
                        .navigationBarHidden(true)
                case .phoneNumberInput:
                    UserDetailsInputView(isOAuthUser: false)
                case .verificationCode:
                    VerificationCodeView(userAuthViewModel: userAuth)
                case .feedView:
                    if let loggedInSpawnUser = userAuth.spawnUser {
                        ContentView(user: loggedInSpawnUser)
                            .navigationBarTitle("")
                            .navigationBarHidden(true)
                    } else {
                        EmptyView() // This should never happen
                    }
                case .none:
                    EmptyView()
                }
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
