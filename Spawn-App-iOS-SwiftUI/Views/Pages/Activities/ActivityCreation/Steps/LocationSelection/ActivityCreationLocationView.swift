import CoreLocation
import MapKit
import SwiftUI

// MARK: - Location Selection Mode
enum LocationSelectionMode {
	case search  // Full drawer with search and location list (default)
	case map  // Map with draggable pin
}

struct ActivityCreationLocationView: View {
	var viewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared
	@ObservedObject private var locationManager = LocationManager.shared

	// Location selection mode - search is default per Figma designs
	@State private var selectionMode: LocationSelectionMode = .search

	// Map region state
	@State private var region: MKCoordinateRegion = {
		let defaultCenter = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207)  // Vancouver
		let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)

		guard
			CLLocationCoordinate2DIsValid(defaultCenter) && defaultSpan.latitudeDelta > 0
				&& defaultSpan.longitudeDelta > 0 && defaultSpan.latitudeDelta.isFinite
				&& defaultSpan.longitudeDelta.isFinite
		else {
			return MKCoordinateRegion(
				center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
				span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
			)
		}

		return MKCoordinateRegion(center: defaultCenter, span: defaultSpan)
	}()

	// Search state
	@State private var searchText: String = ""
	@State private var searchResults: [SearchResultItem] = []
	@State private var isSearching = false

	// Drag gesture state for dismissing drawer
	@State private var dragOffset: CGFloat = 0

	// Map state
	@State private var locationDisplayText: String = ""
	@State private var isUpdatingLocation = false
	@State private var debounceTimer: Timer?
	@State private var is3DMode: Bool = false

	// Location error handling
	@State private var showLocationError = false

	let onNext: () -> Void
	let onBack: (() -> Void)?

	// Predefined locations with coordinates
	private let predefinedLocations: [LocationData] = [
		LocationData(
			name: "UBC Sauder School of Business",
			address: "2053 Main Mall, Vancouver, BC V6T 1Z2",
			coordinate: CLLocationCoordinate2D(latitude: 49.2648, longitude: -123.2534)
		),
		LocationData(
			name: "AMS Student Nest",
			address: "6133 University Blvd, Vancouver, BC V6T 1Z1",
			coordinate: CLLocationCoordinate2D(latitude: 49.2669, longitude: -123.2499)
		),
		LocationData(
			name: "Starbucks Coffee",
			address: "6138 Student Union Blvd, Vancouver, BC V6T 1Z1",
			coordinate: CLLocationCoordinate2D(latitude: 49.2672, longitude: -123.2497)
		),
		LocationData(
			name: "Thunderbird Park",
			address: "2700 East Mall, Vancouver, BC V6T 1Z4",
			coordinate: CLLocationCoordinate2D(latitude: 49.2525, longitude: -123.2592)
		),
	]

	var body: some View {
		ZStack {
			// Map background (always visible)
			mapBackgroundView

			// Content based on selection mode
			switch selectionMode {
			case .search:
				searchModeView
			case .map:
				mapModeView
			}
		}
		.background(universalBackgroundColor)
		.onAppear {
			initializeView()
		}
		.onDisappear {
			cleanupView()
		}
		.onReceive(locationManager.$userLocation) { location in
			handleUserLocationUpdate(location)
		}
		.onReceive(locationManager.$locationError) { error in
			if let error = error {
				print("Location error in ActivityCreationLocationView: \(error)")
				showLocationError = true
			}
		}
		.alert("Location Error", isPresented: $showLocationError) {
			Button("OK") { showLocationError = false }
			if locationManager.authorizationStatus == .denied {
				Button("Settings") {
					if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(settingsUrl)
					}
				}
			}
		} message: {
			Text(locationManager.locationError ?? "An unknown location error occurred.")
		}
	}

	// MARK: - Map Background View
	private var mapBackgroundView: some View {
		UnifiedMapView(
			region: $region,
			is3DMode: $is3DMode,
			showsUserLocation: true,
			annotationItems: [],
			isLocationSelectionMode: selectionMode == .map,
			onMapWillChange: nil,
			onMapDidChange: { coordinate in
				if selectionMode == .map {
					updateLocationText(for: coordinate)
				}
			},
			onActivityTap: { _ in }
		)
		.ignoresSafeArea(.all, edges: .top)
	}

	// MARK: - Search Mode View (Default)
	private var searchModeView: some View {
		VStack(spacing: 0) {
			// Full-height drawer
			VStack {
				// Handle bar
				RoundedRectangle(cornerRadius: 2.5)
					.fill(figmaBlack300)
					.frame(width: 50, height: 4)
					.padding(.top, 12)
					.padding(.bottom, 10)

				// Header with back button and title
				ZStack {
					// Title centered in the full width
					Text("Choose Location")
						.font(.onestSemiBold(size: 20))
						.foregroundColor(universalAccentColor)

					// Back button aligned to leading edge
					HStack {
						Button(action: { onBack?() }) {
							Image(systemName: "chevron.left")
								.font(.system(size: 20, weight: .semibold))
								.foregroundColor(universalAccentColor)
						}
						Spacer()
					}
				}
				.frame(height: 24)
				.padding(.horizontal, 26)
				.padding(.bottom, 6)

				// Search bar
				HStack {
					TextField("Where at?", text: $searchText)
						.font(.onestRegular(size: 16))
						.foregroundColor(searchText.isEmpty ? figmaBlack300 : universalAccentColor)
						.onChange(of: searchText) { _, _ in
							searchLocations()
						}
				}
				.padding(.horizontal, 16)
				.padding(.vertical, 12)
				.overlay(
					RoundedRectangle(cornerRadius: 8)
						.stroke(figmaBlack300, lineWidth: 1)
				)
				.padding(.horizontal, 26)
				.padding(.bottom, 2)

				// Location list
				ScrollView {
					VStack(spacing: 0) {
						// Current Location option
						if locationManager.userLocation != nil {
							LocationListRow(
								icon: "location.fill",
								iconColor: .blue,
								title: "Current Location",
								subtitle: getCurrentLocationAddress(),
								distance: nil
							) {
								selectCurrentLocation()
							}
						}

						// Search results or predefined locations
						if !searchText.isEmpty && !searchResults.isEmpty {
							ForEach(searchResults) { result in
								LocationListRow(
									icon: "mappin.circle",
									iconColor: figmaBlack300,
									title: result.mapItem.name ?? "Unknown Location",
									subtitle: result.mapItem.placemark.formattedAddress() ?? "",
									distance: distanceFromUser(to: result.mapItem.placemark.coordinate)
								) {
									selectSearchResult(result)
								}
							}
						} else {
							// Predefined locations
							ForEach(predefinedLocations, id: \.name) { location in
								LocationListRow(
									icon: "mappin.circle",
									iconColor: figmaBlack300,
									title: location.name,
									subtitle: location.address,
									distance: distanceFromUser(to: location.coordinate)
								) {
									selectPredefinedLocation(location)
								}
							}
						}

						// Set Location on Map option
						LocationListRow(
							icon: "map",
							iconColor: figmaBlack300,
							title: "Set Location on Map",
							subtitle: nil,
							distance: nil,
							showDivider: false
						) {
							withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
								selectionMode = .map
							}
						}
					}
					.padding(.horizontal, 26)
					Spacer()
				}
				Spacer()
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(
				universalBackgroundColor
					.clipShape(
						UnevenRoundedRectangle(
							topLeadingRadius: 20,
							bottomLeadingRadius: 0,
							bottomTrailingRadius: 0,
							topTrailingRadius: 20
						)
					)
					.shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 0)
			)
			.offset(y: max(0, dragOffset))
			.gesture(
				DragGesture()
					.onChanged { value in
						// Only allow dragging down
						if value.translation.height > 0 {
							dragOffset = value.translation.height
						}
					}
					.onEnded { value in
						let translation = value.translation.height
						let velocity = value.predictedEndTranslation.height - value.translation.height

						// If dragged down enough or with enough velocity, switch to map mode
						if translation > 100 || velocity > 500 {
							withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
								dragOffset = 0
								selectionMode = .map
							}
						} else {
							// Snap back
							withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
								dragOffset = 0
							}
						}
					}
			)
			.padding(.top, 60)  // Leave some map visible at the top
		}
	}

	// MARK: - Map Mode View
	private var mapModeView: some View {
		ZStack {
			// Pin in center of map
			VStack {
				Spacer()
				ZStack {
					// Base ellipse under the pin
					Ellipse()
						.fill(Color(red: 0.15, green: 0.55, blue: 1))
						.frame(width: 19.90, height: 9.95)
						.opacity(0.9)
						.shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 3)
						.offset(y: 18)

					// Pin icon
					Image(systemName: "mappin")
						.font(.system(size: 34))
						.foregroundColor(.blue)
						.shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
				}
				Spacer()
			}
			.allowsHitTesting(false)

			// Back button
			VStack {
				HStack {
					Button(action: {
						onBack?()
					}) {
						Image(systemName: "chevron.left")
							.font(.system(size: 24, weight: .bold))
							.foregroundColor(figmaBlack300)
					}
					.frame(width: 48, height: 48)
					.background(.white)
					.cornerRadius(100)
					.shadow(color: Color.black.opacity(0.25), radius: 8, y: 2)
					.padding(.leading, 24)

					Spacer()
				}
				.padding(.top, 24)

				Spacer()
			}

			// Map control buttons
			MapControlButtons(
				is3DMode: $is3DMode,
				region: $region,
				locationManager: locationManager
			)

			// Bottom drawer for map mode
			VStack {
				Spacer()

				VStack(spacing: 0) {
					// Handle bar
					RoundedRectangle(cornerRadius: 2.5)
						.fill(figmaBlack300)
						.frame(width: 50, height: 4)
						.padding(.top, 12)
						.padding(.bottom, 20)

					VStack(spacing: 20) {
						// Title and instruction
						VStack(alignment: .leading, spacing: 4) {
							Text("Set Location")
								.font(.onestSemiBold(size: 20))
								.foregroundColor(universalAccentColor)

							Text("Drag map to move pin")
								.font(.onestMedium(size: 16))
								.foregroundColor(figmaBlack300)
						}
						.frame(maxWidth: .infinity, alignment: .leading)

						// Address display with search button
						Button(action: {
							withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
								dragOffset = 0
								selectionMode = .search
							}
						}) {
							HStack {
								Text(locationDisplayText.isEmpty ? "Searching..." : locationDisplayText)
									.font(.onestMedium(size: 16))
									.foregroundColor(universalSecondaryColor)
									.lineLimit(1)

								Spacer()

								Image(systemName: "magnifyingglass")
									.font(.system(size: 16))
									.foregroundColor(universalSecondaryColor)
							}
						}
						.padding(16)
						.overlay(
							RoundedRectangle(cornerRadius: 16)
								.stroke(universalSecondaryColor, lineWidth: 1)
						)

						// Confirm button
						ActivityNextStepButton(title: "Confirm Location") {
							confirmMapLocation()
						}

						// Step indicators
						StepIndicatorView(currentStep: 2, totalSteps: 3)
							.padding(.bottom, 8)
					}
				}
				.padding(.horizontal, 26)
				.padding(.bottom, 10)
				.background(
					universalBackgroundColor
						.clipShape(
							UnevenRoundedRectangle(
								topLeadingRadius: 20,
								bottomLeadingRadius: 0,
								bottomTrailingRadius: 0,
								topTrailingRadius: 20
							)
						)
						.shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: -5)
				)
			}
		}
	}

	// MARK: - Helper Methods

	private func initializeView() {
		// Check if there's a previously selected location to restore
		if let existingLocation = viewModel.selectedLocation {
			let coordinate = CLLocationCoordinate2D(
				latitude: existingLocation.latitude,
				longitude: existingLocation.longitude
			)
			if CLLocationCoordinate2DIsValid(coordinate) && coordinate.latitude.isFinite
				&& coordinate.longitude.isFinite
			{
				region = MKCoordinateRegion(
					center: coordinate,
					span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
				)
				locationDisplayText = existingLocation.name
				// If we have a previously selected location, start in map mode
				selectionMode = .map
			}
		}

		// Set up location manager
		if locationManager.authorizationStatus == .authorizedWhenInUse
			|| locationManager.authorizationStatus == .authorizedAlways
		{
			locationManager.startLocationUpdates()
		} else if locationManager.authorizationStatus == .notDetermined {
			locationManager.requestLocationPermission()
		}
	}

	private func cleanupView() {
		locationManager.stopLocationUpdates()
		debounceTimer?.invalidate()
	}

	private func handleUserLocationUpdate(_ location: CLLocationCoordinate2D?) {
		// Only auto-center if we don't have a selected location and we're in search mode
		guard viewModel.selectedLocation == nil,
			selectionMode == .search,
			let location = location,
			!locationManager.locationUpdated,
			CLLocationCoordinate2DIsValid(location),
			location.latitude.isFinite && location.longitude.isFinite
		else { return }

		let newRegion = MKCoordinateRegion(
			center: location,
			span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
		)

		withAnimation(.easeInOut(duration: 0.5)) {
			region = newRegion
		}
	}

	private func getCurrentLocationAddress() -> String {
		// Return a placeholder - in production, you'd reverse geocode the user's location
		return "Your current location"
	}

	private func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
		guard let userLocation = locationManager.userLocation,
			CLLocationCoordinate2DIsValid(userLocation),
			CLLocationCoordinate2DIsValid(coordinate)
		else { return nil }

		let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
		let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
		let distance = userCLLocation.distance(from: targetLocation)

		guard distance.isFinite && !distance.isNaN else { return nil }

		if distance < 1000 {
			return "\(Int(distance))m"
		} else {
			let km = distance / 1000
			return km < 10 ? String(format: "%.1fkm", km) : "\(Int(km))km"
		}
	}

	private func searchLocations() {
		guard !searchText.isEmpty else {
			searchResults = []
			return
		}

		let request = MKLocalSearch.Request()
		request.naturalLanguageQuery = searchText

		if let userLocation = locationManager.userLocation, CLLocationCoordinate2DIsValid(userLocation) {
			request.region = MKCoordinateRegion(
				center: userLocation,
				span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
			)
		}

		let search = MKLocalSearch(request: request)
		search.start { response, error in
			guard let response = response, error == nil else {
				DispatchQueue.main.async { self.searchResults = [] }
				return
			}

			DispatchQueue.main.async {
				let validResults = response.mapItems.filter { CLLocationCoordinate2DIsValid($0.placemark.coordinate) }
				self.searchResults = Array(validResults.prefix(10)).map { SearchResultItem($0) }
			}
		}
	}

	private func selectCurrentLocation() {
		guard let userLocation = locationManager.userLocation,
			CLLocationCoordinate2DIsValid(userLocation)
		else { return }

		let location = LocationDTO(
			id: UUID(),
			name: "Current Location",
			latitude: userLocation.latitude,
			longitude: userLocation.longitude
		)
		viewModel.setLocation(location)
		onNext()
	}

	private func selectSearchResult(_ result: SearchResultItem) {
		let coordinate = result.mapItem.placemark.coordinate
		let name = result.mapItem.placemark.formattedAddress() ?? result.mapItem.name ?? "Selected Location"

		let location = LocationDTO(
			id: UUID(),
			name: name,
			latitude: coordinate.latitude,
			longitude: coordinate.longitude
		)
		viewModel.setLocation(location)
		onNext()
	}

	private func selectPredefinedLocation(_ locationData: LocationData) {
		let location = LocationDTO(
			id: UUID(),
			name: locationData.address,
			latitude: locationData.coordinate.latitude,
			longitude: locationData.coordinate.longitude
		)
		viewModel.setLocation(location)
		onNext()
	}

	private func confirmMapLocation() {
		guard CLLocationCoordinate2DIsValid(region.center) else { return }

		let location = LocationDTO(
			id: UUID(),
			name: locationDisplayText.isEmpty ? "Selected Location" : locationDisplayText,
			latitude: region.center.latitude,
			longitude: region.center.longitude
		)
		viewModel.setLocation(location)
		onNext()
	}

	private func updateLocationText(for coordinate: CLLocationCoordinate2D) {
		debounceTimer?.invalidate()
		debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
			Task { @MainActor in
				self.performReverseGeocoding(for: coordinate)
			}
		}
	}

	private func performReverseGeocoding(for coordinate: CLLocationCoordinate2D) {
		guard !isUpdatingLocation, CLLocationCoordinate2DIsValid(coordinate) else { return }

		isUpdatingLocation = true
		let geocoder = CLGeocoder()
		let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

		geocoder.reverseGeocodeLocation(location) { placemarks, error in
			DispatchQueue.main.async {
				defer { self.isUpdatingLocation = false }

				guard let placemark = placemarks?.first else {
					self.locationDisplayText = String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
					return
				}

				var addressComponents: [String] = []
				if let name = placemark.name, !name.isEmpty {
					addressComponents.append(name)
				}
				if let city = placemark.locality, !city.isEmpty {
					addressComponents.append(city)
				}

				self.locationDisplayText =
					addressComponents.isEmpty
					? String(format: "%.4f, %.4f", coordinate.latitude, coordinate.longitude)
					: addressComponents.joined(separator: ", ")
			}
		}
	}
}

