import SwiftUI

// Container view that provides the background and layout for ActivityTypeFriendMenuView
struct MenuContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 8) {
            content
                .background(universalBackgroundColor)
                .cornerRadius(12, corners: [.topLeft, .topRight])
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(universalBackgroundColor)
    }
}

