//
//  EventCardPopupLocationRowView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/20/25.
//

import SwiftUI

struct EventCardPopupLocationRowView: View {
    var event: FullFeedEventDTO
    @ObservedObject var viewModel: EventInfoViewModel
    
    init(event: FullFeedEventDTO) {
        self.event = event
        viewModel = EventInfoViewModel(event: event, eventInfoType: .location)
    }
    
    var body: some View {
        HStack {
            EventLocationView(event: event)
            Spacer()
            Button(action: {/* View on Map */}) {
                HStack {
                    MapIcon()
                    Text("View on Map")
                }
                .font(.onestSemiBold(size: 14))
                .foregroundColor(figmaSoftBlue)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 14)
    }
}

struct MapIcon: View {
    var body: some View {
        Text(Image(systemName: "arrow.trianglehead.turn.up.right.diamond")) // replace with correct SF Symbol name
            .font(.custom("SFProDisplay", size: 16))
            .foregroundColor(figmaSoftBlue)
            .frame(width: 19, height: 17)
        
    }
}
