import SwiftUI

struct UserSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigating: Bool = false
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            // Onboarding graphic
            Image("onboarding_activity_cal")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .padding(.bottom, 40)
            
            // Title and subtitle at the bottom
            VStack(spacing: 16) {
                Text("Let's Get You Set Up")
                    .font(heading1)
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    .multilineTextAlignment(.center)
                Text("It only takes a minute. We'll\npersonalize your experience.")
                    .font(.onestRegular(size: 18))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 60)
            
            Spacer()
            
            // Start button
            Button(action: {
                // Haptic feedback
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
                
                // Execute action with slight delay for animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isNavigating = true
                }
            }) {
                OnboardingButtonCoreView("Start") { figmaIndigo }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.bottom, 40)
        }
        .background(universalBackgroundColor(from: themeService, environment: colorScheme))
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isNavigating, destination: {UserOptionalDetailsInputView()})
    }
}

#Preview {
    UserSetupView()
} 
