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
        HStack{
            Text(viewModel.eventTimeDisplayString)
                .font(.caption2)
                .frame(alignment: .leading)
            // TODO: surround by rounded rectangle
            Spacer()
        }
    }
}
