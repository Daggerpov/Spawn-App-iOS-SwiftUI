import CoreLocation
import MapKit
import SwiftUI

struct ActivityCreationLocationView: View {
	@ObservedObject var viewModel: ActivityCreationViewModel =
		ActivityCreationViewModel.shared
	@StateObject private var locationManager = LocationManager()
	@State private var region: MKCoordinateRegion = {
		print("🔍 DEBUG: Initializing default region for ActivityCreationLocationView")
		// Create a safe default region with validation
		let defaultCenter = CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207) // Vancouver
		let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
		
		print("🔍 DEBUG: Default center: \(defaultCenter), span: \(defaultSpan)")
		
		// Validate the default values
		guard CLLocationCoordinate2DIsValid(defaultCenter) &&
			  defaultSpan.latitudeDelta > 0 && defaultSpan.longitudeDelta > 0 &&
			  defaultSpan.latitudeDelta.isFinite && defaultSpan.longitudeDelta.isFinite else {
			print("⚠️ ActivityCreationLocationView: Invalid default region, using fallback")
			// Ultra-safe fallback
			return MKCoordinateRegion(
				center: CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
				span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
			)
		}
		
		print("🔍 DEBUG: Using valid default region: \(MKCoordinateRegion(center: defaultCenter, span: defaultSpan))")
		return MKCoordinateRegion(center: defaultCenter, span: defaultSpan)
	}()
	@State private var searchText: String = "6133 University Blvd, Vancouver"
	@State private var showingLocationPicker = false
	@State private var dragOffset: CGFloat = 0
	@State private var isUpdatingLocation = false
	@State private var debounceTimer: Timer?

	// Location error handling
	@State private var showLocationError = false
	
	// Pin overlay reference
	@State private var pinOverlay = LocationSelectionPinOverlay()

	let onNext: () -> Void
	let onBack: (() -> Void)?

	// 3D camera toggle (placeholder for SwiftUI Map). Used to reflect UI state.
	@State private var is3DMode: Bool = false  // Only used on iOS 17+

	var body: some View {
		print("🔍 DEBUG: ActivityCreationLocationView body being rendered")
		print("🔍 DEBUG: Current region: \(region)")
		print("🔍 DEBUG: Current is3DMode: \(is3DMode)")
		print("🔍 DEBUG: Current searchText: \(searchText)")
		
		return ZStack {
			// Location Selection Map View using new refactored components
			LocationSelectionMapView(
				region: $region,
				is3DMode: $is3DMode,
				onMapWillChange: {
					print("🔍 DEBUG: Map will change")
					pinOverlay.startMapMoving()
				},
				onMapDidChange: { coordinate in
					print("🔍 DEBUG: Map did change to coordinate: \(coordinate)")
					pinOverlay.stopMapMoving()
					// Update location text when map moves (for pin drop)
					updateLocationText(for: coordinate)
				}
			)
			.ignoresSafeArea(.all, edges: .top)
		.onReceive(locationManager.$userLocation) { location in
			print(
				"📍 ActivityCreationLocationView: Received user location: \(String(describing: location))"
			)
			print("🔍 DEBUG: locationManager.locationUpdated flag: \(locationManager.locationUpdated)")
			if let location = location, !locationManager.locationUpdated {
				print("🔍 DEBUG: Processing new user location: \(location)")
				// Validate coordinates before creating region to prevent NaN values
				guard CLLocationCoordinate2DIsValid(location) else {
					print(
						"⚠️ ActivityCreationLocationView: Invalid user location received - \(location)"
					)
					return
				}
				
				// Additional validation for finite values
				guard location.latitude.isFinite && location.longitude.isFinite &&
					  !location.latitude.isNaN && !location.longitude.isNaN else {
					print(
						"⚠️ ActivityCreationLocationView: Non-finite user location values - lat: \(location.latitude), lng: \(location.longitude)"
					)
					return
				}

				print(
					"✅ ActivityCreationLocationView: Setting region with valid coordinates - lat: \(location.latitude), lng: \(location.longitude)"
				)

				let newRegion = MKCoordinateRegion(
					center: location,
					span: MKCoordinateSpan(
						latitudeDelta: 0.01,
						longitudeDelta: 0.01
					)
				)
				
				// Validate the new region before setting it
				guard CLLocationCoordinate2DIsValid(newRegion.center) &&
					  newRegion.span.latitudeDelta > 0 && newRegion.span.longitudeDelta > 0 &&
					  newRegion.span.latitudeDelta.isFinite && newRegion.span.longitudeDelta.isFinite else {
					print(
						"⚠️ ActivityCreationLocationView: Invalid new region created - center: \(newRegion.center), span: \(newRegion.span)"
					)
					return
				}

				// Use a safer animation approach for iOS < 17 compatibility
				if #available(iOS 17, *) {
					withAnimation(.easeInOut(duration: 1.0)) {
						region = newRegion
					}
				} else {
					// For iOS < 17, use a simpler animation or no animation
					DispatchQueue.main.async {
						withAnimation(.easeInOut(duration: 0.5)) {
							region = newRegion
						}
					}
				}

				print(
					"✅ ActivityCreationLocationView: Region updated successfully"
				)
			}
		}
		.onReceive(locationManager.$locationError) { error in
			if let error = error {
				print(
					"Location error in ActivityCreationLocationView: \(error)"
				)
				showLocationError = true
			}
		}

		// Pin overlay in center of map
		pinOverlay

		// Top navigation - back button aligned to safe area like other creation pages
		VStack {
			HStack {
				Button(action: {
					onBack?()
				}) {
					Image(systemName: "chevron.left")
						.font(.system(size: 24, weight: .bold))
						.foregroundColor(
							Color(red: 0.56, green: 0.52, blue: 0.52)
						)
				}
				.frame(width: 48, height: 48)
				.background(.white)
				.cornerRadius(100)
				.shadow(
					color: Color(red: 0, green: 0, blue: 0, opacity: 0.25),
					radius: 8,
					y: 2
				)
				.padding(.leading, 24)

				Spacer()

				// Removed floating label

				Spacer()
			}
			.padding(.top, 24)
			.padding(.bottom, 12)

			Spacer()
		}

		// Top-right controls: 3D toggle and recenter buttons
		LocationSelectionMapControls(
			is3DMode: $is3DMode,
			userLocation: locationManager.userLocation,
			onRecenterTapped: {
				if let userLocation = locationManager.userLocation {
					// Validate user location before using it
					guard MapValidationUtils.validateCoordinate(userLocation) else {
						print("⚠️ ActivityCreationLocationView: Invalid user location for recenter - \(userLocation)")
						return
					}
					
					if let newRegion = MapValidationUtils.createSafeRegion(
						center: userLocation,
						span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
					) {
						withAnimation(.easeInOut(duration: 0.75)) {
							region = newRegion
						}
					} else {
						print("⚠️ ActivityCreationLocationView: Failed to create safe region for recenter")
					}
				}
			},
			on3DToggled: {
				print("🔍 DEBUG: 3D mode toggled to: \(is3DMode)")
			}
		)

		// Bottom sheet
		VStack {
			Spacer()

			VStack(spacing: 0) {
				// Handle bar
				RoundedRectangle(cornerRadius: 2.5)
					.fill(Color.gray.opacity(0.4))
					.frame(width: 40, height: 5)
					.padding(.top, 12)
					.padding(.bottom, 20)

				VStack(spacing: 16) {
					// Title and instruction
					VStack(spacing: 6) {
						Text("Set Location")
							.font(.title2)
							.fontWeight(.semibold)
							.foregroundColor(universalAccentColor)

						Text("Drag map to move pin")
							.font(.subheadline)
							.foregroundColor(figmaBlack300)
					}

					// Address field
					HStack {
						TextField(
							"6133 University Blvd, Vancouver",
							text: $searchText
						)
						.font(.body)
						.foregroundColor(universalAccentColor)
						.padding(.vertical, 12)
						.padding(.horizontal, 16)
						.background(Color.gray.opacity(0.1))
						.clipShape(RoundedRectangle(cornerRadius: 12))

						Button(action: {
							showingLocationPicker = true
						}) {
							Image(systemName: "magnifyingglass")
								.foregroundColor(figmaBlack300)
								.padding(12)
								.background(Color.gray.opacity(0.1))
								.clipShape(Circle())
						}
					}

					// Step indicators
					StepIndicatorView(currentStep: 2, totalSteps: 3)
						.padding(.bottom, 8)  // Standard bottom padding

					// Confirm button
					ActivityNextStepButton(
						title: "Confirm Location"
					) {

						guard MapValidationUtils.validateCoordinate(region.center)
						else {
							print(
								"⚠️ Confirm Location: Invalid region center coordinates - \(region.center)"
							)
							return
						}

						// Set the location in the view model based on current pin position
						let location = LocationDTO(
							id: UUID(),
							name: searchText.isEmpty
							? "Selected Location" : searchText,
							latitude: region.center.latitude,
							longitude: region.center.longitude
						)
						viewModel.setLocation(location)
						onNext()
					}
				}
				.padding(.horizontal, 20)
			}
			.background(
				universalBackgroundColor
					.clipShape(
						TopRoundedRectangle(radius: 20)
					)
					.shadow(
						color: Color.black.opacity(0.1),
						radius: 10,
						x: 0,
						y: -5
					)
			)
			.offset(y: dragOffset)
			.gesture(
				DragGesture()
					.onChanged { value in
						let translation = value.translation.height
						if translation < 0 {
							// Dragging up
							dragOffset = translation * 0.3
						} else {
							// Dragging down
							dragOffset = translation * 0.1
						}
					}
					.onEnded { value in
						let translation = value.translation.height
						let velocity = value.velocity.height

						withAnimation(
							.spring(response: 0.6, dampingFraction: 0.8)
						) {
							if translation < -100 || velocity < -500 {
								// Dragged up enough or fast enough - show location picker
								showingLocationPicker = true
							}
							dragOffset = 0
						}
					}
			)
		}
		} // End of main ZStack
		.background(universalBackgroundColor)
		.sheet(isPresented: $showingLocationPicker) {
			LocationPickerView(
				userLocation: locationManager.userLocation,
				onLocationSelected: { locationName in
					searchText = locationName
					showingLocationPicker = false
				}
			)
		}
		.onReceive(
			NotificationCenter.default.publisher(
				for: UIApplication.willEnterForegroundNotification
			)
		) { _ in
			print(
				"📍 ActivityCreationLocationView: App entering foreground, checking location services..."
			)
			// Update region when app becomes active
			if let userLocation = locationManager.userLocation {
				// Enhanced validation for iOS < 17 compatibility
				guard MapValidationUtils.validateCoordinate(userLocation) else {
					print(
						"⚠️ ActivityCreationLocationView: Invalid user location on foreground - \(userLocation)"
					)
					return
				}

				if let newRegion = MapValidationUtils.createSafeRegion(
					center: userLocation,
					span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
				) {
					region = newRegion
				} else {
					print("⚠️ ActivityCreationLocationView: Failed to create safe region on foreground")
				}
			}

			// Re-request location when app returns to foreground
			if locationManager.authorizationStatus == .authorizedWhenInUse
				|| locationManager.authorizationStatus == .authorizedAlways
			{
				print(
					"📍 ActivityCreationLocationView: Restarting location updates after app foreground..."
				)
				locationManager.startLocationUpdates()
			} else {
				print(
					"⚠️ ActivityCreationLocationView: Location permission not granted when app entered foreground"
				)
			}
		}
		.onAppear {
			print(
				"📍 ActivityCreationLocationView: View appeared, checking location manager state..."
			)
			print(
				"📍 Current authorization status: \(locationManager.authorizationStatus.rawValue)"
			)
			print(
				"📍 Current user location: \(String(describing: locationManager.userLocation))"
			)
			print("📍 Location updated flag: \(locationManager.locationUpdated)")
			print("🔍 DEBUG: Current region at onAppear: \(region)")
			print("🔍 DEBUG: Current viewModel state: \(viewModel)")

			// Ensure location manager is properly set up when view appears
			if locationManager.authorizationStatus == .authorizedWhenInUse
				|| locationManager.authorizationStatus == .authorizedAlways
			{
				print("🔍 DEBUG: Starting location updates (authorized)")
				locationManager.startLocationUpdates()
			} else if locationManager.authorizationStatus == .notDetermined {
				print("🔍 DEBUG: Requesting location permission (not determined)")
				locationManager.requestLocationPermission()
			} else {
				print("🔍 DEBUG: Location authorization denied or restricted: \(locationManager.authorizationStatus.rawValue)")
			}
		}
		.onDisappear {
			print(
				"📍 ActivityCreationLocationView: View disappeared, stopping location updates..."
			)
			locationManager.stopLocationUpdates()
			// Clean up timers
			debounceTimer?.invalidate()
		}
		// Removed onChange(of: region) to prevent iOS < 17 compatibility issues
		.alert("Location Error", isPresented: $showLocationError) {
			Button("OK") {
				showLocationError = false
			}
			if locationManager.authorizationStatus == .denied {
				Button("Settings") {
					if let settingsUrl = URL(
						string: UIApplication.openSettingsURLString
					) {
						UIApplication.shared.open(settingsUrl)
					}
				}
			}
		} message: {
			Text(
				locationManager.locationError
				?? "An unknown location error occurred."
			)
		}
	}
	
	// MARK: - Private Functions
	
	// Function to update location text based on coordinates
	private func updateLocationText(for coordinate: CLLocationCoordinate2D) {
		// Cancel any existing timer
		debounceTimer?.invalidate()

		// Create a new timer with a delay to debounce the calls
		debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false)
		{ _ in
			DispatchQueue.main.async {
				self.performReverseGeocoding(for: coordinate)
			}
		}
	}

	// Function to perform the actual reverse geocoding
	private func performReverseGeocoding(for coordinate: CLLocationCoordinate2D) {
		// Prevent multiple simultaneous updates
		guard !isUpdatingLocation else {
			print(
				"📍 performReverseGeocoding: Already updating location, skipping..."
			)
			return
		}

		// Validate coordinates before reverse geocoding to prevent NaN values
		guard MapValidationUtils.validateCoordinate(coordinate) else {
			print("⚠️ performReverseGeocoding: Invalid coordinates - \(coordinate)")
			return
		}

		print(
			"📍 performReverseGeocoding: Starting reverse geocoding for \(coordinate)"
		)
		isUpdatingLocation = true

		let geocoder = CLGeocoder()
		let location = CLLocation(
			latitude: coordinate.latitude,
			longitude: coordinate.longitude
		)

		geocoder.reverseGeocodeLocation(location) { placemarks, error in
			DispatchQueue.main.async {
				defer {
					self.isUpdatingLocation = false
					print("📍 performReverseGeocoding: Finished reverse geocoding")
				}

				if let error = error {
					print(
						"⚠️ Reverse geocoding error: \(error.localizedDescription)"
					)
					// Don't return here - we might still want to show a default location
					if error.localizedDescription.contains("network")
						|| error.localizedDescription.contains("Network")
					{
						print(
							"📍 Network error during geocoding, keeping existing address"
						)
						return
					}
				}

				guard let placemark = placemarks?.first else {
					print("⚠️ No placemark found for coordinates \(coordinate)")
					// Set a generic location name based on coordinates
					self.searchText = String(
						format: "%.4f, %.4f",
						coordinate.latitude,
						coordinate.longitude
					)
					return
				}

				print("📍 Found placemark: \(placemark)")

				// Create a formatted address string with more robust handling
				var addressComponents: [String] = []

				// Try different combinations for the best address format
				if let name = placemark.name, !name.isEmpty {
					// If we have a specific place name, use it
					addressComponents.append(name)
				} else {
					// Build address from components
					if let streetNumber = placemark.subThoroughfare,
					   !streetNumber.isEmpty
					{
						addressComponents.append(streetNumber)
					}

					if let street = placemark.thoroughfare, !street.isEmpty {
						addressComponents.append(street)
					}
				}

				if let city = placemark.locality, !city.isEmpty {
					addressComponents.append(city)
				}

				if let state = placemark.administrativeArea, !state.isEmpty {
					addressComponents.append(state)
				}

				// Fallback to postal code if we don't have much else
				if addressComponents.isEmpty, let postalCode = placemark.postalCode,
				   !postalCode.isEmpty
				{
					addressComponents.append(postalCode)
				}

				let formattedAddress = addressComponents.joined(separator: ", ")

				// Update search text if we have a valid address, otherwise use coordinates
				if !formattedAddress.isEmpty {
					print("📍 Setting formatted address: \(formattedAddress)")
					self.searchText = formattedAddress
				} else {
					print("📍 No formatted address available, using coordinates")
					self.searchText = String(
						format: "%.4f, %.4f",
						coordinate.latitude,
						coordinate.longitude
					)
				}
			}
		}
	}
}

