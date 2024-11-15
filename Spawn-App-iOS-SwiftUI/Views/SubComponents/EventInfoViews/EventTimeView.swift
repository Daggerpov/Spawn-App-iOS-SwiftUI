//
//  EventTimeView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI

struct EventTimeView: View {
    @ObservedObject var viewModel: EventTimeViewModel
    
    init(event: Event) {
        self.viewModel = EventTimeViewModel(event: event)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Background for the text bubble
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.1))
                .frame(height: 30) // Adjust height as needed

            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .padding(5)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color.white.opacity(0.1))
                    )
                
                Text(viewModel.eventTimeDisplayString)
                    .lineLimit(1)
                    .fixedSize()
                    .font(.caption2)
                    .padding(.leading, 3) // Adjust for spacing
            }
//                        .padding(.leading, 5) // Extra padding for left alignment
        }
//        HStack {
//            Text(viewModel.eventTimeDisplayString)
//                .font(.caption2)
//                .padding(6)
//                .background(
//                    RoundedRectangle(cornerRadius: 15)
//                        .fill(Color.init(white: 2, opacity: 0.05))
//                )
//                .frame(alignment: .leading)
//            Spacer()
//        }
    }
}
