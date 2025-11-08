//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import CoreLocation
import MapKit
import SwiftUI

struct MapView: View {
	@ObservedObject var viewModel: FeedViewModel
	@StateObject private var locationManager = LocationManager()

	@State private var region = MKCoordinateRegion(
		center: CLLocationCoordinate2D(
			latitude: defaultMapLatitude,
			longitude: defaultMapLongitude
		),
		span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
	)

	@State private var is3DMode: Bool = false
	@State private var showFilterOverlay: Bool = false
	@State private var selectedTimeFilter: MapFilterOverlay.TimeFilter = .allActivities
	@State private var showLocationError: Bool = false
	@State private var locationErrorMessage: String = ""
	@State private var isViewVisible = false
	@State private var filteredActivities: [FullFeedActivityDTO] = []

	var user: BaseUserDTO

	init(user: BaseUserDTO, viewModel: FeedViewModel) {
		self.user = user
		self.viewModel = viewModel
	}

	// MARK: - Helper Methods

	/// Updates filtered activities based on current filter and activities
	/// This is called only when needed, not on every render (performance optimization)
	private func updateFilteredActivities() {
		let now = Date()
		let calendar = Calendar.current

		let filtered = viewModel.activities.filter { activity in
			guard let startTime = activity.startTime else { return false }

			switch selectedTimeFilter {
			case .allActivities:
				return true

			case .happeningNow:
				guard let endTime = activity.endTime else { return false }
				return startTime <= now && endTime >= now

			case .inTheNextHour:
				let oneHourFromNow = calendar.date(
					byAdding: .hour,
					value: 1,
					to: now
				)!
				return startTime > now && startTime <= oneHourFromNow

			case .afternoon:
				let noonTime = calendar.date(
					bySettingHour: 12,
					minute: 0,
					second: 0,
					of: startTime
				)!
				let eveningTime = calendar.date(
					bySettingHour: 17,
					minute: 0,
					second: 0,
					of: startTime
				)!

				return startTime >= noonTime && startTime < eveningTime
					&& calendar.isDate(startTime, inSameDayAs: now)

			case .evening:
				let eveningTime = calendar.date(
					bySettingHour: 17,
					minute: 0,
					second: 0,
					of: startTime
				)!
				let nightTime = calendar.date(
					bySettingHour: 21,
					minute: 0,
					second: 0,
					of: startTime
				)!

				return startTime >= eveningTime && startTime < nightTime
					&& calendar.isDate(startTime, inSameDayAs: now)

			case .lateNight:
				let startOfDay = calendar.startOfDay(for: startTime)
				let nightTime = calendar.date(
					bySettingHour: 21,
					minute: 0,
					second: 0,
					of: startTime
				)!
				let nextDay = calendar.date(
					byAdding: .day,
					value: 1,
					to: startOfDay
				)!

				return (startTime >= nightTime && startTime < nextDay)
					|| (startTime >= startOfDay
						&& startTime < calendar.date(
							bySettingHour: 4,
							minute: 0,
							second: 0,
							of: startTime
						)!)
			}
		}

		filteredActivities = filtered
	}

