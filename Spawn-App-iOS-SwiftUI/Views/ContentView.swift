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
    
    var body: some View {
        VStack{
            headerView
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(mockTags, id: \.self) { mockTag in
                        TagButtonView(mockTag: mockTag, activeTag: $activeTag, animation: animation)
                    }
                }
                .padding(.top, 10)
            }
            // TODO: implement logic here to adjust search results when the tag clicked is changed
            //            .onChange(of: viewModel.activeCategory) { _ in
            //                viewModel.loadQuotesBySearch()
            //            }
//            Spacer()
//                .frame(maxHeight: .infinity)
            VStack{
                ScrollView(.vertical) {
                    LazyVStack(spacing: 15) {
                        ForEach(0..<4) {_ in 
                            EventView()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray)
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
                    
                }
                .font(.title)
            }
            Spacer()
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
        .padding()
    }
}


