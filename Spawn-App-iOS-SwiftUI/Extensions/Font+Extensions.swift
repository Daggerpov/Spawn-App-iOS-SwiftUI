import SwiftUI

extension Font {
    // Convenience methods for using Onest font
    static func onestRegular(size: CGFloat) -> Font {
        return .custom("Onest-Regular", size: size)
    }
    
    static func onestMedium(size: CGFloat) -> Font {
        return .custom("Onest-Medium", size: size)
    }
    
    static func onestSemiBold(size: CGFloat) -> Font {
        return .custom("Onest-SemiBold", size: size)
    }
    
    static func onestBold(size: CGFloat) -> Font {
        return .custom("Onest-Bold", size: size)
    }
}
