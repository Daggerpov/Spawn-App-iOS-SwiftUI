import SwiftUI

struct ActivityBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(universalAccentColor)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@available(iOS 17, *)
#Preview {
    VStack(alignment: .leading) {
        ActivityBackButton {
            print("Back tapped")
        }
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(universalBackgroundColor)
} 