import SwiftUI

struct SemiboldTextModifier: ViewModifier {
    var size: CGFloat
    
    init(size: CGFloat = 16) {
        self.size = size
    }
    
    func body(content: Content) -> some View {
        content
            .font(.onestSemiBold(size: size))
    }
}

