import SwiftUI

extension Font {
    static func registerFonts() {
        // Only call this once, typically in the app startup
        registerFont(bundle: .main, fontName: "Onest-Regular", fontExtension: "ttf")
        registerFont(bundle: .main, fontName: "Onest-Medium", fontExtension: "ttf")
        registerFont(bundle: .main, fontName: "Onest-Bold", fontExtension: "ttf")
    }
    
    private static func registerFont(bundle: Bundle, fontName: String, fontExtension: String) {
        guard let fontURL = bundle.url(forResource: fontName, withExtension: fontExtension),
              let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let font = CGFont(fontDataProvider) else {
            print("Could not load font \(fontName).\(fontExtension)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            print("Error registering font: \(error.debugDescription)")
        }
    }
    
    // Convenience methods for using Onest font
    static func onestRegular(size: CGFloat) -> Font {
        return .custom("Onest-Regular", size: size)
    }
    
    static func onestMedium(size: CGFloat) -> Font {
        return .custom("Onest-Medium", size: size)
    }
    
    static func onestBold(size: CGFloat) -> Font {
        return .custom("Onest-Bold", size: size)
    }
}