	var body: some View {
		ZStack {
			// Map layer
			UnifiedMapView(
				region: $region,
				is3DMode: $is3DMode,
				showsUserLocation: true,
				annotationItems: filteredActivities.filter { $0.location != nil },
				isLocationSelectionMode: false,
				onMapWillChange: nil,
				onMapDidChange: { _ in },
				onActivityTap: { activity in
					NotificationCenter.default.post(
						name: .showGlobalActivityPopup,
						object: nil,
						userInfo: [
							"activity": activity,
							"color": ActivityColorService.shared.getColorForActivity(activity.id),
							"fromMapView": true,
						]
					)
				},
				onMapLoaded: {
					print("✅ Map loaded successfully")
				}
			)
			.ignoresSafeArea()

			// Control buttons (3D toggle, location)
			MapControlButtons(
				is3DMode: $is3DMode,
				region: $region,
				locationManager: locationManager
			)

			// Filter overlay
			MapFilterOverlay(
				showFilterOverlay: $showFilterOverlay,
				selectedTimeFilter: $selectedTimeFilter
			)
		}
		.onAppear {
			isViewVisible = true
			print("🗺️ MapView appeared")
			
			updateFilteredActivities()
			
			// Set initial region immediately - let UnifiedMapView handle initialization
			if let userLocation = self.locationManager.userLocation {
				self.region = MKCoordinateRegion(
					center: userLocation,
					span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
				)
			} else if !self.viewModel.activities.isEmpty {
				self.adjustRegionForActivities()
			}
			
			// Start location updates
			if locationManager.authorizationStatus == .authorizedWhenInUse
				|| locationManager.authorizationStatus == .authorizedAlways
			{
				locationManager.startLocationUpdates()
			}
		}
		.onDisappear {
			isViewVisible = false
			locationManager.stopLocationUpdates()
			print("🗺️ MapView disappeared")
		}
		.onChange(of: locationManager.locationUpdated) {
			guard isViewVisible else { return }
			
			if locationManager.locationUpdated
				&& locationManager.userLocation != nil
				&& abs(region.center.latitude - defaultMapLatitude) < 0.0001
				&& abs(region.center.longitude - defaultMapLongitude) < 0.0001
			{
				adjustRegionToUserLocation()
			}
		}
		.onChange(of: viewModel.activities) {
			guard isViewVisible else { return }
			updateFilteredActivities()
		}
		.onChange(of: selectedTimeFilter) {
			updateFilteredActivities()
		}
		.onChange(of: locationManager.locationError) { _, error in
			guard isViewVisible else { return }
			
			if let error = error {
				locationErrorMessage = error
				showLocationError = true
			}
		}
		.alert("Location Error", isPresented: $showLocationError) {
			Button("OK") {
				showLocationError = false
			}
			if locationManager.authorizationStatus == .denied {
				Button("Settings") {
					if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
						UIApplication.shared.open(settingsUrl)
					}
				}
			}
		} message: {
			Text(locationErrorMessage)
		}
	}

	private func adjustRegionToUserLocation() {
		if let userLocation = locationManager.userLocation {
			withAnimation {
				region = MKCoordinateRegion(
					center: userLocation,
					span: MKCoordinateSpan(
						latitudeDelta: 0.01,
						longitudeDelta: 0.01
					)
				)
			}
		}
	}

	private func adjustRegionForActivities() {
		guard !viewModel.activities.isEmpty else { return }

		let latitudes = viewModel.activities.compactMap { $0.location?.latitude }
		let longitudes = viewModel.activities.compactMap { $0.location?.longitude }

		guard let minLatitude = latitudes.min(),
			let maxLatitude = latitudes.max(),
			let minLongitude = longitudes.min(),
			let maxLongitude = longitudes.max()
		else { return }

		let centerLatitude = (minLatitude + maxLatitude) / 2
		let centerLongitude = (minLongitude + maxLongitude) / 2
		let latitudeDelta = (maxLatitude - minLatitude) * 1.5
		let longitudeDelta = (maxLongitude - minLongitude) * 1.5

		withAnimation {
			region = MKCoordinateRegion(
				center: CLLocationCoordinate2D(
					latitude: centerLatitude,
					longitude: centerLongitude
				),
				span: MKCoordinateSpan(
					latitudeDelta: max(latitudeDelta, 0.01),
					longitudeDelta: max(longitudeDelta, 0.01)
				)
			)
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @ObservedObject var appCache = AppCache.shared
	let previewViewModel = FeedViewModel(
		apiService: MockAPIService.isMocking
			? MockAPIService(userId: BaseUserDTO.danielAgapov.id)
			: APIService(),
		userId: BaseUserDTO.danielAgapov.id
	)
	MapView(user: .danielAgapov, viewModel: previewViewModel).environmentObject(
		appCache
	)
}
