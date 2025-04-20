//
//  EventCreationButton.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationButtonView: View {
    @Binding var showEventCreationDrawer: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
            .frame(width: 100, height: 45)
            .foregroundColor(universalBackgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: universalRectangleCornerRadius)
                    .stroke(universalAccentColor, lineWidth: 2)
            )
            .overlay(
                Button(action: {
                    showEventCreationDrawer = true
                }) {
                    HStack {
                        Spacer()
                        Image(systemName: "plus")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                            .shadow(radius: 20)
                            .foregroundColor(universalAccentColor)
                            .font(.system(size: 30, weight: .bold))
                        Spacer()
                    }
                }
            )
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    @Previewable @State var state: Bool = false
    EventCreationButtonView(showEventCreationDrawer: $state).environmentObject(
        appCache)
}
