//
//  FriendTagToggleView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Raul.Reyes on 18/02/25.
//

import SwiftUI

struct FriendTagToggleView: View {
    @Binding var selectedTab: FriendTagToggle
    @Namespace private var animationNamespace
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([FriendTagToggle.friends, FriendTagToggle.tags], id: \.self) { tab in
                Text(tab == .friends ? "friends" : "tags")
                    .foregroundColor(selectedTab == tab ? universalAccentColor : .white)
                    .frame(width: 65, height: 33)
                    .padding(.horizontal, 10)
                    .font(.system(size: 16, weight: .semibold))
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(universalBackgroundColor)
                                    .matchedGeometryEffect(id: "pickerSelection", in: animationNamespace)
                                    .frame(width: 80, height: 30)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.5, blendDuration: 0.1)) {
                            selectedTab = tab
                        }
                    }
            }
        }
        .padding(5)
        .clipShape(Capsule())

        .padding(.horizontal)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(universalAccentColor)
                    .frame(width: 180, height: 42)
                
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 165, height: 33)
            }
        )
    }
}


@available(iOS 17.0, *)
#Preview {
    @State @Previewable var selectedTab: FriendTagToggle = .friends
    
    FriendTagToggleView(selectedTab: $selectedTab)
        .padding()
}
