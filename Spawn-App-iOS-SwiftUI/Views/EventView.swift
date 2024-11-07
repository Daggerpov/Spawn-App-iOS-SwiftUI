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
        VStack{
            VStack (spacing: 10) {
                HStack{
                    Text(event.title)
                        .font(.title2)
                        .frame(alignment: .leading)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    VStack{
                        HStack{
                            Spacer()
                            ForEach(0..<Int.random(in: 2...4), id: \.self){ _ in
                                Image("Daniel_Lee_pfp")
                                    .resizable()
                                    .frame(width: 25, height: 25)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                                    .shadow(radius: 10)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .foregroundColor(.white)
            .frame(alignment: .leading)
                
            Spacer()
            HStack{
                VStack{
                    HStack{
                        Text("\(event.startTime) -  \(event.endTime)")
                            .cornerRadius(20)
                            .font(.caption2)
                            .frame(alignment: .leading)
                        // TODO: surround by rounded rectangle
                        Spacer()
                    }
                    Spacer()
                    HStack{
                        Image(systemName: "map")
                        // TODO: surround by circle, per Figma design
                        Text(event.location.locationName)
                            .lineLimit(1)
                            .fixedSize()
                            .font(.caption2)
                        Spacer()
                    }
                    .frame(alignment: .leading)
                    .font(.caption)
                }
                .foregroundColor(.white)
                Spacer()
                Circle()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.white)
                    .background(Color.white)
                    .clipShape(Circle())
                    .overlay(
                        // TODO: obviously change `Bool.random()` later to proper logic
                        // proper logic: (if user is in `Event`'s `participants`)
                        Image(systemName: Bool.random() ? "checkmark" : "star.fill")
                            .resizable()
                            .frame(width: 17.5, height: 17.5)
                            .clipShape(Circle())
                            .shadow(radius: 20)
                            .foregroundColor(color)
                        )
            }
            .frame(alignment: .trailing)
        }
        .padding(20)
        .background(color)
        .cornerRadius(10)
    }
}


