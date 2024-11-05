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
            Spacer()
                .frame(maxHeight: .infinity)
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
                Text("hello,")
                    .font(.title2)
                //                        .frame(alignment: .leading)
                
                HStack{
                    Image(systemName: "star.fill")
                    Text("udhlee")
                        .bold()
                    
                }
                .font(.title)
            }
            .frame(alignment: .leading)
            Spacer()
            Spacer()
            Spacer()
            Circle()
            // TODO: change this to a relative size, using Geometry Reader
                .frame(height: 45)
            Spacer()
        }
    }
}

struct TagButtonView: View {
    let mockTag: String
    @Binding var activeTag: String
    var animation: Namespace.ID
    
    var body: some View {
        Button(action: {
            withAnimation(.snappy) {
                activeTag = mockTag
            }
        }) {
            Text(mockTag)
                .font(.callout)
                .foregroundColor(activeTag == mockTag ? .white : .black)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background {
                    Capsule()
                        .fill(activeTag == mockTag ? .black : .white)
                        .matchedGeometryEffect(id: activeTag == mockTag ? "ACTIVETAG" : "", in: animation)
                }
        }
        .buttonStyle(.plain)
        
    }
}
