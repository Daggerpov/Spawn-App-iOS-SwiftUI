//
//  TagButtonView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/4/24.
//

import SwiftUI

struct TagButtonView: View {
    let tag: String
    @Binding var activeTag: String
    var animation: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.easeIn) {
                activeTag = tag
            }
        }) {
            Text(tag)
                .font(.callout)
                .foregroundColor(activeTag == tag ? .white : universalAccentColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background{
                    Capsule()
                        .fill(activeTag == tag ? universalAccentColor : .white)
                        .matchedGeometryEffect(id: "ACTIVETAG_\(tag)", in: animation) // Use unique ID for each tag
                }
                
        }
        .buttonStyle(.plain)
    }
}
