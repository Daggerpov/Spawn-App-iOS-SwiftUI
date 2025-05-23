//
//  EventCardPopupView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/18/25.
//

import SwiftUI

struct EventCardPopupView: View {
    var event: FullFeedEventDTO
    var color: Color
    var userId: UUID
    @ObservedObject var viewModel: EventDescriptionViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            // Top Bar: Drag indicator, expand/collapse, menu
            EventCardPopupTopBarView()
            
            // Title & Time Centered
            EventCardPopupTitleTimeView(event: event)
            
            // Action Button & Participants Row
            EventPopupParticipantRowView(event: event, isParticipating: $viewModel.isParticipating)
            
            // Map Placeholder
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.2))
                .frame(height: 110)
                .overlay(Text("[Map goes here]").foregroundColor(.white.opacity(0.7)))
                .padding(.horizontal)
                .padding(.bottom, 14)
            
            // Location Row
            EventCardPopupLocationRowView(event: event)
            
            // Description & Comments
            EventCardPopupDescriptionView(event: event)
            
            // Timestamp
            Text("Posted 7 hours ago") // TODO: Use real timestamp
                .font(.onestRegular(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.bottom, 18)
        }
        .background(color)
        .cornerRadius(32)
        .padding(.top, 16)
        .padding(.horizontal, 8)
    }
}

#if DEBUG
struct EventCardPopupView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock data for preview
        let mockEvent = FullFeedEventDTO.mockDinnerEvent // Replace with your mock or sample event
        let mockColor = Color(red: 0.48, green: 0.60, blue: 1.0)
        let mockUserId = UUID()
        let viewModel = EventDescriptionViewModel(apiService: MockAPIService(), event: mockEvent, senderUserId: mockUserId)
        EventCardPopupView(event: mockEvent, color: mockColor, userId: mockUserId, viewModel: viewModel)
            .background(Color.gray.opacity(0.2))
            .previewLayout(.sizeThatFits)
    }
}
#endif
