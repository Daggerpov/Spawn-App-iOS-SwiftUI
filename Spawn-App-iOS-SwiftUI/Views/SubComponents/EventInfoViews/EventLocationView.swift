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
                    ZStack(alignment: .leading) {
                        // Background for the text bubble
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 30) // Adjust height as needed

                        HStack(spacing: 5) {
                            Image(systemName: "map")
                                .padding(5)
                                .background(
                                    RoundedRectangle(cornerRadius: 30)
                                        .fill(Color.white.opacity(0.1))
                                )
                            
                            Text(eventLocation)
                                .lineLimit(1)
                                .fixedSize()
                                .font(.caption2)
                                .padding(.leading, 3) // Adjust for spacing
                        }
//                        .padding(.leading, 5) // Extra padding for left alignment
                    }

                }
    }
}
