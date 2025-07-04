import SwiftUI

struct ThemeTestView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeService = ThemeService.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Theme Test")
                .font(.largeTitle)
                .foregroundColor(universalAccentColor)
            
            VStack(spacing: 10) {
                Text("Current Theme: \(themeService.colorScheme.displayName)")
                    .font(.headline)
                    .foregroundColor(universalAccentColor)
                
                Text("System Color Scheme: \(colorScheme == .dark ? "Dark" : "Light")")
                    .font(.subheadline)
                    .foregroundColor(universalAccentColor)
            }
            
            VStack(spacing: 16) {
                // Background color test
                RoundedRectangle(cornerRadius: 10)
                    .fill(universalBackgroundColor)
                    .frame(height: 60)
                    .overlay(
                        Text("Background Color")
                            .foregroundColor(universalAccentColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(universalAccentColor, lineWidth: 1)
                    )
                
                // Accent color test
                RoundedRectangle(cornerRadius: 10)
                    .fill(universalAccentColor)
                    .frame(height: 60)
                    .overlay(
                        Text("Accent Color")
                            .foregroundColor(universalBackgroundColor)
                    )
                
                // Placeholder text color test
                RoundedRectangle(cornerRadius: 10)
                    .fill(universalPlaceHolderTextColor)
                    .frame(height: 60)
                    .overlay(
                        Text("Placeholder Text Color")
                            .foregroundColor(universalAccentColor)
                    )
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .background(universalBackgroundColor)
        .navigationTitle("Theme Test")
        .navigationBarTitleDisplayMode(.inline)
    }
}

@available(iOS 17, *)
#Preview {
    NavigationView {
        ThemeTestView()
    }
} 