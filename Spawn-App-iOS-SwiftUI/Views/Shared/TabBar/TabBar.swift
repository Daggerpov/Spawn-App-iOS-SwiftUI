import SwiftUI

struct TabBar: View {
	@Binding var selection: Tabs
	@State private var symbolTrigger: Bool = false
	@Namespace private var tabItemNameSpace
	var tutorialViewModel = TutorialViewModel.shared

	init(selection: Binding<Tabs>) {
		self._selection = selection
	}

	func changeTabTo(_ tab: Tabs) {
		// Check if navigation is restricted during tutorial
		if tutorialViewModel.tutorialState.shouldRestrictNavigation {
			// Only allow activities tab during activity type selection
			if !tutorialViewModel.canNavigateToTab(tab.toTabType) {
				// Add haptic feedback to indicate restriction
				let notificationGenerator = UINotificationFeedbackGenerator()
				notificationGenerator.notificationOccurred(.warning)
				return
			}
		}

		withAnimation(.bouncy(duration: 0.3, extraBounce: 0.15)) {
			selection = tab
		}

		symbolTrigger = true

		Task { @MainActor in
			try? await Task.sleep(for: .seconds(0.1))
			symbolTrigger = false
		}
	}

	func isTabDisabled(_ tab: Tabs) -> Bool {
		if tutorialViewModel.tutorialState.shouldRestrictNavigation {
			return !tutorialViewModel.canNavigateToTab(tab.toTabType)
		}
		return false
	}

	var body: some View {

		HStack(spacing: -8) {
			ForEach(Tabs.allCases, id: \.self) { tab in
				if #available(iOS 17.0, *) {
					Button(action: {
						changeTabTo(tab)
					}) {
						if tab == selection {
							ActiveTabLabel(tabItem: tab.item, isAnimating: $symbolTrigger)
								.matchedGeometryEffect(id: "tabItem", in: tabItemNameSpace)
								.foregroundStyle(Color(hex: colorsTabIconActive))
								.animation(.none, value: selection)
						} else {
							InActiveTabLabel(tabItem: tab.item)
								.foregroundStyle(Color(hex: colorsTabIconInactive))
								.animation(.none, value: selection)
						}
					}
					.withTabButtonStyle()
					.opacity(isTabDisabled(tab) ? 0.4 : 1.0)
					.animation(.easeInOut(duration: 0.2), value: tutorialViewModel.tutorialState)
				} else {
					// Fallback for iOS < 17
					Button(action: {
						changeTabTo(tab)
					}) {
						if tab == selection {
							ActiveTabLabel(tabItem: tab.item, isAnimating: $symbolTrigger)
								.matchedGeometryEffect(id: "tabItem", in: tabItemNameSpace)
								.foregroundColor(Color(hex: colorsTabIconActive))
								.animation(.none, value: selection)
						} else {
							InActiveTabLabel(tabItem: tab.item)
								.foregroundColor(Color(hex: colorsTabIconInactive))
								.animation(.none, value: selection)
						}
					}
					.withTabButtonStyle()
					.opacity(isTabDisabled(tab) ? 0.4 : 1.0)
					.animation(.easeInOut(duration: 0.2), value: tutorialViewModel.tutorialState)
				}
			}
		}
		.padding(4)
		.background(
			ZStack {
				RoundedRectangle(cornerRadius: 100, style: .continuous)
					.fill(.ultraThinMaterial)
					.overlay(
						RoundedRectangle(cornerRadius: 100, style: .continuous)
							.fill(
								Color(
									UIColor { traitCollection in
										switch traitCollection.userInterfaceStyle {
										case .dark:
											return UIColor(Color(hex: colorsGray800).opacity(0.8))
										default:
											return UIColor(Color(hex: colorsTabBackground).opacity(0.6))
										}
									})
							)
					)
			}
		)
		.clipShape(RoundedRectangle(cornerRadius: 100))
		.shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 5)

	}
}
