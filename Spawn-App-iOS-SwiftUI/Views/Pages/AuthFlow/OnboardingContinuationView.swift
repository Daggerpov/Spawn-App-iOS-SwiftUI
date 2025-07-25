import SwiftUI

struct OnboardingContinuationView: View {
    @StateObject private var userAuth = UserAuthViewModel.shared
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    // Add state to prevent multiple button taps
    @State private var isProcessing: Bool = false
    
    var body: some View {
        ZStack {
            // Status Bar
            HStack(alignment: .top, spacing: 32) {
                HStack(alignment: .bottom, spacing: 10) {
                    Text("9:41")
                        .font(Font.custom("SF Pro Text", size: 20).weight(.semibold))
                        .lineSpacing(20)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                .padding(EdgeInsets(top: 1, leading: 0, bottom: 0, trailing: 0))
                .frame(width: 77.14)
                .cornerRadius(24)
                
                HStack(alignment: .top, spacing: 0) {
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(width: 192)
                        .background(universalAccentColor(from: themeService, environment: colorScheme))
                        .cornerRadius(30)
                }
                
                HStack(alignment: .bottom, spacing: 4.95) {
                    // Battery and signal indicators would go here
                }
                .frame(height: 37)
            }
            .padding(EdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24))
            .frame(width: 428, height: 37)
            .offset(x: 0, y: -444.50)
            
            // Logo
            VStack(spacing: 30) {
                Image("logo_no_text")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
            }
            .offset(x: 0, y: -150)
            
            // Main content text
            VStack(spacing: 20) {
                Text("Welcome back!")
                    .font(Font.custom("Onest", size: 32).weight(.bold))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                
                Text("Continue where you left off?")
                    .font(Font.custom("Onest", size: 20))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            }
            .frame(width: 364)
            .offset(x: 0, y: 6.50)
            
            // Action buttons
            VStack(spacing: 27) {
                Button(action: {
                    // Prevent multiple taps
                    guard !isProcessing else { return }
                    
                    isProcessing = true
                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                    impactGenerator.impactOccurred()
                    
                    // Add a small delay to prevent rapid taps
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        userAuth.continueOnboarding()
                        
                        // Reset processing state after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isProcessing = false
                        }
                    }
                }) {
                    OnboardingButtonCoreView("Continue")
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
                
                Button(action: {
                    // Prevent multiple taps
                    guard !isProcessing else { return }
                    
                    isProcessing = true
                    let impactGenerator = UIImpactFeedbackGenerator(style: .light)
                    impactGenerator.impactOccurred()
                    
                    // Add a small delay to prevent rapid taps
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        userAuth.navigateTo(.signIn)
                        
                        // Reset processing state after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isProcessing = false
                        }
                    }
                }) {
                    Text("Return to Login")
                        .font(Font.custom("Onest", size: 17).weight(.medium))
                        .underline()
                        .foregroundColor(Color(red: 0.33, green: 0.42, blue: 0.93))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isProcessing)
            }
            .padding(.horizontal, 22)
            .offset(x: 0, y: 124)
        }
        .frame(width: 428, height: 926)
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .cornerRadius(44)
        .navigationBarHidden(true)
        .withAuthNavigation(userAuth)
    }
}

#Preview {
    OnboardingContinuationView()
} 