import CoreLocation
import MapKit
import SwiftUI

struct LocationPickerView: View {
	@State private var searchText = ""
	@State private var searchResults: [SearchResultItem] = []
	@Environment(\.presentationMode) var presentationMode

	let userLocation: CLLocationCoordinate2D?
	let onLocationSelected: (String) -> Void

	// Predefined locations with coordinates for distance calculation
	private let predefinedLocations: [LocationData] = {
		print("🔍 DEBUG: Initializing predefinedLocations array")
		let locations = [
			LocationData(
				name: "UBC Sauder School of Business",
				address: "2053 Main Mall, Vancouver, BC V6T 1Z2",
				coordinate: CLLocationCoordinate2D(
					latitude: 49.2648,
					longitude: -123.2534
				)
			),
			LocationData(
				name: "AMS Student Nest",
				address: "6133 University Blvd, Vancouver, BC V6T 1Z1",
				coordinate: CLLocationCoordinate2D(
					latitude: 49.2669,
					longitude: -123.2499
				)
			),
			LocationData(
				name: "Starbucks Coffee",
				address: "6138 Student Union Blvd, Vancouver, BC V6T 1Z1",
				coordinate: CLLocationCoordinate2D(
					latitude: 49.2672,
					longitude: -123.2497
				)
			),
			LocationData(
				name: "Thunderbird Park",
				address: "2700 East Mall, Vancouver, BC V6T 1Z4",
				coordinate: CLLocationCoordinate2D(
					latitude: 49.2525,
					longitude: -123.2592
				)
			),
		]
		print("🔍 DEBUG: Created \(locations.count) predefined locations")
		return locations
	}()

