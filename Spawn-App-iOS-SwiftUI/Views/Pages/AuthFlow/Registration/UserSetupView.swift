import SwiftUI

struct UserSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isNavigating: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            Spacer()
            // Title and subtitle at the bottom
            VStack(spacing: 16) {
                Text("Let’s Get You Set Up")
                    .font(heading1)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Text("It only takes a minute. We’ll\npersonalize your experience.")
                    .font(.onestRegular(size: 18))
                    .foregroundColor(.black)
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
        .background(Color.white)
        .ignoresSafeArea()
    
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $isNavigating, destination: {UserOptionalDetailsInputView()})
    }
}

#Preview {
    UserSetupView()
} 
