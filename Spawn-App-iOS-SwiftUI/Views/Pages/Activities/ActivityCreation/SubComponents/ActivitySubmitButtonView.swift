//
//  EventSubmitButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Lee on 2025-04-19.
//

import SwiftUI

struct EventSubmitButtonView: View {
    var backgroundColor: Color
    init(backgroundColor: Color) {
        self.backgroundColor = backgroundColor
    }
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundColor(.white)
            Text("Spawn")
                .font(
                    Font.custom("Poppins", size: 16).weight(.bold)
                )
        }
        .frame(maxWidth: .infinity)
        .kerning(1)
        .multilineTextAlignment(.center)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15).fill(backgroundColor)
        )
        .foregroundColor(.white)
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    EventSubmitButtonView(backgroundColor: universalSecondaryColor).environmentObject(appCache)
}
