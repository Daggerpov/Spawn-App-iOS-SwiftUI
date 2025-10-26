import SwiftUI

// Shared invisible balance button for layout purposes
struct InvisibleBalanceButton: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.clear)
        }
        .disabled(true)
    }
}

