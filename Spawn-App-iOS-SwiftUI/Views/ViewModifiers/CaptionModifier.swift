import SwiftUI

struct CaptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.onestRegular(size: 14))
    }
}

