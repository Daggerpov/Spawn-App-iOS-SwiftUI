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

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                content(selection)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .overlay(alignment: .bottom) {
                TabBar(selection: $selection)
                    .padding(0)
            }
        }
    }
}

struct TabBar: View {
    @Binding var selection: Tabs
    @State private var symbolTrigger: Bool = false
    @Namespace private var tabItemNameSpace

    func changeTabTo(_ tab: Tabs) {
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0.15)) {
            selection = tab
        }
        
        symbolTrigger = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            symbolTrigger = false
        }
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
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
            .padding(4)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 100, style: .continuous)
                                        .fill(
                                            .shadow(.inner(color: .white.opacity(0.75) ,radius: 16, x:0, y: 0))
                                            .shadow(.inner(color: .white, radius: 2, x: 0, y: 2))
                                        )
                                        .foregroundColor(Color(hex: colorsTabBackground).opacity(0.6))
                }
                .background(.ultraThinMaterial) // Material layer
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
