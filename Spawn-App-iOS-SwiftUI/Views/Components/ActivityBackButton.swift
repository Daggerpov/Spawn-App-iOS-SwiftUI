import SwiftUI

struct ActivityBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(universalAccentColor)
                
                Text("Back")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(universalAccentColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.clear)
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