import SwiftUI

// MARK: - Text Modifiers for Onest Font
struct HeadlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestBold(size: 20))
    }
}

struct SubheadlineModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestMedium(size: 16))
    }
}

struct BodyModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestRegular(size: 16))
    }
}

struct CaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestRegular(size: 14))
    }
}

struct SmallTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestRegular(size: 12))
    }
}

// MARK: - View Extensions
extension View {
    func onestHeadline() -> some View {
        self.modifier(HeadlineModifier())
    }
    
    func onestSubheadline() -> some View {
        self.modifier(SubheadlineModifier())
    }
    
    func onestBody() -> some View {
        self.modifier(BodyModifier())
    }
    
    func onestCaption() -> some View {
        self.modifier(CaptionModifier())
    }
    
    func onestSmallText() -> some View {
        self.modifier(SmallTextModifier())
    }
} 