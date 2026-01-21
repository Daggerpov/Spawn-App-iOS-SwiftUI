import SwiftUI

// New version that accepts external binding
struct WithTabBarBinding<Content>: View where Content: View {
	@Binding var selection: Tabs
	@ViewBuilder var content: (Tabs) -> Content
	var activityCreationViewModel = ActivityCreationViewModel.shared

	// Calculate the TabBar space needed
	private var tabBarSpacing: CGFloat {
		let buttonHeight: CGFloat = 64  // BTTN_HEIGHT from TabButtonLabelsView
		let tabBarPadding: CGFloat = 4 * 2  // padding from TabBar
		let extraSpacing: CGFloat = 20  // Additional spacing for visual separation
		return buttonHeight + tabBarPadding + extraSpacing
	}

	// Check if we should hide the tab bar (for location selection screen)
	private var shouldHideTabBar: Bool {
		// Hide tab bar only when on activities tab and specifically on location selection step
		return selection == .activities && activityCreationViewModel.isOnLocationSelectionStep
	}

	// Calculate adaptive bottom padding based on screen size and safe area
	private func adaptiveBottomPadding(for proxy: GeometryProxy) -> CGFloat {
		let screenHeight = proxy.size.height.isNaN ? UIScreen.main.bounds.height : proxy.size.height
		let safeAreaBottom = proxy.safeAreaInsets.bottom.isNaN ? 0 : proxy.safeAreaInsets.bottom

		// iPhone 8 and similar devices (smaller screens, typically no safe area)
		if screenHeight <= 667 || safeAreaBottom < 10 {
			return max(100, safeAreaBottom + 20)
		}
		// iPhone X and newer (larger screens with significant safe area)
		else {
			return max(80, safeAreaBottom + 20)
		}
	}

	var body: some View {
		GeometryReader { proxy in
			let safeWidth =
				proxy.size.width.isNaN || proxy.size.width <= 0 ? UIScreen.main.bounds.width : proxy.size.width
			let safeHeight =
				proxy.size.height.isNaN || proxy.size.height <= 0 ? UIScreen.main.bounds.height : proxy.size.height

			ZStack {
				// Background that extends to cover entire screen including tab bar area
				universalBackgroundColor
					.ignoresSafeArea(.all)

				// Main content area - fills entire screen
				content(selection)
					.frame(width: safeWidth, height: safeHeight)
					.padding(.bottom, shouldHideTabBar ? 0 : tabBarSpacing)  // Conditional padding based on tab bar visibility
					.if(selection != .activities) { view in
						view.ignoresSafeArea(.keyboard, edges: .bottom)  // Prevent keyboard from pushing content up for non-activities tabs
					}

				// Tab bar positioned absolutely at bottom - conditionally visible
				if !shouldHideTabBar {
					VStack {
						Spacer()
						TabBar(selection: $selection)
							.padding(.bottom, adaptiveBottomPadding(for: proxy))
					}
				}
			}
		}
		.ignoresSafeArea(.keyboard)  // Prevent keyboard from affecting the entire layout including tab bar
	}
}
