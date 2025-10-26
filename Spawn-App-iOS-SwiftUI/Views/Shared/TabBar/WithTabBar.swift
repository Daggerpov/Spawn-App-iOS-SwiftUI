import SwiftUI

struct WithTabBar<Content>: View where Content: View {
    @State private var selection: Tabs = .home
    @ViewBuilder var content: (Tabs) -> Content
    
    // Calculate the TabBar space needed
    private var tabBarSpacing: CGFloat {
        let buttonHeight: CGFloat = 64 // BTTN_HEIGHT from TabButtonLabelsView
        let tabBarPadding: CGFloat = 4 * 2 // padding from TabBar
        let extraSpacing: CGFloat = 20 // Additional spacing for visual separation
        return buttonHeight + tabBarPadding + extraSpacing
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // Background that extends to cover entire screen including tab bar area
                universalBackgroundColor
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    content(selection)
                        .frame(width: proxy.size.width, height: proxy.size.height - tabBarSpacing)
                    
                    // Spacer for TabBar
                    Color.clear
                        .frame(height: tabBarSpacing)
                }
                .overlay(alignment: .bottom) {
                    TabBar(selection: $selection)
                        .padding(.bottom, max(40, proxy.safeAreaInsets.bottom + 16))
                }
            }
        }
    }
}

#Preview {
    WithTabBar { selection in
        Text("Hello world")
            .foregroundStyle(selection.item.color)
    }
}

