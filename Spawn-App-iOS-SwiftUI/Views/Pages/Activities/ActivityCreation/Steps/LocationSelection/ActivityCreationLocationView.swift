import CoreLocation
import MapKit
import SwiftUI

// Uses UnifiedMapViewRepresentable from Views/Components/UnifiedMapView.swift

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

	// Pin animation states
	@State private var baseEllipseScale: CGFloat = 1.0
	@State private var pulseScale: CGFloat = 1.0
	@State private var pulseOpacity: Double = 0.0
	@State private var pinOffset: CGFloat = 0
	@State private var pinScale: CGFloat = 1.0
	@State private var isMapMoving = false
	@State private var mapMovementTimer: Timer?

	// Location error handling
	@State private var showLocationError = false

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
			// Unified Map View using the same component as MapView (works on all iOS versions)
			UnifiedMapViewRepresentable(
				region: $region,
				is3DMode: $is3DMode,
				showsUserLocation: true,
				annotationItems: [],  // No activities to show in location selection mode
				isLocationSelectionMode: true,
				onMapWillChange: nil,
				onMapDidChange: { coordinate in
					print("🔍 DEBUG: Map did change to coordinate: \(coordinate)")
					// Update location text when map moves (for pin drop)
					updateLocationText(for: coordinate)
				},
				onActivityTap: { _ in 
					print("🔍 DEBUG: Activity tap received (should not happen in location selection mode)")
				}  // No activity taps in location selection mode
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

		// Pin in center of map
		VStack {
			Spacer()
			ZStack {
				// Base ellipse under the pin
				Ellipse()
					.fill(Color(red: 0.15, green: 0.55, blue: 1))
					.frame(width: 19.90, height: 9.95)
					.scaleEffect(baseEllipseScale)
					.opacity(0.9)
					.shadow(
						color: Color.black.opacity(0.25),
						radius: 12,
						x: 0,
						y: 3
					)
					.offset(y: 18)
					.animation(
						.spring(response: 0.35, dampingFraction: 0.85),
						value: baseEllipseScale
					)
				// Expanding pulse when dropped
				Ellipse()
					.fill(Color(red: 0.15, green: 0.55, blue: 1))
					.frame(width: 19.90, height: 9.95)
					.scaleEffect(pulseScale)
					.opacity(pulseOpacity)
					.offset(y: 18)

				// Pin icon
				Image(systemName: "mappin")
					.font(.system(size: 34))
					.foregroundColor(.blue)
					.scaleEffect(pinScale)
					.offset(y: pinOffset)
					.shadow(
						color: .black.opacity(isMapMoving ? 0.35 : 0.25),
						radius: isMapMoving ? 8 : 6,
						x: 0,
						y: isMapMoving ? 6 : 3
					)
					.animation(
						.spring(response: 0.25, dampingFraction: 0.8),
						value: isMapMoving
					)
					.animation(
						.spring(response: 0.25, dampingFraction: 0.8),
						value: pinOffset
					)
					.animation(
						.spring(response: 0.25, dampingFraction: 0.8),
						value: pinScale
					)
			}
			Spacer()
		}
		.allowsHitTesting(false)  // Prevent pin from blocking gestures

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
		VStack {
			HStack {
				Spacer()
				VStack(spacing: 0) {
					// 3D mode toggle (works on iOS 9+ with MapKit camera)
					Button(action: {
                                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                impactGenerator.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    is3DMode.toggle()
                                }
                            }) {
                                Text("3D")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 44, height: 44)
                                    .background(universalBackgroundColor)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 10,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 10
                                        )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())

					// Recenter to user location
					Button(action: {
						let impactGenerator = UIImpactFeedbackGenerator(
							style: .medium
						)
						impactGenerator.impactOccurred()

						if let userLocation = locationManager.userLocation {
							// Validate user location before using it
							guard CLLocationCoordinate2DIsValid(userLocation) &&
								  userLocation.latitude.isFinite && userLocation.longitude.isFinite &&
								  !userLocation.latitude.isNaN && !userLocation.longitude.isNaN else {
								print(
									"⚠️ ActivityCreationLocationView: Invalid user location for recenter - \(userLocation)"
								)
								return
							}
							
							let newRegion = MKCoordinateRegion(
								center: userLocation,
								span: MKCoordinateSpan(
									latitudeDelta: 0.01,
									longitudeDelta: 0.01
								)
							)
							
							// Validate the new region
							guard CLLocationCoordinate2DIsValid(newRegion.center) &&
								  newRegion.span.latitudeDelta > 0 && newRegion.span.longitudeDelta > 0 &&
								  newRegion.span.latitudeDelta.isFinite && newRegion.span.longitudeDelta.isFinite else {
								print(
									"⚠️ ActivityCreationLocationView: Invalid region for recenter"
								)
								return
							}
							
							withAnimation(.easeInOut(duration: 0.75)) {
								region = newRegion
							}
						}
					}) {
						Image(systemName: "location.fill")
							.font(.system(size: 20))
							.foregroundColor(universalAccentColor)
							.frame(width: 44, height: 44)
                                .background(universalBackgroundColor)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 10,
                                        bottomTrailingRadius: 10,
                                        topTrailingRadius: 0
                                    )
                                )
					}
					.buttonStyle(PlainButtonStyle())
				}
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
				.padding(.trailing, 16)
			}
			.padding(.top, 24)
			Spacer()
		}

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
							.font(.onestSemiBold(size: 20))
							.foregroundColor(universalAccentColor)

						Text("Drag map to move pin")
							.font(.onestMedium(size: 16))
							.foregroundColor(figmaBlack300)
					}

					// Address field
					HStack {
						TextField("6133 University Blvd, Vancouver", text: $searchText)
                                .font(.onestMedium(size: 16))
                                .padding(.horizontal, 12)
                                .foregroundColor(universalAccentColor)
                                .background(Color.clear)

						Button(action: {
							showingLocationPicker = true
						}) {
							Image(systemName: "magnifyingglass")
								 .foregroundColor(universalAccentColor)
                                    .padding(12)
                                    .background(Color.clear)
						}
					}
                    .background(Color.clear)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: colorsGray700), lineWidth: 1)
                        )
				
					// Confirm button
					ActivityNextStepButton(
						title: "Confirm Location"
					) {

						guard CLLocationCoordinate2DIsValid(region.center)
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
                        // Step indicators
                        StepIndicatorView(currentStep: 2, totalSteps: 3)
                            .padding(.bottom, 8) // Standard bottom padding
        
                
				}
			}
            .padding(.horizontal, 25)
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
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
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
				guard CLLocationCoordinate2DIsValid(userLocation) &&
					  userLocation.latitude.isFinite && userLocation.longitude.isFinite &&
					  !userLocation.latitude.isNaN && !userLocation.longitude.isNaN else {
					print(
						"⚠️ ActivityCreationLocationView: Invalid user location on foreground - \(userLocation)"
					)
					return
				}

				let newRegion = MKCoordinateRegion(
					center: userLocation,
					span: MKCoordinateSpan(
						latitudeDelta: 0.01,
						longitudeDelta: 0.01
					)
				)
				
				// Validate the new region before setting
				guard CLLocationCoordinate2DIsValid(newRegion.center) &&
					  newRegion.span.latitudeDelta > 0 && newRegion.span.longitudeDelta > 0 &&
					  newRegion.span.latitudeDelta.isFinite && newRegion.span.longitudeDelta.isFinite else {
					print(
						"⚠️ ActivityCreationLocationView: Invalid region created on foreground"
					)
					return
				}

				region = newRegion
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
			mapMovementTimer?.invalidate()
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
		guard CLLocationCoordinate2DIsValid(coordinate) else {
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

// MARK: - Supporting Views
// All supporting view structs have been moved to separate files in ActivityCreationLocationView/

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

// MARK: - Unified Map View now in Views/Components/UnifiedMapView.swift

// Double extension for floating point comparison
extension Double {
	func isEqual(to other: Double, tolerance: Double = 0.0001) -> Bool {
		return abs(self - other) < tolerance
	}
}

@available(iOS 17, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared

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
