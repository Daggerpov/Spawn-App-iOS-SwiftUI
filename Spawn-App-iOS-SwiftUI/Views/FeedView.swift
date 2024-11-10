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
    var appUser: AppUser
    
    @State var showingPopup: Bool = false
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
                                    appUser: appUser,
                                    event: mockEvent,
                                    color: colors.randomElement() ?? Color.blue
                                ) { event, color in
                                    eventInPopup = event
                                    colorInPopup = color
                                    showingPopup = true
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding()
            .background(Color(hex: "#C0BCB4"))
            .ignoresSafeArea(.container)
        }
        .popup(isPresented: $showingPopup) {
            if let event = eventInPopup {
                if let color = colorInPopup {
                    EventDescriptionView(
                        event: event,
                        appUsers: AppUser.mockAppUsers,
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
        }
    }
}

#Preview {
    FeedView(appUser: AppUser.danielLee)
}

extension FeedView {
    private var headerView: some View {
        HStack{
            Spacer()
            VStack{
                // TODO: fix the sizes of these texts
                // TODO: fix the text alignment of "hello"
                HStack{
                    Text("hello,")
                        .font(.title)
                    Spacer()
                }
                
                HStack{
                    Image(systemName: "star.fill")
                    Text(appUser.username)
                        .bold()
                        .font(.largeTitle)
                    Spacer()
                }
                .font(.title)
            }
            .foregroundColor(Color(hex: "#173131"))
            .frame(alignment: .leading)
            Spacer()
            
            if let pfp = appUser.profilePicture {
                NavigationLink {
                    ProfileView(appUser: appUser)
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
