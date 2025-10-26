import SwiftUI

struct InviteContactRow: View {
    let contact: Contact
    let isInvited: Bool
    let onInvite: () -> Void
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture Placeholder
            Circle()
                .fill(Color(red: 0.50, green: 0.23, blue: 0.27).opacity(0.50))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(contact.name.prefix(1)))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4.06, y: 1.62)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(Font.custom("Onest", size: 14).weight(.semibold))
                    .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
                
                if let firstPhoneNumber = contact.phoneNumbers.first {
                    Text(firstPhoneNumber)
                        .font(Font.custom("Onest", size: 12))
                        .foregroundColor(universalPlaceHolderTextColor(from: themeService, environment: colorScheme))
                }
            }
            
            Spacer()
            
            Button(action: onInvite) {
                if isInvited {
                    Text("Invited")
                        .font(Font.custom("Onest", size: 12).weight(.medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                } else {
                    Text("Invite")
                        .font(Font.custom("Onest", size: 12).weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.42, green: 0.51, blue: 0.98))
                        .cornerRadius(12)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
    }
}

