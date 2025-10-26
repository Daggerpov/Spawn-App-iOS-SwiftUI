import SwiftUI

// Settings Row Component
struct SettingsRow: View {
    let icon: String
    var isSystemIcon: Bool = true
    let title: String
    var showDisclosure: Bool = false
    var externalLink: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isSystemIcon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(universalAccentColor)
                        .frame(width: 24, height: 24)
                } else {
                    Image(icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .font(.body)
                    .foregroundColor(universalAccentColor)
                
                Spacer()
                
                if showDisclosure {
                    if externalLink {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .frame(height: 44)
        }
    }
}

