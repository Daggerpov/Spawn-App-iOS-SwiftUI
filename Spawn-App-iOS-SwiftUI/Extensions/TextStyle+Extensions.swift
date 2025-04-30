import SwiftUI

// Extension to apply Onest font to all Text views
extension Text {
    func onestStyle() -> some View {
        self.font(.onestRegular(size: 16))
    }
}

// Extension to apply Onest font to all TextField views
extension TextField {
    func onestStyle() -> some View {
        self.font(.onestRegular(size: 16))
    }
}

// Extension for View to make it easier to apply Onest font
extension View {
    func onestFont(size: CGFloat = 16, weight: Font.Weight = .regular) -> some View {
        switch weight {
        case .bold:
            return self.font(.onestBold(size: size))
        case .medium:
            return self.font(.onestMedium(size: size))
        default:
            return self.font(.onestRegular(size: size))
        }
    }
}

// Theme modifier for applying Onest font to all text in a view hierarchy
struct OnestFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.font, .onestRegular(size: 16))
    }
}

extension View {
    func onestFontTheme() -> some View {
        self.modifier(OnestFontModifier())
    }
} 