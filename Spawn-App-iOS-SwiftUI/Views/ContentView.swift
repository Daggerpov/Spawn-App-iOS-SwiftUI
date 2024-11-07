//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/3/24.
//

import SwiftUI

struct ContentView: View {
    @Namespace private var animation
    @State private var activeTag: String = "Everyone"
    let mockTags: [String] = ["Everyone", "Close Friends", "Sports", "Hobbies"]
    let colors: [Color] = [Color(hex: "#8084ac"), Color(hex: "#704444"), Color(hex: "#b0442c"), Color(hex: "#889c6c")]
    
    var body: some View {
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
            //            .onChange(of: viewModel.activeCategory) { _ in
            //                viewModel.loadQuotesBySearch()
            //            }
//            Spacer()
//                .frame(maxHeight: .infinity)
            Spacer()
            Spacer()
            VStack{
                ScrollView(.vertical) {
                    LazyVStack(spacing: 15) {
                        ForEach(Event.mockEvents) {mockEvent in
                            EventView(event: mockEvent, color: colors.randomElement() ?? Color.blue)
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
}

#Preview {
    ContentView()
}

extension ContentView {
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
                    Text("udhlee")
                        .bold()
                        .font(.largeTitle)
                    Spacer()
                    
                }
                .font(.title)
            }
            .foregroundColor(Color(hex: "#173131"))
            .frame(alignment: .leading)
            Spacer()
            Image("Daniel_Lee_pfp")
                .resizable()
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .shadow(radius: 10)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 2)
    }
}


