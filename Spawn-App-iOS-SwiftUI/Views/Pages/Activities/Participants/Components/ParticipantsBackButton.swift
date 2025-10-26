import SwiftUI

// Shared back button component
struct ParticipantsBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