struct SearchResultItem: Identifiable {
	let id = UUID()
	let mapItem: MKMapItem

	init(_ mapItem: MKMapItem) {
		self.mapItem = mapItem
	}
}

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
						.onChange(of: searchText) { _ in
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
			guard MapValidationUtils.validateCoordinate(userLocation) else {
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
							let isValid = MapValidationUtils.validateCoordinate(
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
					let isValid = MapValidationUtils.validateCoordinate(item.placemark.coordinate)
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
			MapValidationUtils.validateCoordinate(userLocation)
				&& MapValidationUtils.validateCoordinate(coordinate)
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

struct LocationRowView: View {
	let icon: String
	let iconColor: Color
	let title: String
	let subtitle: String?
	let distance: String?
	let action: () -> Void

	var body: some View {
		Button(action: action) {
			HStack(spacing: 12) {
				Image(systemName: icon)
					.foregroundColor(iconColor)
					.font(.system(size: 16))
					.frame(width: 20)

				VStack(alignment: .leading, spacing: 2) {
					HStack {
						Text(title)
							.foregroundColor(universalAccentColor)
							.font(.system(size: 16, weight: .medium))

						Spacer()

						if let distance = distance {
							Text(distance)
								.foregroundColor(figmaBlack300)
								.font(.system(size: 14))
						}
					}

					if let subtitle = subtitle, !subtitle.isEmpty {
						Text(subtitle)
							.font(.system(size: 14))
							.foregroundColor(figmaBlack300)
							.multilineTextAlignment(.leading)
					}
				}

				Spacer()
			}
			.padding(.vertical, 8)
			.contentShape(Rectangle())
		}
		.buttonStyle(PlainButtonStyle())
	}
}

struct LocationData {
	let name: String
	let address: String
	let coordinate: CLLocationCoordinate2D
}

// Custom shape for top-rounded rectangles (iOS < 16 compatibility)
struct TopRoundedRectangle: Shape {
	let radius: CGFloat

	func path(in rect: CGRect) -> Path {
		var path = Path()

		path.move(to: CGPoint(x: 0, y: rect.maxY))
		path.addLine(to: CGPoint(x: 0, y: radius))
		path.addArc(
			center: CGPoint(x: radius, y: radius),
			radius: radius,
			startAngle: .radians(.pi),
			endAngle: .radians(.pi * 1.5),
			clockwise: false
		)
		path.addLine(to: CGPoint(x: rect.maxX - radius, y: 0))
		path.addArc(
			center: CGPoint(x: rect.maxX - radius, y: radius),
			radius: radius,
			startAngle: .radians(.pi * 1.5),
			endAngle: .radians(0),
			clockwise: false
		)
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
		path.closeSubpath()

		return path
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
			country,
		]
		return
			components
			.compactMap { $0 }
			.filter { !$0.isEmpty }
			.joined(separator: ", ")
	}
}

// Double extension for floating point comparison
extension Double {
	func isEqual(to other: Double, tolerance: Double = 0.0001) -> Bool {
		return abs(self - other) < tolerance
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared

	ActivityCreationLocationView(
		onNext: {
			print("Next step tapped")
		},
		onBack: {
			print("Back tapped")
		}
	)
	.environmentObject(appCache)
}
