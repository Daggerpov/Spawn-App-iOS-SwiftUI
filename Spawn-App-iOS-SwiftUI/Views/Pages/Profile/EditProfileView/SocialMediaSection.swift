import SwiftUI

// MARK: - Social Media Section
struct SocialMediaSection: View {
    @Binding var whatsappLink: String
    @Binding var instagramLink: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Media")
                .font(.headline)
                .foregroundColor(universalAccentColor)
                .padding(.bottom, 4)
            
            // Instagram
            SocialMediaField(
                icon: "instagram",
                placeholder: "username (without @)",
                text: $instagramLink
            )
            
            // WhatsApp
            SocialMediaField(
                icon: "whatsapp",
                placeholder: "+1 234 567 8901",
                text: $whatsappLink,
                keyboardType: .phonePad
            )
        }
        .padding(.horizontal)
    }
}

