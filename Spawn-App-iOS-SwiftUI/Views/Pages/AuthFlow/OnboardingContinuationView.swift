import SwiftUI

struct OnboardingContinuationView: View {
    @StateObject private var userAuth = UserAuthViewModel.shared
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var shouldReturnToLogin = false
    
    var body: some View {
        ZStack {
            // Background - now theme-aware
            universalBackgroundColor(from: themeService, environment: colorScheme)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                Spacer()
                
                // Welcome back text
                VStack(spacing: 20) {
                    Text("Welcome back!")
                        .font(.onestBold(size: 32))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    
                    Text("Continue where you left off?")
                        .font(.onestRegular(size: 20))
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 27) {
                    // Continue button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        userAuth.continueOnboarding()
                    }) {
                        OnboardingButtonCoreView("Continue")
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Return to Login button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                        impactGenerator.impactOccurred()
                        
                        shouldReturnToLogin = true
                    }) {
                        Text("Return to Login")
                            .font(.onestMedium(size: 17))
                            .underline()
                            .foregroundColor(figmaIndigo)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $shouldReturnToLogin) {
            SignInView()
                .onAppear {
                    // Reset auth flow when returning to login
                    userAuth.resetAuthFlow()
                }
        }
    }
}

#Preview {
    OnboardingContinuationView()
} 