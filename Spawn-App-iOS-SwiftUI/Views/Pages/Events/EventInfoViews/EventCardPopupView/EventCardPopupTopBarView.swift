//
//  EventCardPopupTopBarView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/19/25.
//

import SwiftUI

struct EventCardPopupTopBarView: View {
    
    var body: some View {
        VStack {
            Capsule()
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            HStack(alignment: .center) {
                Button(action: {/* Expand/Collapse */}) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Button(action: {/* Menu */}) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
