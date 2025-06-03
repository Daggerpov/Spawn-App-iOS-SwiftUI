import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionView: View {
	@EnvironmentObject var viewModel: ActivityCreationViewModel
	@Environment(\.dismiss) private var dismiss
	@StateObject private var locationManager = LocationManager()
	
	@State private var searchText = ""
	@State private var searchResults: [MKMapItem] = []
	@State private var selectedMapItem: MKMapItem?
	@State private var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Default to Vancouver
		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
	)
	
	var body: some View {
		VStack(spacing: 0) {
			// Search bar
			searchBar
				.padding()
			
			// Current location button
			if let userLocation = locationManager.userLocation {
				Button(action: {
					selectLocation(
						coordinate: userLocation,
						name: "Current Location",
						address: "5934 University Blvd"
					)
				}) {
					HStack {
						Image(systemName: "location.fill")
							.foregroundColor(.blue)
						Text("Current Location")
						Spacer()
						Text("5934 University Blvd")
							.foregroundColor(.gray)
					}
					.padding()
					.background(Color.gray.opacity(0.1))
					.cornerRadius(12)
				}
				.padding(.horizontal)
			}
			
			// Search results or recent locations
			if !searchText.isEmpty && !searchResults.isEmpty {
				searchResultsList
			} else {
				recentLocationsList
			}
			
			// Map view
			if let selectedLocation = selectedMapItem?.placemark.coordinate {
				MapViewRepresentable(
					region: .constant(MKCoordinateRegion(
						center: selectedLocation,
						span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
					)),
					onRegionChange: {}
				)
				.frame(height: 200)
				.cornerRadius(12)
				.padding()
			}
			
			// Confirm button
			if selectedMapItem != nil {
				Button(action: {
					saveLocation()
					dismiss()
				}) {
					Text("Confirm Location")
						.font(.headline)
						.foregroundColor(.white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(universalSecondaryColor)
						.cornerRadius(12)
				}
				.padding()
			}
		}
		.background(Color(.systemBackground))
		.onAppear {
			if let userLocation = locationManager.userLocation {
				region = MKCoordinateRegion(
					center: userLocation,
					span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
				)
			}
		}
	}
	
	private var searchBar: some View {
		HStack {
			Image(systemName: "magnifyingglass")
				.foregroundColor(.gray)
			
			TextField("Where at?", text: $searchText)
				.onChange(of: searchText) { _ in
					searchLocations()
				}
			
			if !searchText.isEmpty {
				Button(action: { searchText = "" }) {
					Image(systemName: "xmark.circle.fill")
						.foregroundColor(.gray)
				}
			}
		}
		.padding()
		.background(Color(.systemGray6))
		.cornerRadius(12)
	}
	
	private var searchResultsList: some View {
		ScrollView {
			LazyVStack(spacing: 0) {
				ForEach(searchResults, id: \.self) { item in
					Button(action: {
						selectSearchResult(item)
					}) {
						HStack {
							VStack(alignment: .leading) {
								Text(item.name ?? "Unknown Location")
									.foregroundColor(.primary)
								if let address = item.placemark.formattedAddress() {
									Text(address)
										.font(.caption)
										.foregroundColor(.gray)
								}
							}
							Spacer()
							Image(systemName: "chevron.right")
								.foregroundColor(.gray)
						}
						.padding()
					}
					Divider()
				}
			}
		}
	}
	
	private var recentLocationsList: some View {
		List {
			ForEach([
				"UBC Sauder School of Business",
				"AMS Student Nest",
				"Starbucks Coffee",
				"Thunderbird Park"
			], id: \.self) { location in
				Button(action: {
					// Handle location selection
				}) {
					HStack {
						Text(location)
						Spacer()
						Image(systemName: "chevron.right")
							.foregroundColor(.gray)
					}
				}
				.foregroundColor(.primary)
			}
			
			Button(action: {
				// Handle set location on map
			}) {
				Text("Set Location on Map")
			}
			
			Button(action: {
				// Handle saved locations
			}) {
				Text("Saved Locations")
			}
		}
		.listStyle(PlainListStyle())
	}
	
	private func searchLocations() {
		guard !searchText.isEmpty else {
			searchResults = []
			return
		}
		
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = searchText
		request.region = region
		
		let search = MKLocalSearch(request: request)
		search.start { response, error in
			guard let response = response, error == nil else {
				searchResults = []
				return
			}
			searchResults = response.mapItems
		}
	}
	
	private func selectSearchResult(_ mapItem: MKMapItem) {
		selectedMapItem = mapItem
		searchText = mapItem.name ?? ""
	}
	
	private func selectLocation(coordinate: CLLocationCoordinate2D, name: String, address: String) {
		let placemark = MKPlacemark(coordinate: coordinate)
		selectedMapItem = MKMapItem(placemark: placemark)
		selectedMapItem?.name = name
	}
	
	private func saveLocation() {
		guard let mapItem = selectedMapItem else { return }
		
		let location = Location(
			id: UUID(),
			name: mapItem.name ?? "Selected Location",
			latitude: mapItem.placemark.coordinate.latitude,
			longitude: mapItem.placemark.coordinate.longitude
		)
		
		viewModel.setLocation(location)
	}
}

// MKPlacemark extension to get formatted address
extension MKPlacemark {
	func formattedAddress() -> String? {
		let components = [
			thoroughfare,
			locality,
			administrativeArea,
			postalCode,
			country
		]
		return components
			.compactMap { $0 }
			.filter { !$0.isEmpty }
			.joined(separator: ", ")
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared
	LocationSelectionView()
		.environmentObject(ActivityCreationViewModel.shared)
}
