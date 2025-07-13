import SwiftUI

extension Font {
    static func registerFonts() {
        // Only call this once, typically in the app startup
        registerFont(bundle: .main, fontName: "Onest-Regular", fontExtension: "ttf")
        registerFont(bundle: .main, fontName: "Onest-Medium", fontExtension: "ttf")
        registerFont(bundle: .main, fontName: "Onest-Bold", fontExtension: "ttf")
        registerFont(bundle: .main, fontName: "Onest-SemiBold", fontExtension: "ttf")
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
            if let error = error?.takeRetainedValue() {
                let errorCode = CFErrorGetCode(error)
                let errorDescription = CFErrorCopyDescription(error)
                
                // Error code 305 means the font is already registered - this is normal for app reinstalls
                if errorCode == 305 {
                    print("Font \(fontName) is already registered (this is normal for app reinstalls)")
                } else {
                    print("Error registering font \(fontName): Code \(errorCode), Description: \(errorDescription ?? "Unknown error" as CFString)")
                }
            } else {
                print("Error registering font \(fontName): Unknown error")
            }
        } else {
            print("Successfully registered font: \(fontName)")
        }
    }
    
    // Convenience methods for using Onest font with fallbacks
    static func onestRegular(size: CGFloat) -> Font {
        // First try to use the custom font, fall back to system font if it fails
        if UIFont(name: "Onest-Regular", size: size) != nil {
            return .custom("Onest-Regular", size: size)
        } else {
            print("Warning: Onest-Regular font not available, falling back to system font")
            return .system(size: size, weight: .regular)
        }
    }
    
    static func onestMedium(size: CGFloat) -> Font {
        if UIFont(name: "Onest-Medium", size: size) != nil {
            return .custom("Onest-Medium", size: size)
        } else {
            print("Warning: Onest-Medium font not available, falling back to system font")
            return .system(size: size, weight: .medium)
        }
    }
    
    static func onestSemiBold(size: CGFloat) -> Font {
        if UIFont(name: "Onest-SemiBold", size: size) != nil {
            return .custom("Onest-SemiBold", size: size)
        } else {
            print("Warning: Onest-SemiBold font not available, falling back to system font")
            return .system(size: size, weight: .semibold)
        }
    }
    
    static func onestBold(size: CGFloat) -> Font {
        if UIFont(name: "Onest-Bold", size: size) != nil {
            return .custom("Onest-Bold", size: size)
        } else {
            print("Warning: Onest-Bold font not available, falling back to system font")
            return .system(size: size, weight: .bold)
        }
    }
}