// MARK: - Location List Row Component
struct LocationListRow: View {
	let icon: String
	let iconColor: Color
	let title: String
	let subtitle: String?
	let distance: String?
	var showDivider: Bool = true
	let onTap: () -> Void

	var body: some View {
		Button(action: onTap) {
			VStack(spacing: 0) {
				HStack(alignment: .center, spacing: 16) {
					// Icon with optional distance
					VStack(spacing: 2) {
						Image(systemName: icon)
							.font(.system(size: 16))
							.foregroundColor(iconColor)

						if let distance = distance {
							Text(distance)
								.font(.onestSemiBold(size: 10))
								.foregroundColor(universalSecondaryColor)
						}
					}
					.frame(width: 32)

					// Text content
					VStack(alignment: .leading, spacing: 2) {
						Text(title)
							.font(.onestMedium(size: 16))
							.foregroundColor(universalAccentColor)

						if let subtitle = subtitle, !subtitle.isEmpty {
							Text(subtitle)
								.font(.onestMedium(size: 12))
								.foregroundColor(figmaBlack300)
								.lineLimit(1)
						}
					}

					Spacer()
				}
				.padding(.vertical, 12)

				if showDivider {
					Divider()
						.background(figmaBlack300)
				}
			}
		}
		.buttonStyle(PlainButtonStyle())
	}
}

// MARK: - Extensions

extension MKPlacemark {
	func formattedAddress() -> String? {
		let components = [thoroughfare, locality, administrativeArea, postalCode, country]
		return components.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
	}
}

extension Double {
	func isEqual(to other: Double, tolerance: Double = 0.0001) -> Bool {
		return abs(self - other) < tolerance
	}
}

// MARK: - Preview

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared

	ActivityCreationLocationView(
		onNext: { print("Next step tapped") },
		onBack: { print("Back tapped") }
	)
	.environmentObject(appCache)
}
