//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI
import MapKit

struct MapView: View {
    @EnvironmentObject var user: ObservableUser
    
    @StateObject var viewModel: FeedViewModel = FeedViewModel(events: Event.mockEvents)
    @State var camera: MapCameraPosition = .automatic
    let mockTags: [FriendTag] = FriendTag.mockTags

    var body: some View {
        ZStack{
            Map(position: $camera) {
                ForEach(viewModel.events) {mockEvent in
                    if let name = mockEvent.location?.locationName,
                       let lat = mockEvent.location?.latitude,
                       let long = mockEvent.location?.longitude {
                        Annotation(
                            name,
                            coordinate: CLLocationCoordinate2D(
                                latitude: lat,
                                longitude: long
                            )
                        ) {
                            VStack {
                                if let creatorPfp = mockEvent.creator.profilePicture {
                                    VStack (spacing: -8){ // -8, to make the triangle "go inside" the pin
                                        ZStack {
                                            Image(systemName: "mappin.circle.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .foregroundColor(universalAccentColor)
                                            
                                            Image(creatorPfp)
                                                .ProfileImageModifier(imageType: .mapView)
                                        }
                                        
                                        Triangle()
                                            .fill(universalAccentColor)
                                            .frame(width: 40, height: 20)
                                    }
                                }
                            }
                        }
                    }
                }
            }   
            VStack {
                VStack{
                    TagsScrollView(tags: mockTags)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                Spacer()
                HStack (spacing: 35) {
                    BottomNavButtonView(buttonType: .feed)
                    Spacer()
                    BottomNavButtonView(buttonType: .plus)
                    Spacer()
                    BottomNavButtonView(buttonType: .friends)
                    // TODO: make work after designs are finalized
                }
                .padding(32)
            }
            .padding(.top, 50)
        }
        
        .ignoresSafeArea()
        .mapStyle(.standard)
    }
}

#Preview {
    @Previewable @StateObject var observableUser: ObservableUser = ObservableUser(
        user: .danielLee
    )
    MapView()
        .environmentObject(observableUser)
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) 
        path.closeSubpath()
        return path
    }
}

