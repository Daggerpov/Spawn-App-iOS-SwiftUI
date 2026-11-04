//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Rebuilt from scratch for better stability and performance
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: View {
	// MARK: - Properties
	var viewModel: FeedViewModel
	@ObservedObject private var locationManager = LocationManager.shared

	let user: BaseUserDTO

	// MARK: - State
	@State private var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(
			latitude: defaultMapLatitude,
			longitude: defaultMapLongitude
		),
		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
	)

	@State private var is3DMode: Bool = false
	@State private var showFilterOverlay: Bool = false
	@State private var selectedTimeFilter: MapFilterOverlay.TimeFilter =
		.allActivities
	@State private var filteredActivities: [FullFeedActivityDTO] = []
	@State private var isMapLoaded = false
	@State private var hasInitialized = false
	@State private var hasCenteredOnUser = false
	@State private var hasFitActivities = false
	@State private var mapInitializationTask: Task<Void, Never>?
	@State private var viewLifecycleState: ViewLifecycleState = .notAppeared

	enum ViewLifecycleState {
		case notAppeared
		case appearing
		case appeared
		case disappearing
	}

	/// Checks if view is in a valid state for updates
	private var shouldProcessUpdates: Bool {
		return viewLifecycleState == .appeared
	}

	// MARK: - Initialization

	init(user: BaseUserDTO, viewModel: FeedViewModel) {
		self.user = user
		self.viewModel = viewModel
	}

	// MARK: - Body

	var body: some View {
		ZStack {
			// Map Layer
			UnifiedMapView(
				region: $region,
				is3DMode: $is3DMode,
				showsUserLocation: true,
				annotationItems: filteredActivities,
				isLocationSelectionMode: false,
				overlayInsets: Self.overlayInsets,
				onMapWillChange: nil,
				onMapDidChange: nil,
				onActivityTap: handleActivityTap,
				onMapLoaded: handleMapLoaded
			)
			.ignoresSafeArea()

			// Control Buttons Overlay
			MapControlButtons(
				is3DMode: $is3DMode,
				region: $region,
				locationManager: locationManager
			)

			// Filter Overlay
			MapFilterOverlay(
				showFilterOverlay: $showFilterOverlay,
				selectedTimeFilter: $selectedTimeFilter
			)

			// Loading Indicator
			if !isMapLoaded {
				ZStack {
					Color.black.opacity(0.3)
						.ignoresSafeArea()

					ProgressView()
						.progressViewStyle(
							CircularProgressViewStyle(tint: .white)
						)
						.scaleEffect(1.5)
				}
			}
		}
		.onAppear {
			handleViewAppeared()
		}
		.onDisappear {
			handleViewDisappeared()
		}
		.onChange(of: viewModel.activities) { _, _ in
			guard shouldProcessUpdates else {
				return
			}
			updateFilteredActivities()

			// Activities can load after the map first centers; bring them into view once when they do
			let center = locationManager.userLocation ?? region.center
			if !hasFitActivities && !nearbyActivityCoordinates(around: center).isEmpty {
				withAnimation {
					fitRegion(around: center)
				}
			}
		}
		.onChange(of: selectedTimeFilter) { _, _ in
			guard shouldProcessUpdates else {
				return
			}
			updateFilteredActivities()
		}
		.onChange(of: locationManager.locationUpdated) { _, _ in
			guard shouldProcessUpdates else {
				return
			}
			handleUserLocationUpdate()
		}
	}

	// MARK: - Constants

	/// Maximum reasonable span for the map (anything larger is likely a bug)
	private static let maxReasonableSpan: Double = 0.5
	/// Default span for user-centered view
	private static let defaultSpan: Double = 0.01
	/// Activities farther than this are left out of the initial fit so the map stays zoomed in
	private static let maxFitDistance: CLLocationDistance = 3_000
	/// Room around the fitted pins so they don't sit on the edge of the visible map
	private static let fitPaddingFactor: Double = 1.5
	/// Space the floating UI takes over the map, from the safe area. The top clears the 3D and
	/// location buttons; the bottom clears the tab bar and lines the Maps logo up with the filter button.
	private static let overlayInsets = UIEdgeInsets(top: 120, left: 16, bottom: 80, right: 16)

	// MARK: - Lifecycle Methods

	private func handleViewAppeared() {
		guard viewLifecycleState != .appeared else {
			return
		}

		viewLifecycleState = .appearing

		// CRITICAL: Reset map loaded state on each appearance
		// This ensures tiles reload if they failed previously
		isMapLoaded = false

		// Initialize filtered activities
		updateFilteredActivities()

		// Set initial region (only once per view lifetime)
		if !hasInitialized {
			setInitialRegion()
			hasInitialized = true
		} else {
			// On subsequent appearances, check if region is unreasonably zoomed out
			// This can happen due to MKMapView state issues during tab switching
			let isZoomedOutTooFar =
				region.span.latitudeDelta > Self.maxReasonableSpan
				|| region.span.longitudeDelta > Self.maxReasonableSpan

			if isZoomedOutTooFar, let userLocation = locationManager.userLocation {
				print(
					"⚠️ MapView: Detected unreasonable zoom level (span: \(region.span.latitudeDelta)), re-centering on user"
				)
				withAnimation {
					region = MKCoordinateRegion(
						center: userLocation,
						span: MKCoordinateSpan(
							latitudeDelta: Self.defaultSpan,
							longitudeDelta: Self.defaultSpan
						)
					)
				}
			} else if !hasCenteredOnUser, let userLocation = locationManager.userLocation {
				// Handle case where view reappears after location became available
				withAnimation {
					fitRegion(around: userLocation)
				}
				hasCenteredOnUser = true
				print("📍 MapView: Centered on user location (on reappear)")
			}
		}

		// Start location updates
		if locationManager.authorizationStatus == .authorizedWhenInUse
			|| locationManager.authorizationStatus == .authorizedAlways
		{
			locationManager.startLocationUpdates()
		}

		// NEW: Safety timeout that respects lifecycle
		mapInitializationTask = Task { @MainActor in
			do {
				// Check cancellation before sleep
				guard !Task.isCancelled else {
					return
				}

				try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds

				// Check cancellation after sleep
				guard !Task.isCancelled else {
					return
				}

				// Only update if still in appeared state AND not cancelled
				if viewLifecycleState == .appeared && !isMapLoaded && !Task.isCancelled {
					print("⚠️ Map loading timeout - dismissing loading indicator")
					isMapLoaded = true
				}
			} catch {
				// Task was cancelled - this is expected during navigation
			}
		}

		viewLifecycleState = .appeared
	}

	private func handleViewDisappeared() {
		guard viewLifecycleState == .appeared else {
			return
		}

		viewLifecycleState = .disappearing

		locationManager.stopLocationUpdates()

		// Cancel any pending map initialization
		mapInitializationTask?.cancel()
		mapInitializationTask = nil
	}

	private func handleMapLoaded() {
		isMapLoaded = true
	}

	// MARK: - Region Management

	private func setInitialRegion() {
		// Priority 1: User location
		if let userLocation = locationManager.userLocation {
			fitRegion(around: userLocation)
			hasCenteredOnUser = true
			print(
				"📍 MapView: Set initial region to user location (\(userLocation.latitude), \(userLocation.longitude))")
			return
		}

		// Priority 2: Default location - wait for user location rather than zooming out to all activities.
		// Only activities near the default location are fit, so the map stays zoomed in
		fitRegion(around: region.center)
		print(
			"📍 MapView: Using default region (user location not yet available, authorization: \(locationManager.authorizationStatus.rawValue))"
		)
	}

	private func handleUserLocationUpdate() {
		// Auto-center on user location if we haven't done so yet
		guard let userLocation = locationManager.userLocation else { return }
		guard !hasCenteredOnUser else { return }

		withAnimation {
			fitRegion(around: userLocation)
		}
		hasCenteredOnUser = true
		print("📍 Auto-centered to user location")
	}

	/// Shows `center` together with the activity pins near it, never tighter than the default span
	private func fitRegion(around center: CLLocationCoordinate2D) {
		let nearbyCoordinates = nearbyActivityCoordinates(around: center)
		let coordinates = [center] + nearbyCoordinates
		let latitudes = coordinates.map(\.latitude)
		let longitudes = coordinates.map(\.longitude)
		let minLatitude = latitudes.min() ?? center.latitude
		let maxLatitude = latitudes.max() ?? center.latitude
		let minLongitude = longitudes.min() ?? center.longitude
		let maxLongitude = longitudes.max() ?? center.longitude

		region = MKCoordinateRegion(
			center: CLLocationCoordinate2D(
				latitude: (minLatitude + maxLatitude) / 2,
				longitude: (minLongitude + maxLongitude) / 2
			),
			span: MKCoordinateSpan(
				latitudeDelta: max(Self.defaultSpan, (maxLatitude - minLatitude) * Self.fitPaddingFactor),
				longitudeDelta: max(Self.defaultSpan, (maxLongitude - minLongitude) * Self.fitPaddingFactor)
			)
		)
		hasFitActivities = !nearbyCoordinates.isEmpty
	}

	/// Coordinates of the shown activities within `maxFitDistance` of `center`
	private func nearbyActivityCoordinates(around center: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
		let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
		return filteredActivities.compactMap { activity in
			guard let location = activity.location else { return nil }
			let activityLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
			guard activityLocation.distance(from: centerLocation) <= Self.maxFitDistance else { return nil }
			return activityLocation.coordinate
		}
	}

	// MARK: - Activity Filtering

	private func updateFilteredActivities() {
		let now = Date()
		let calendar = Calendar.current

		let filtered = viewModel.activities.filter { activity in
			// Must have a location to show on map
			guard activity.location != nil else { return false }
			guard let startTime = activity.startTime else { return false }

			switch selectedTimeFilter {
			case .allActivities:
				return true

			case .happeningNow:
				guard let endTime = activity.endTime else { return false }
				return startTime <= now && endTime >= now

			case .inTheNextHour:
				let oneHourFromNow =
					calendar.date(byAdding: .hour, value: 1, to: now) ?? now
				return startTime > now && startTime <= oneHourFromNow

			case .afternoon:
				guard calendar.isDate(startTime, inSameDayAs: now) else {
					return false
				}
				let hour = calendar.component(.hour, from: startTime)
				return hour >= 12 && hour < 17

			case .evening:
				guard calendar.isDate(startTime, inSameDayAs: now) else {
					return false
				}
				let hour = calendar.component(.hour, from: startTime)
				return hour >= 17 && hour < 21

			case .lateNight:
				guard calendar.isDate(startTime, inSameDayAs: now) else {
					return false
				}
				let hour = calendar.component(.hour, from: startTime)
				return hour >= 21 || hour < 4
			}
		}

		filteredActivities = filtered
		print(
			"🔍 Filtered activities: \(filtered.count) of \(viewModel.activities.count)"
		)
	}

	// MARK: - Activity Interaction

	private func handleActivityTap(_ activity: FullFeedActivityDTO) {
		NotificationCenter.default.post(
			name: .showGlobalActivityPopup,
			object: nil,
			userInfo: [
				"activity": activity,
				"color": ActivityColorService.shared.getColorForActivity(
					activity.id
				),
				"fromMapView": true,
			]
		)
	}
}

// MARK: - Preview

@available(iOS 17.0, *)
#Preview {
	let previewViewModel = FeedViewModel(
		userId: BaseUserDTO.danielAgapov.id
	)
	MapView(user: .danielAgapov, viewModel: previewViewModel)
}
