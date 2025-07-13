import SwiftUI

struct UserSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigating: Bool = false
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
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
                isNavigating = true
            }) {
                OnboardingButtonCoreView("Start") { figmaIndigo }
            }
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
