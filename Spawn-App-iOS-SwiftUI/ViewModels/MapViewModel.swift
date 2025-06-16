//
//  MapViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/15/25.
//
import MapKit
import SwiftUI

class MapViewModel: Identifiable {
    var lat: Double
    var lon: Double
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    @State var region: MKCoordinateRegion
    
    init(activity: FullFeedActivityDTO) {
        if let location = activity.location {
            lat = location.latitude
            lon = location.longitude
        } else { // TODO: something more robust
            lat = 0
            lon = 0
        }
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
}
