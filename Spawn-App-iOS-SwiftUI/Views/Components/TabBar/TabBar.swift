//
//  TabBarContentView.swift
//  swiftystuff
//
//  Created by Abdulrahim Illo on 04/05/2024.
//

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
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

// New version that accepts external binding
struct WithTabBarBinding<Content>: View where Content: View {
    @Binding var selection: Tabs
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
                        .padding(.bottom, 16)
                }
            }
        }
    }
}

struct TabBar: View {
    @Binding var selection: Tabs
    @State private var symbolTrigger: Bool = false
    @Namespace private var tabItemNameSpace
    @StateObject private var tutorialViewModel = TutorialViewModel.shared

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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
                        // Fallback on earlier versions
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
                                    Color(UIColor { traitCollection in
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

#Preview {
    WithTabBar { selection in
        Text("Hello world")
            .foregroundStyle(selection.item.color)
    }
}
