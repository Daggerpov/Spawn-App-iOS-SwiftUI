//
//  FriendMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import SwiftUI
import MapKit

struct FriendMapView: View {
    @EnvironmentObject var user: ObservableUser
    
    @StateObject var viewModel: FeedViewModel = FeedViewModel(events: Event.mockEvents)
    
    @State var camera: MapCameraPosition = .automatic
    
    var body: some View {
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
        .ignoresSafeArea()
        .mapStyle(.standard)
    }
}

#Preview {
    @Previewable @StateObject var observableUser: ObservableUser = ObservableUser(
        user: .danielLee
    )
    FriendMapView()
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

