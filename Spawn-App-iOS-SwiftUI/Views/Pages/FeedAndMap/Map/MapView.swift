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
	@ObservedObject var viewModel: FeedViewModel
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
				print("🗺️ MapView: Ignoring activity update - view not appeared")
				return
			}
			updateFilteredActivities()
		}
		.onChange(of: selectedTimeFilter) { _, _ in
			guard shouldProcessUpdates else {
				print("🗺️ MapView: Ignoring filter update - view not appeared")
				return
			}
			updateFilteredActivities()
		}
		.onChange(of: locationManager.locationUpdated) { _, _ in
			guard shouldProcessUpdates else {
				print("🗺️ MapView: Ignoring location update - view not appeared")
				return
			}
			handleUserLocationUpdate()
		}
	}

	// MARK: - Lifecycle Methods

	private func handleViewAppeared() {
		guard viewLifecycleState != .appeared else {
			print("🗺️ MapView: Ignoring duplicate onAppear")
			return
		}
		
		viewLifecycleState = .appearing
		print("🗺️ MapView appeared")
		
		// CRITICAL: Reset map loaded state on each appearance
		// This ensures tiles reload if they failed previously
		isMapLoaded = false
		print("🗺️ MapView: Reset isMapLoaded to force tile loading")

		// Initialize filtered activities
		updateFilteredActivities()

		// Set initial region (only once per view lifetime)
		if !hasInitialized {
			setInitialRegion()
			hasInitialized = true
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
					print("🗺️ Map initialization cancelled before timeout")
					return
				}
				
				try await Task.sleep(nanoseconds: 3_000_000_000)  // 3 seconds
				
				// Check cancellation after sleep
				guard !Task.isCancelled else {
					print("🗺️ Map initialization cancelled after timeout")
					return
				}
				
				// Only update if still in appeared state AND not cancelled
				if viewLifecycleState == .appeared && !isMapLoaded && !Task.isCancelled {
					print("⚠️ Map loading timeout - dismissing loading indicator")
					isMapLoaded = true
				}
			} catch {
				// Task was cancelled - this is expected during navigation
				print("🗺️ Map initialization task cancelled (expected)")
			}
		}
		
		viewLifecycleState = .appeared
	}

	private func handleViewDisappeared() {
		guard viewLifecycleState == .appeared else {
			print("🗺️ MapView: Ignoring disappear when not appeared")
			return
		}
		
		viewLifecycleState = .disappearing
		print("🗺️ MapView disappeared")
		
		locationManager.stopLocationUpdates()
		
		// Cancel any pending map initialization
		mapInitializationTask?.cancel()
		mapInitializationTask = nil
	}

	private func handleMapLoaded() {
		print("✅ Map loaded successfully")
		isMapLoaded = true
	}

	// MARK: - Region Management

	private func setInitialRegion() {
		// Priority 1: User location
		if let userLocation = locationManager.userLocation {
			region = MKCoordinateRegion(
				center: userLocation,
				span: MKCoordinateSpan(
					latitudeDelta: 0.01,
					longitudeDelta: 0.01
				)
			)
			print("📍 MapView: Set initial region to user location (\(userLocation.latitude), \(userLocation.longitude))")
			return
		}

		// Priority 2: Activities location
		if !viewModel.activities.isEmpty {
			fitRegionToActivities()
			print("📍 MapView: Set initial region to fit activities")
			return
		}

		// Priority 3: Default location (already set in @State)
		print("📍 MapView: Using default region (user location not yet available, authorization: \(locationManager.authorizationStatus.rawValue))")
	}

	private func handleUserLocationUpdate() {
		// Only auto-center if still at default location
		guard let userLocation = locationManager.userLocation else { return }

		let isStillAtDefault =
			abs(region.center.latitude - defaultMapLatitude) < 0.001
			&& abs(region.center.longitude - defaultMapLongitude) < 0.001

		if isStillAtDefault {
			withAnimation {
				region = MKCoordinateRegion(
					center: userLocation,
					span: MKCoordinateSpan(
						latitudeDelta: 0.01,
						longitudeDelta: 0.01
					)
				)
			}
			print("📍 Auto-centered to user location")
		}
	}

	private func fitRegionToActivities() {
		let activitiesWithLocation = viewModel.activities.filter {
			$0.location != nil
		}
		guard !activitiesWithLocation.isEmpty else { return }

		let latitudes = activitiesWithLocation.compactMap {
			$0.location?.latitude
		}
		let longitudes = activitiesWithLocation.compactMap {
			$0.location?.longitude
		}

		guard let minLat = latitudes.min(),
			let maxLat = latitudes.max(),
			let minLon = longitudes.min(),
			let maxLon = longitudes.max()
		else {
			return
		}

		let centerLat = (minLat + maxLat) / 2
		let centerLon = (minLon + maxLon) / 2
		let latDelta = max((maxLat - minLat) * 1.5, 0.01)
		let lonDelta = max((maxLon - minLon) * 1.5, 0.01)

		region = MKCoordinateRegion(
			center: CLLocationCoordinate2D(
				latitude: centerLat,
				longitude: centerLon
			),
			span: MKCoordinateSpan(
				latitudeDelta: latDelta,
				longitudeDelta: lonDelta
			)
		)
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
	@Previewable @ObservedObject var appCache = AppCache.shared
	let previewViewModel = FeedViewModel(
		apiService: MockAPIService.isMocking
			? MockAPIService(userId: BaseUserDTO.danielAgapov.id)
			: APIService(),
		userId: BaseUserDTO.danielAgapov.id
	)
	MapView(user: .danielAgapov, viewModel: previewViewModel)
		.environmentObject(appCache)
}
