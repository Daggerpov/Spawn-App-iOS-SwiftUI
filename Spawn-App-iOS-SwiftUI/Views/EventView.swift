//
//  EventView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel on 11/4/24.
//

import SwiftUI

struct EventView: View {
    var event: Event
    var color: Color
    var body: some View {
        HStack{
            VStack (spacing: 10) {
                HStack{
                    Text(event.title)
                        .font(.title2)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                HStack{
                    Text("\(event.startTime) -  \(event.endTime)")
                        .cornerRadius(20)
                        .font(.caption2)
                    Spacer()
                }
                HStack{
                    Image(systemName: "map")
                    Text(event.location)
                    Spacer()
                }
                .font(.caption)
            }
            .foregroundColor(.white)
            .frame(alignment: .leading)
            Spacer()
            VStack{
                HStack{
                    Spacer()
                    ForEach(0..<Int.random(in: 2...4), id: \.self){ _ in
                        Image("Daniel_Lee_pfp")
                            .resizable()
                            .frame(width: 25, height: 25)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.black, lineWidth: 2))
                            .shadow(radius: 10)
                    }
                }
                Spacer()
                HStack{
                    Spacer()
                    Circle()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Image(systemName: event.symbolName)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                                .shadow(radius: 20)
                                .foregroundColor(color)
                            )
                    
                }
            }
            .frame(alignment: .trailing)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
}
