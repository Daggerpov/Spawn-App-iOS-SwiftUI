//
//  MapViewModel.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/15/25.
//
import MapKit
import Observation
import SwiftUI

@Observable
@MainActor
final class MapViewModel: Identifiable {
	// Note: activity is still ObservableObject; will be migrated separately
	var activity: FullFeedActivityDTO
	let id = UUID()

	var lat: Double {
		activity.location?.latitude ?? 0
	}

	var lon: Double {
		activity.location?.longitude ?? 0
	}

	var coordinate: CLLocationCoordinate2D {
		CLLocationCoordinate2D(latitude: lat, longitude: lon)
	}

	var mapItem: MKMapItem {
		let item = MKMapItem(placemark: .init(coordinate: coordinate))
		item.name = activity.location?.name ?? "Activity Location"
		return item
	}

	var initialRegion: MKCoordinateRegion {
		MKCoordinateRegion(
			center: coordinate,
			span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
		)
	}

	init(activity: FullFeedActivityDTO) {
		self.activity = activity
	}

	// Add method to update activity reference
	func updateActivity(_ newActivity: FullFeedActivityDTO) {
		self.activity = newActivity
	}
}
