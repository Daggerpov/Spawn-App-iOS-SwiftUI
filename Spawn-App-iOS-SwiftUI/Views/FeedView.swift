//
//  FeedView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/3/24.
//

import PopupView

import SwiftUI

struct FeedView: View {
    @StateObject var viewModel: FeedViewModel = FeedViewModel(events: Event.mockEvents)
    
    @Namespace private var animation: Namespace.ID
    @State private var activeTag: String = "Everyone"
    let mockTags: [String] = ["Everyone", "Close Friends", "Sports", "Hobbies"]
    var user: User
    
    @State var showingEventDescriptionPopup: Bool = false
    @State var showingOpenFriendTagsPopup: Bool = false
    @State var showingFriendsPopup: Bool = false
    @State var showingTagsPopup: Bool = false
    @State var eventInPopup: Event?
    @State var colorInPopup: Color?
    
    var body: some View {
        NavigationStack{
            VStack{
                Spacer()
                headerView.padding(.top, 50)
                Spacer()
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(mockTags, id: \.self) { mockTag in
                            TagButtonView(mockTag: mockTag, activeTag: $activeTag, animation: animation)
                        }
                    }
                    .padding(.top, 10)
                    .padding(.leading, 16)
                    .padding(.trailing, 16)
                }
                // TODO: implement logic here to adjust search results when the tag clicked is changed
                Spacer()
                Spacer()
                VStack{
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.events) {mockEvent in
                                EventCardView(
                                    user: User,
                                    event: mockEvent,
                                    // TODO: change this logic to be based on the event in relation to which friend tag the creator belongs to
                                    color: eventColors.randomElement() ?? Color.blue
                                ) { event, color in
                                    eventInPopup = event
                                    colorInPopup = color
                                    showingEventDescriptionPopup = true
                                }
                            }
                        }
                    }
                    HStack (spacing: 35) {
                        BottomNavButtonView(buttonType: .map)
                        Spacer()
                        BottomNavButtonView(buttonType: .plus)
                        Spacer()
                        BottomNavButtonView(buttonType: .tag)
                            .onTapGesture {
                                showingOpenFriendTagsPopup = true
                            }
                    }
                    
                }
                .padding(.horizontal)
                
            }
            .padding()
            .background(universalBackgroundColor)
            .ignoresSafeArea(.container)
            .dimmedBackground(isActive: showingTagsPopup || showingEventDescriptionPopup || showingFriendsPopup)
        }
        // TODO: fix these repetitive popups; maybe separate into another component
        .popup(isPresented: $showingEventDescriptionPopup) {
            if let event = eventInPopup {
                if let color = colorInPopup {
                    EventDescriptionView(
                        event: event,
                        Users: User.mockUsers,
                        color: color
                    )
                }
            }
        } customize: {
            $0
                .type(.floater(
                    verticalPadding: 20,
                    horizontalPadding: 20,
                    useSafeAreaInset: false
                ))
            // TODO: read up on the documentation: https://github.com/exyte/popupview
            // so that the description view is dismissed upon clicking outside
            
            // TODO: investigate making the background view dim, just like in the figma design
        }
        .popup(isPresented: $showingFriendsPopup) {
            FriendsListView(user: User)
        } customize: {
            $0
                .type(.floater(
                    verticalPadding: 20,
                    horizontalPadding: 20,
                    useSafeAreaInset: false
                ))
            // TODO: read up on the documentation: https://github.com/exyte/popupview
            // so that the description view is dismissed upon clicking outside
            
            // TODO: investigate making the background view dim, just like in the figma design
        }
        .popup(isPresented: $showingTagsPopup) {
            TagsListView(user: User)
        } customize: {
            $0
                .type(.floater(
                    verticalPadding: 20,
                    horizontalPadding: 20,
                    useSafeAreaInset: false
                ))
            // TODO: read up on the documentation: https://github.com/exyte/popupview
            // so that the description view is dismissed upon clicking outside
            
            // TODO: investigate making the background view dim, just like in the figma design
        }
        .popup(isPresented: $showingOpenFriendTagsPopup) {
            OpenFriendTagsView() { type in
                switch type {
                    case .friends:
                        showingFriendsPopup = true
                    case .tags:
                        showingTagsPopup = true
                }
                showingOpenFriendTagsPopup = false
            }
        } customize: {
            $0
                .type(.toast)
                .position(.bottom)
                .dragToDismiss(true)
                .closeOnTap(false)
                .closeOnTapOutside(true)
        }
    }
}

#Preview {
    FeedView(user: User.danielLee)
}

extension FeedView {
    private var headerView: some View {
        HStack{
            Spacer()
            VStack{
                HStack{
                    Text("hello,")
                        .font(.title)
                    Spacer()
                }
                
                HStack{
                    Image(systemName: "star.fill")
                    Text(User.username)
                        .bold()
                        .font(.largeTitle)
                    Spacer()
                }
                .font(.title)
            }
            .foregroundColor(universalAccentColor)
            .frame(alignment: .leading)
            Spacer()
            
            if let pfp = User.profilePicture {
                NavigationLink {
                    ProfileView(user: User)
                } label: {
                    pfp
                        .ProfileImageModifier(imageType: .feedPage)
                }
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}

extension View {
    func dimmedBackground(isActive: Bool) -> some View {
        self.overlay(
            Group {
                if isActive {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeInOut, value: isActive)
                }
            }
        )
    }
}
