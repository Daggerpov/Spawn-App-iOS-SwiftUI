//
//  EventLocationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventLocationView: View {
    var event: Event

    var body: some View {
        if let eventLocation = event.location?.locationName {
            HStack{
                Image(systemName: "map")
                // TODO: surround by circle, per Figma design
                Text(eventLocation)
                    .lineLimit(1)
                    .fixedSize()
                    .font(.caption2)
                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.init(white: 2, opacity: 0.05))
            )
            .frame(alignment: .leading)
            .font(.caption)
        }
    }
}
