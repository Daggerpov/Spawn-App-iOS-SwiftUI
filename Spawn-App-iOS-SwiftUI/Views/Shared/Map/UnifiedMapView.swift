//
//  UnifiedMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 12/22/24.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Unified Map View
// This component can be used for both activity display and location selection
struct UnifiedMapView: UIViewRepresentable {
	@Binding var region: MKCoordinateRegion
	@Binding var is3DMode: Bool
	let showsUserLocation: Bool
	var annotationItems: [FullFeedActivityDTO]
	let isLocationSelectionMode: Bool

	// Callbacks
	var onMapWillChange: (() -> Void)?
	var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
	var onActivityTap: (FullFeedActivityDTO) -> Void
	var onMapLoaded: (() -> Void)?

	func makeUIView(context: Context) -> MKMapView {
		let mapView = MKMapView()

		// CRITICAL: Set map type to standard to ensure tiles load
		mapView.mapType = .standard

		mapView.showsUserLocation = showsUserLocation
		mapView.delegate = context.coordinator

		// Set properties for better stability
		mapView.isZoomEnabled = true
		mapView.isScrollEnabled = true
		mapView.isRotateEnabled = true
		mapView.showsCompass = true
		mapView.showsScale = true
		mapView.isUserInteractionEnabled = true

		// Additional iOS < 17 compatibility settings
		mapView.showsBuildings = true
		mapView.isPitchEnabled = true

		// Use pointOfInterestFilter instead of deprecated showsPointsOfInterest
		if #available(iOS 13.0, *) {
			mapView.pointOfInterestFilter = .includingAll
		} else {
			mapView.showsPointsOfInterest = true
		}

