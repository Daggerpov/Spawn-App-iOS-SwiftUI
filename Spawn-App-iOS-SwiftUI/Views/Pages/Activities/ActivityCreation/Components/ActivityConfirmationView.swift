import SwiftUI

struct ActivityConfirmationView: View {
    @Binding var showShareSheet: Bool
    let onClose: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Success!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've spawned in and \"Morning Stroll\" is now live for your friends.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button(action: {
                showShareSheet = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share with your network")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button(action: onClose) {
                Text("Return to Home")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
    }
} 