import Foundation
import SwiftUI

struct TabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
    }
}

extension View {
    func withTabButtonStyle() -> some View {
        buttonStyle(TabButtonStyle())
    }
}