		// Validate region before setting to prevent crashes
		guard
			CLLocationCoordinate2DIsValid(region.center)
				&& region.span.latitudeDelta > 0
				&& region.span.longitudeDelta > 0
				&& region.span.latitudeDelta.isFinite
				&& region.span.longitudeDelta.isFinite
		else {
			let defaultRegion = MKCoordinateRegion(
				center: CLLocationCoordinate2D(
					latitude: 49.2827,
					longitude: -123.1207
				),
				span: MKCoordinateSpan(
					latitudeDelta: 0.01,
					longitudeDelta: 0.01
				)
			)
			mapView.setRegion(defaultRegion, animated: false)
			// Notify that map is loaded after a short delay to ensure rendering
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.onMapLoaded?()
			}
			return mapView
		}

		// Set initial region using the basic setRegion method for better iOS < 17 compatibility
		mapView.setRegion(region, animated: false)

		print(
			"🗺️ UnifiedMapView: Map view created, waiting for tiles to load..."
		)

		// Call onMapLoaded after a short delay as fallback
		// The delegate method will also call it, but this ensures it gets called
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			self.onMapLoaded?()
		}

		return mapView
	}

	func updateUIView(_ mapView: MKMapView, context: Context) {
		// Keep coordinator in sync with latest parent values
		context.coordinator.parent = self

		// Validate coordinates before updating
		guard
			CLLocationCoordinate2DIsValid(region.center)
				&& region.span.latitudeDelta > 0
				&& region.span.longitudeDelta > 0
				&& region.span.latitudeDelta.isFinite
				&& region.span.longitudeDelta.isFinite
		else {
			return
		}

		// Check if region significantly changed from last render
		let regionChanged: Bool = {
			guard let lastCenter = context.coordinator.lastRenderedRegionCenter,
				let lastSpan = context.coordinator.lastRenderedRegionSpan
			else {
				return true  // First render
			}
			return abs(lastCenter.latitude - region.center.latitude) > 0.0005
				|| abs(lastCenter.longitude - region.center.longitude) > 0.0005
				|| abs(lastSpan.latitudeDelta - region.span.latitudeDelta)
					> 0.001
				|| abs(lastSpan.longitudeDelta - region.span.longitudeDelta)
					> 0.001
		}()

		// Check for significant location change from current map view
		let isLocationChange =
			abs(mapView.region.center.latitude - region.center.latitude)
			> 0.0005
			|| abs(mapView.region.center.longitude - region.center.longitude)
				> 0.0005

		// Check if 3D mode changed
		let mode3DChanged = context.coordinator.lastRendered3DMode != is3DMode

		// 3D mode functionality with MapKit camera
		let currentCamera = mapView.camera
		let targetPitch = is3DMode ? 45.0 : 0.0

		// Only update camera if region changed or 3D mode toggled
		if (regionChanged && isLocationChange) || mode3DChanged {
			// Create new camera while preserving current altitude and heading
			let newCamera = MKMapCamera(
				lookingAtCenter: region.center,
				fromDistance: max(currentCamera.altitude, 500),  // Ensure minimum altitude
				pitch: isLocationSelectionMode ? 0.0 : targetPitch,  // Keep flat for location selection
				heading: currentCamera.heading
			)

			UIView.animate(
				withDuration: 0.75,
				delay: 0,
				options: [.curveEaseInOut],
				animations: {
					mapView.camera = newCamera
				},
				completion: nil
			)
		}

		// Update region only if not in 3D mode and region significantly changed
		if !is3DMode && regionChanged && isLocationChange {
			mapView.setRegion(region, animated: true)
		}

		// Update annotations only if not in location selection mode
		if !isLocationSelectionMode {
			let newActivityIDs = Set(annotationItems.map { $0.id })

			// Check if annotations have changed from last render
			let annotationsChanged =
				context.coordinator.lastRenderedAnnotationIDs != newActivityIDs

			if annotationsChanged {
				let currentAnnotations = mapView.annotations.filter {
					!($0 is MKUserLocation)
				}
				mapView.removeAnnotations(currentAnnotations)

				let newAnnotations = annotationItems.compactMap {
					activity -> MKAnnotation? in
					guard let location = activity.location else { return nil }
					let coord = CLLocationCoordinate2D(
						latitude: location.latitude,
						longitude: location.longitude
					)
					let icon =
						(activity.icon?.isEmpty == false) ? activity.icon! : "⭐️"
					let color = UIColor(
						ActivityColorService.shared.getColorForActivity(
							activity.id
						)
					)
					return ActivityAnnotation(
						activityId: activity.id,
						title: activity.title,
						coordinate: coord,
						icon: icon,
						color: color
					)
				}
				mapView.addAnnotations(newAnnotations)

				// Update cached annotation IDs
				context.coordinator.lastRenderedAnnotationIDs = newActivityIDs
			}
		}

		// Update cached state to prevent unnecessary future updates
		if regionChanged {
			context.coordinator.lastRenderedRegionCenter = region.center
			context.coordinator.lastRenderedRegionSpan = region.span
		}
		if mode3DChanged {
			context.coordinator.lastRendered3DMode = is3DMode
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	class Coordinator: NSObject, MKMapViewDelegate {
		var parent: UnifiedMapView

		// Track last rendered state to prevent unnecessary updates
		var lastRenderedAnnotationIDs: Set<UUID> = []
		var lastRendered3DMode: Bool = false
		var lastRenderedRegionCenter: CLLocationCoordinate2D?
		var lastRenderedRegionSpan: MKCoordinateSpan?

		// Track last logged location to prevent excessive logging
		var lastLoggedLocation: CLLocationCoordinate2D?

		init(_ parent: UnifiedMapView) {
			self.parent = parent
			super.init()
		}

		func mapView(
			_ mapView: MKMapView,
			regionWillChangeAnimated animated: Bool
		) {
			DispatchQueue.main.async {
				self.parent.onMapWillChange?()
			}
		}

		func mapView(
			_ mapView: MKMapView,
			regionDidChangeAnimated animated: Bool
		) {
			// Safely handle region changes to prevent crashes
			guard CLLocationCoordinate2DIsValid(mapView.region.center) else {
				return
			}

			// Validate region span to prevent invalid values
			let region = mapView.region
			guard
				region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0
					&& region.span.latitudeDelta.isFinite
					&& region.span.longitudeDelta.isFinite
			else {
				return
			}

			// Only update binding if there's a significant change to prevent feedback loops
			let isSignificantChange =
				abs(region.center.latitude - parent.region.center.latitude)
				> 0.0005
				|| abs(region.center.longitude - parent.region.center.longitude)
					> 0.0005
				|| abs(
					region.span.latitudeDelta - parent.region.span.latitudeDelta
				) > 0.001
				|| abs(
					region.span.longitudeDelta
						- parent.region.span.longitudeDelta
				) > 0.001

			guard isSignificantChange else {
				return
			}

			DispatchQueue.main.async {
				// Only update region binding if in location selection mode (needs accurate pin placement)
				// For map view, don't update binding to prevent feedback loop with animations
				if self.parent.isLocationSelectionMode {
					self.parent.region = region
				}
				self.parent.onMapDidChange?(region.center)
			}
		}

		func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
			-> MKAnnotationView?
		{
			// Only create custom views for activity annotations, not in location selection mode
			if annotation is MKUserLocation || parent.isLocationSelectionMode {
				return nil
			}

			let identifier = "ActivityPin"
			var annotationView = mapView.dequeueReusableAnnotationView(
				withIdentifier: identifier
			)

			if annotationView == nil {
				annotationView = MKAnnotationView(
					annotation: annotation,
					reuseIdentifier: identifier
				)
				annotationView?.canShowCallout = false
				annotationView?.isDraggable = false
				annotationView?.isEnabled = true
				annotationView?.isUserInteractionEnabled = true
			} else {
				annotationView?.annotation = annotation
			}

			// Resolve activity for this annotation
			let resolvedActivity: FullFeedActivityDTO? = {
				if let activityAnnotation = annotation as? ActivityAnnotation {
					return parent.annotationItems.first(where: {
						$0.id == activityAnnotation.activityId
					})
				}
				// Fallback: coordinate proximity match
				let coord = annotation.coordinate
				let epsilon = 0.000001
				return parent.annotationItems.first(where: { act in
					guard let loc = act.location else { return false }
					return abs(loc.latitude - coord.latitude) < epsilon
						&& abs(loc.longitude - coord.longitude) < epsilon
				})
			}()

			if let activityAnnotation = annotation as? ActivityAnnotation {
				if let customImage = MapAnnotationHelpers.createCustomPinImage(
					icon: activityAnnotation.activityIcon,
					color: activityAnnotation.activityUIColor
				) {
					annotationView?.image = customImage
					annotationView?.centerOffset = CGPoint(
						x: 0,
						y: -customImage.size.height / 2
					)
				}
			} else if let resolvedActivity = resolvedActivity {
				let activityIcon = MapAnnotationHelpers.getActivityIcon(
					for: resolvedActivity
				)
				let activityColor = UIColor(
					ActivityColorService.shared.getColorForActivity(
						resolvedActivity.id
					)
				)
				if let customImage = MapAnnotationHelpers.createCustomPinImage(
					icon: activityIcon,
					color: activityColor
				) {
					annotationView?.image = customImage
					annotationView?.centerOffset = CGPoint(
						x: 0,
						y: -customImage.size.height / 2
					)
				}
			} else {
				if let fallbackImage =
					MapAnnotationHelpers.createCustomPinImage(
						icon: "⭐️",
						color: UIColor(Color(hex: "#333333"))
					)
				{
					annotationView?.image = fallbackImage
					annotationView?.centerOffset = CGPoint(
						x: 0,
						y: -fallbackImage.size.height / 2
					)
				}
			}

			return annotationView
		}

		func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
			// Only handle activity selection if not in location selection mode
			guard !parent.isLocationSelectionMode else {
				return
			}

			if let activityAnnotation = view.annotation as? ActivityAnnotation {
				if let activity = parent.annotationItems.first(where: {
					$0.id == activityAnnotation.activityId
				}) {
					parent.onActivityTap(activity)
				}
			} else if let annotation = view.annotation {
				// Fallback: coordinate proximity match
				let coord = annotation.coordinate
				let epsilon = 0.000001
				if let activity = parent.annotationItems.first(where: { act in
					guard let loc = act.location else { return false }
					return abs(loc.latitude - coord.latitude) < epsilon
						&& abs(loc.longitude - coord.longitude) < epsilon
				}) {
					parent.onActivityTap(activity)
				}
			}
		}

		func mapView(
			_ mapView: MKMapView,
			didFailToLocateUserWithError error: Error
		) {
			print(
				"⚠️ UnifiedMapView: Failed to locate user - \(error.localizedDescription)"
			)
		}

		func mapView(
			_ mapView: MKMapView,
			didUpdate userLocation: MKUserLocation
		) {
			// Only log significant location changes to avoid console spam
			if let location = userLocation.location?.coordinate,
				CLLocationCoordinate2DIsValid(location)
			{

				// Only log if location has changed significantly (>10 meters)
				if let lastLocation = self.lastLoggedLocation {
					let distance = self.calculateDistance(
						from: lastLocation,
						to: location
					)
					if distance > 10.0 {  // 10 meters threshold
						print(
							"📍 UnifiedMapView: User location updated - \(location) (moved \(String(format: "%.1f", distance))m)"
						)
						self.lastLoggedLocation = location
					}
				} else {
					// First location update
					print(
						"📍 UnifiedMapView: Initial user location - \(location)"
					)
					self.lastLoggedLocation = location
				}
			}
		}

		func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
			// This delegate method is called when MapKit finishes loading and rendering the map
			print("✅ UnifiedMapView: Map tiles finished loading")
			DispatchQueue.main.async {
				self.parent.onMapLoaded?()
			}
		}

		func mapViewDidFinishRenderingMap(
			_ mapView: MKMapView,
			fullyRendered: Bool
		) {
			// This is called when the map finishes rendering
			// We use mapViewDidFinishLoadingMap instead, but this can be a backup
			if fullyRendered {
				print("✅ UnifiedMapView: Map fully rendered")
			}
		}

		// Helper to calculate distance between two coordinates in meters
		private func calculateDistance(
			from: CLLocationCoordinate2D,
			to: CLLocationCoordinate2D
		) -> Double {
			let fromLocation = CLLocation(
				latitude: from.latitude,
				longitude: from.longitude
			)
			let toLocation = CLLocation(
				latitude: to.latitude,
				longitude: to.longitude
			)
			return fromLocation.distance(from: toLocation)
		}
	}
}
