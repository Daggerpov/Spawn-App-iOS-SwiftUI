//
//  EventDescriptionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//

import SwiftUI

struct EventDescriptionView: View {
    @ObservedObject var viewModel: EventDescriptionViewModel
    var color: Color
    
    init(event: Event, appUsers: [AppUser], color: Color) {
        self.viewModel = EventDescriptionViewModel(event: event, appUsers: appUsers)
        self.color = color
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title and Time Information
                EventCardTopRowView(event: viewModel.event)
                
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        EventTimeView(event: viewModel.event)
                        EventLocationView(event: viewModel.event)
                    }
                    .foregroundColor(.white)
                    
                    Spacer() // Ensures alignment but doesn't add spacing below the content
                }
                
                // Note
                if let note = viewModel.event.note {
                    Text("Note: \(note)")
                        .font(.body)
                }
                
                if let chatMessages = viewModel.event.chatMessages {
                    Text("\(chatMessages.count) replies")
                }
                
                ScrollView(.vertical) {
                    LazyVStack(spacing: 15) {
                        if let chatMessages = viewModel.event.chatMessages {
                            // TODO: remove this logic out of the view, and into view model
                            ForEach(chatMessages) { chatMessage in
                                let appUser: AppUser = AppUserService.shared.appUserLookup[chatMessage.user.id] ?? AppUser.emptyUser
                                HStack{
                                    if let profilePicture = appUser.profilePicture {
                                        profilePicture
                                            .ProfileImageModifier(imageType: .chatMessage)
                                    }
                                    VStack{
                                        Text(appUser.username)
                                        Text(chatMessage.message)
                                    }
                                    Spacer()
                                    HStack{
                                        Text(chatMessage.timestamp)
                                        // TODO: add logic later, to either use heart.fill or just heart,
                                        // based on whether current user is in the chat message's likedBy array
                                        Image(systemName: "heart")
                                    }
                                }
                            }
                        }
                        
                    }
                }
            }
            .padding(20)
            .background(color)
            .cornerRadius(universalRectangleCornerRadius)
        }
        .padding(.horizontal) // Reduces padding on the bottom
        .padding(.top, 200)
    }
}