	var body: some View {
		NavigationView {
			VStack(spacing: 0) {
				// Search bar
				HStack(spacing: 12) {
					Image(systemName: "magnifyingglass")
						.foregroundColor(figmaBlack300)
						.font(.system(size: 16))

					TextField("Where at?", text: $searchText)
						.foregroundColor(universalAccentColor)
						.font(.system(size: 16))
						.onChange(of: searchText) {
							searchLocations()
						}
				}
				.padding(.vertical, 12)
				.padding(.horizontal, 16)
				.background(Color(UIColor.systemGray6))
				.clipShape(RoundedRectangle(cornerRadius: 10))
				.padding(.horizontal, 16)
				.padding(.top, 8)

				List {
					// Current Location
					if userLocation != nil {
						LocationRowView(
							icon: "location.fill",
							iconColor: .blue,
							title: "Current Location",
							subtitle:
								"5934 University Blvd, Vancouver, BC V6T 1G2",
							distance: nil
						) {
							print("🔍 DEBUG: Current Location selected")
							onLocationSelected("Current Location")
							presentationMode.wrappedValue.dismiss()
						}
						.onAppear {
							print("🔍 DEBUG: Rendering Current Location row")
						}
					}

					// Predefined locations with distance
					ForEach(predefinedLocations, id: \.name) { location in
						LocationRowView(
							icon: "mappin.circle",
							iconColor: figmaBlack300,
							title: location.name,
							subtitle: location.address,
							distance: distanceFromUser(to: location.coordinate)
						) {
							print("🔍 DEBUG: Predefined location selected: \(location.name)")
							onLocationSelected(location.address)
							presentationMode.wrappedValue.dismiss()
						}
						.onAppear {
							print("🔍 DEBUG: Rendering predefined location: \(location.name)")
						}
					}

					// Search results - now thread-safe with proper identifiers
					ForEach(searchResults) { searchResult in
						let item = searchResult.mapItem
						LocationRowView(
							icon: "mappin.circle",
							iconColor: figmaBlack300,
							title: item.name ?? "Unknown Location",
							subtitle: item.placemark.formattedAddress() ?? "",
							distance: userLocation != nil
								? distanceFromUser(
									to: item.placemark.coordinate
								) : nil
						) {
							print("🔍 DEBUG: Search result selected: \(item.name ?? "Unknown")")
							onLocationSelected(
								item.placemark.formattedAddress() ?? item.name
									?? "Selected Location"
							)
							presentationMode.wrappedValue.dismiss()
						}
						.onAppear {
							print("🔍 DEBUG: Rendering search result: \(item.name ?? "Unknown")")
						}
					}

					// Set Location on Map option
					LocationRowView(
						icon: "map",
						iconColor: figmaBlack300,
						title: "Set Location on Map",
						subtitle: nil,
						distance: nil
					) {
						print("🔍 DEBUG: Set Location on Map selected")
						onLocationSelected("Set Location on Map")
						presentationMode.wrappedValue.dismiss()
					}
					.onAppear {
						print("🔍 DEBUG: Rendering Set Location on Map row")
					}
				}
				.listStyle(PlainListStyle())
				.listRowSeparator(.hidden)
			}
			.navigationTitle("Choose Location")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Cancel") {
						presentationMode.wrappedValue.dismiss()
					}
				}
			}
		}
	}

	private func searchLocations() {
		print("🔍 DEBUG: searchLocations called with text: '\(searchText)'")
		guard !searchText.isEmpty else {
			print("🔍 DEBUG: searchText is empty, clearing results")
			DispatchQueue.main.async {
				self.searchResults = []
			}
			return
		}

		print("🔍 DEBUG: Creating MKLocalSearch.Request")
		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = searchText
		print("🔍 DEBUG: Set naturalLanguageQuery to: '\(searchText)'")
		if let userLocation = userLocation {
			// Validate user location before using it in search region
			guard CLLocationCoordinate2DIsValid(userLocation) else {
				print(
					"⚠️ searchLocations: Invalid user location - \(userLocation)"
				)
				// Continue search without region restriction
				print("🔍 DEBUG: Starting search without region restriction")
				let search = MKLocalSearch(request: request)
				search.start { response, error in
					print("🔍 DEBUG: Search completed")
					if let error = error {
						print("🔍 DEBUG: Search error: \(error)")
					}
					guard let response = response, error == nil else {
						print("🔍 DEBUG: No response or error occurred, clearing results")
						DispatchQueue.main.async {
							self.searchResults = []
						}
						return
					}
					print("🔍 DEBUG: Got \(response.mapItems.count) search results")
					DispatchQueue.main.async {
						// Filter out results with invalid coordinates
						let validResults = response.mapItems.filter { item in
							let isValid = CLLocationCoordinate2DIsValid(
								item.placemark.coordinate
							)
							print("🔍 DEBUG: Result '\(item.name ?? "Unknown")' coordinate valid: \(isValid)")
							return isValid
						}
						print("🔍 DEBUG: \(validResults.count) results have valid coordinates")
						self.searchResults = Array(validResults.prefix(10)).map
						{ SearchResultItem($0) }
						print("🔍 DEBUG: Set searchResults to \(self.searchResults.count) items")
					}
				}
				return
			}

			request.region = MKCoordinateRegion(
				center: userLocation,
				span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
			)
		}

		print("🔍 DEBUG: Starting search with region restriction")
		let search = MKLocalSearch(request: request)
		search.start { response, error in
			print("🔍 DEBUG: Search with region completed")
			if let error = error {
				print("🔍 DEBUG: Search with region error: \(error)")
			}
			guard let response = response, error == nil else {
				print("🔍 DEBUG: No response or error occurred (with region), clearing results")
				DispatchQueue.main.async {
					self.searchResults = []
				}
				return
			}
			print("🔍 DEBUG: Got \(response.mapItems.count) search results (with region)")
			DispatchQueue.main.async {
				// Filter out results with invalid coordinates
				let validResults = response.mapItems.filter { item in
					let isValid = CLLocationCoordinate2DIsValid(item.placemark.coordinate)
					print("🔍 DEBUG: Result '\(item.name ?? "Unknown")' coordinate valid (with region): \(isValid)")
					return isValid
				}
				print("🔍 DEBUG: \(validResults.count) results have valid coordinates (with region)")
				self.searchResults = Array(validResults.prefix(10)).map {
					SearchResultItem($0)
				}
				print("🔍 DEBUG: Set searchResults to \(self.searchResults.count) items (with region)")
			}
		}
	}

	private func distanceFromUser(to coordinate: CLLocationCoordinate2D)
		-> String?
	{
		guard let userLocation = userLocation else { return nil }

		// Validate both coordinates before calculating distance to prevent NaN values
		guard
			CLLocationCoordinate2DIsValid(userLocation)
				&& CLLocationCoordinate2DIsValid(coordinate)
		else {
			print(
				"⚠️ distanceFromUser: Invalid coordinates - user: \(userLocation), target: \(coordinate)"
			)
			return nil
		}

		let userCLLocation = CLLocation(
			latitude: userLocation.latitude,
			longitude: userLocation.longitude
		)
		let targetLocation = CLLocation(
			latitude: coordinate.latitude,
			longitude: coordinate.longitude
		)
		let distance = userCLLocation.distance(from: targetLocation)

		// Additional check to ensure distance is valid
		guard distance.isFinite && !distance.isNaN else {
			print(
				"⚠️ distanceFromUser: Invalid distance calculated: \(distance)"
			)
			return nil
		}

		if distance < 1000 {
			return "\(Int(distance))m"
		} else {
			let km = distance / 1000
			if km < 10 {
				return String(format: "%.1fkm", km)
			} else {
				return "\(Int(km))km"
			}
		}
	}
}

