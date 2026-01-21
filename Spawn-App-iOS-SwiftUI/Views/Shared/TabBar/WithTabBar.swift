import SwiftUI

struct WithTabBar<Content>: View where Content: View {
	@State private var selection: Tabs = .home
	@ViewBuilder var content: (Tabs) -> Content

	// Calculate the TabBar space needed
	private var tabBarSpacing: CGFloat {
		let buttonHeight: CGFloat = 64  // BTTN_HEIGHT from TabButtonLabelsView
		let tabBarPadding: CGFloat = 4 * 2  // padding from TabBar
		let extraSpacing: CGFloat = 20  // Additional spacing for visual separation
		return buttonHeight + tabBarPadding + extraSpacing
	}

	var body: some View {
		GeometryReader { proxy in
			let safeWidth =
				proxy.size.width.isNaN || proxy.size.width <= 0 ? UIScreen.main.bounds.width : proxy.size.width
			let safeHeight =
				proxy.size.height.isNaN || proxy.size.height <= 0 ? UIScreen.main.bounds.height : proxy.size.height
			let safeBottomInset = proxy.safeAreaInsets.bottom.isNaN ? 0 : proxy.safeAreaInsets.bottom

			ZStack {
				// Background that extends to cover entire screen including tab bar area
				universalBackgroundColor
					.ignoresSafeArea(.all)

				VStack(spacing: 0) {
					content(selection)
						.frame(width: safeWidth, height: safeHeight - tabBarSpacing)

					// Spacer for TabBar
					Color.clear
						.frame(height: tabBarSpacing)
				}
				.overlay(alignment: .bottom) {
					TabBar(selection: $selection)
						.padding(.bottom, max(40, safeBottomInset + 16))
				}
			}
		}
		.ignoresSafeArea(.keyboard)  // Prevent keyboard from affecting the entire layout including tab bar
	}
}

#Preview {
	WithTabBar { selection in
		Text("Hello world")
			.foregroundStyle(selection.item.color)
	}
}
