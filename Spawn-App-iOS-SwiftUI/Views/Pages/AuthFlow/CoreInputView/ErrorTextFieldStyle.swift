import SwiftUI

// Error-aware text field component with red borders
struct ErrorTextFieldStyle: TextFieldStyle {
    let hasError: Bool
    @ObservedObject var themeService = ThemeService.shared
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(getInputFieldBackgroundColor())
            .cornerRadius(16)
            .font(.onestRegular(size: 16))
            .foregroundColor(universalAccentColor(from: themeService, environment: colorScheme))
            .accentColor(universalAccentColor(from: themeService, environment: colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 1)
                    .stroke(hasError ? Color(red: 0.77, green: 0.19, blue: 0.19) : Color.clear, lineWidth: 1)
            )
    }
    
    private func getInputFieldBackgroundColor() -> Color {
        // Use a theme-aware background color for input fields
        let currentScheme = themeService.colorScheme
        switch currentScheme {
        case .light:
            return Color(hex: colorsGrayInput)
        case .dark:
            return Color(hex: "#2C2C2C")
        case .system:
            return colorScheme == .dark ? Color(hex: "#2C2C2C") : Color(hex: colorsGrayInput)
        }
    }
}

