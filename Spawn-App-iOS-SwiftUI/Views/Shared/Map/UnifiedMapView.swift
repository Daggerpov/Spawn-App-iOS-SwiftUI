//
//  UnifiedMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Rebuilt from scratch for better stability and performance
//

import CoreLocation
import MapKit
import SwiftUI

/// A unified map view that can be used for both activity display and location selection
struct UnifiedMapView: UIViewRepresentable {
	// MARK: - Properties
	@Binding var region: MKCoordinateRegion
	@Binding var is3DMode: Bool

	let showsUserLocation: Bool
	var annotationItems: [FullFeedActivityDTO]
	let isLocationSelectionMode: Bool

	// MARK: - Callbacks
	var onMapWillChange: (() -> Void)?
	var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
	var onActivityTap: (FullFeedActivityDTO) -> Void
	var onMapLoaded: (() -> Void)?

	// MARK: - UIViewRepresentable

	func makeUIView(context: Context) -> MKMapView {
		let mapView = MKMapView()

		#if targetEnvironment(simulator)
		print("⚠️ Running on Simulator - Map tiles may not load properly")
		print("⚠️ If you see a grid, try running on a physical device")
		#endif

		// Basic setup
		mapView.mapType = .standard
		mapView.delegate = context.coordinator
		mapView.showsUserLocation = showsUserLocation

		// Enable standard map interactions
		mapView.isZoomEnabled = true
		mapView.isScrollEnabled = true
		mapView.isRotateEnabled = true
		mapView.isPitchEnabled = true
		mapView.isUserInteractionEnabled = true
		mapView.isMultipleTouchEnabled = true

		// Show standard map features
		mapView.showsCompass = true
		mapView.showsScale = true
		mapView.showsBuildings = true
		mapView.pointOfInterestFilter = .includingAll

		// Ensure map tiles can load
		let configuration = MKStandardMapConfiguration()
		configuration.elevationStyle = .flat
		configuration.pointOfInterestFilter = .includingAll
		mapView.preferredConfiguration = configuration

		// Set initial region
		if isValidRegion(region) {
			mapView.setRegion(region, animated: false)
		} else {
			// Fallback to Vancouver if region is invalid
			let fallbackRegion = MKCoordinateRegion(
				center: CLLocationCoordinate2D(
					latitude: 49.2827,
					longitude: -123.1207
				),
				span: MKCoordinateSpan(
					latitudeDelta: 0.01,
					longitudeDelta: 0.01
				)
			)
			mapView.setRegion(fallbackRegion, animated: false)
		}

		// Force initial render and tile loading
		DispatchQueue.main.async { [weak mapView] in
			guard let mapView = mapView else { return }
			mapView.layoutIfNeeded()
			// Force a small region change to trigger tile loading
			let currentRegion = mapView.region
			mapView.setRegion(currentRegion, animated: false)
			print("🗺️ Map view initial render forced")
		}

		return mapView
	}

	func updateUIView(_ mapView: MKMapView, context: Context) {
		// Update parent on main thread only
		DispatchQueue.main.async {
			context.coordinator.parent = self
		}

		// Update region if significantly changed and valid
		if shouldUpdateRegion(mapView: mapView, context: context) {
			mapView.setRegion(region, animated: true)
			context.coordinator.lastSetRegion = region
		}

		// Update 3D mode if changed
		if context.coordinator.last3DMode != is3DMode {
			update3DMode(mapView: mapView, animated: true)
			context.coordinator.last3DMode = is3DMode
		}

		// Update annotations if in activity display mode
		if !isLocationSelectionMode {
			updateAnnotations(mapView: mapView, context: context)
		}
	}

	static func dismantleUIView(_ mapView: MKMapView, coordinator: Coordinator)
	{
		print("🗺️ UnifiedMapView: Beginning dismantle")
		
		// Invalidate coordinator immediately
		coordinator.invalidate()
		
		// Remove delegate immediately to stop callbacks
		mapView.delegate = nil
		
		// CRITICAL: Remove annotations asynchronously to avoid blocking
		let annotationsToRemove = mapView.annotations.filter { !($0 is MKUserLocation) }
		
		if !annotationsToRemove.isEmpty {
			print("🗺️ UnifiedMapView: Removing \(annotationsToRemove.count) annotations asynchronously")
			
			// Dispatch to a background queue with a slight delay
			// This allows the tab transition to complete before cleanup
			DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.05) {
				DispatchQueue.main.async {
					// Check if mapView still exists and hasn't been reused
					guard mapView.delegate == nil else {
						print("🗺️ UnifiedMapView: MapView was reused, skipping cleanup")
						return
					}
					mapView.removeAnnotations(annotationsToRemove)
					print("🗺️ UnifiedMapView: Annotations removed")
				}
			}
		}
	}

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	// MARK: - Helper Methods

	/// Validates that a region has valid coordinates and spans
	private func isValidRegion(_ region: MKCoordinateRegion) -> Bool {
		return CLLocationCoordinate2DIsValid(region.center)
			&& region.span.latitudeDelta > 0
			&& region.span.longitudeDelta > 0
			&& region.span.latitudeDelta.isFinite
			&& region.span.longitudeDelta.isFinite
	}

	/// Determines if the region should be updated based on significant changes
	private func shouldUpdateRegion(mapView: MKMapView, context: Context)
		-> Bool
	{
		guard isValidRegion(region) else { return false }
		guard let lastRegion = context.coordinator.lastSetRegion else {
			return true
		}

		// Only update if there's a significant change (avoids render loops)
		let centerChanged =
			abs(lastRegion.center.latitude - region.center.latitude) > 0.0001
			|| abs(lastRegion.center.longitude - region.center.longitude)
				> 0.0001
		let spanChanged =
			abs(lastRegion.span.latitudeDelta - region.span.latitudeDelta)
			> 0.001
			|| abs(lastRegion.span.longitudeDelta - region.span.longitudeDelta)
				> 0.001

		return centerChanged || spanChanged
	}

	/// Updates the map's 3D mode by adjusting the camera
	private func update3DMode(mapView: MKMapView, animated: Bool) {
		let targetPitch: CGFloat =
			(is3DMode && !isLocationSelectionMode) ? 45.0 : 0.0
		let camera = MKMapCamera(
			lookingAtCenter: mapView.region.center,
			fromDistance: max(mapView.camera.altitude, 500),
			pitch: targetPitch,
			heading: mapView.camera.heading
		)

		mapView.setCamera(camera, animated: animated)
	}

	/// Updates map annotations based on activity items
	private func updateAnnotations(mapView: MKMapView, context: Context) {
		let newActivityIDs = Set(annotationItems.map { $0.id })

		// Skip update if annotations haven't changed
		guard context.coordinator.lastAnnotationIDs != newActivityIDs else {
			return
		}

		// Remove old annotations (except user location)
		let oldAnnotations = mapView.annotations.filter {
			!($0 is MKUserLocation)
		}
		mapView.removeAnnotations(oldAnnotations)

		// Add new annotations
		let newAnnotations: [ActivityAnnotation] = annotationItems.compactMap {
			activity in
			guard let location = activity.location else { return nil }

			let coordinate = CLLocationCoordinate2D(
				latitude: location.latitude,
				longitude: location.longitude
			)
			let icon = activity.icon?.isEmpty == false ? activity.icon! : "⭐️"
			let color = UIColor(
				ActivityColorService.shared.getColorForActivity(activity.id)
			)

			return ActivityAnnotation(
				activityId: activity.id,
				title: activity.title,
				coordinate: coordinate,
				icon: icon,
				color: color
			)
		}

		mapView.addAnnotations(newAnnotations)
		context.coordinator.lastAnnotationIDs = newActivityIDs
	}

	// MARK: - Coordinator

	class Coordinator: NSObject, MKMapViewDelegate {
		var parent: UnifiedMapView

		// Track state to prevent unnecessary updates
		var lastSetRegion: MKCoordinateRegion?
		var last3DMode: Bool = false
		var lastAnnotationIDs: Set<UUID> = []
		var hasReportedLoad = false
		private var isValid: Bool = true  // Track if coordinator is still valid

		init(_ parent: UnifiedMapView) {
			self.parent = parent
			super.init()
		}
		
		func invalidate() {
			isValid = false
		}

		// MARK: - Region Change Delegates

		func mapView(
			_ mapView: MKMapView,
			regionWillChangeAnimated animated: Bool
		) {
			parent.onMapWillChange?()
		}

		func mapView(
			_ mapView: MKMapView,
			regionDidChangeAnimated animated: Bool
		) {
			let region = mapView.region

			// Validate the new region
			guard CLLocationCoordinate2DIsValid(region.center),
				region.span.latitudeDelta > 0,
				region.span.longitudeDelta > 0,
				region.span.latitudeDelta.isFinite,
				region.span.longitudeDelta.isFinite
			else {
				return
			}

			// In location selection mode, update binding for accurate pin placement
			if parent.isLocationSelectionMode {
				DispatchQueue.main.async { [weak self] in
					guard let self = self else { return }
					self.parent.region = region
				}
			}

			// Call the change callback
			parent.onMapDidChange?(region.center)
		}

		// MARK: - Annotation Delegates

		func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
			-> MKAnnotationView?
		{
			// Don't customize user location or if in location selection mode
			guard !parent.isLocationSelectionMode,
				!(annotation is MKUserLocation)
			else {
				return nil
			}

			let identifier = "ActivityAnnotation"
			var annotationView = mapView.dequeueReusableAnnotationView(
				withIdentifier: identifier
			)

			if annotationView == nil {
				annotationView = MKAnnotationView(
					annotation: annotation,
					reuseIdentifier: identifier
				)
				annotationView?.canShowCallout = false
				annotationView?.isEnabled = true
			} else {
				annotationView?.annotation = annotation
			}

			// Set the custom pin image
			if let activityAnnotation = annotation as? ActivityAnnotation {
				annotationView?.image =
					MapAnnotationHelpers.createCustomPinImage(
						icon: activityAnnotation.activityIcon,
						color: activityAnnotation.activityUIColor
					)

				// Center the pin properly
				if let image = annotationView?.image {
					annotationView?.centerOffset = CGPoint(
						x: 0,
						y: -image.size.height / 2
					)
				}
			}

			return annotationView
		}

		func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
			// Handle activity selection
			guard !parent.isLocationSelectionMode else { return }

			if let activityAnnotation = view.annotation as? ActivityAnnotation,
				let activity = parent.annotationItems.first(where: {
					$0.id == activityAnnotation.activityId
				})
			{
				parent.onActivityTap(activity)
			}

			// Deselect immediately to allow re-tapping
			mapView.deselectAnnotation(view.annotation, animated: false)
		}

		// MARK: - Loading Delegates

		func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
			print("🗺️ mapViewDidFinishLoadingMap called")
			// Only report load once
			guard isValid, !hasReportedLoad else { return }
			hasReportedLoad = true

			DispatchQueue.main.async { [weak self] in
				guard let self = self, self.isValid else { return }
				self.parent.onMapLoaded?()
			}
		}

		func mapViewDidFinishRenderingMap(
			_ mapView: MKMapView,
			fullyRendered: Bool
		) {
			print("🗺️ mapViewDidFinishRenderingMap called - fullyRendered: \(fullyRendered)")
			if fullyRendered && !hasReportedLoad && isValid {
				hasReportedLoad = true
				DispatchQueue.main.async { [weak self] in
					guard let self = self, self.isValid else { return }
					self.parent.onMapLoaded?()
				}
			}
		}
		
		func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
			print("🗺️ mapViewWillStartLoadingMap called")
		}
		
		func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
			print("🗺️ mapViewWillStartRenderingMap called")
		}
		
		func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
			print("🗺️ Renderer requested for overlay")
			return MKOverlayRenderer(overlay: overlay)
		}
		
		func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
			print("❌ Map failed to load: \(error.localizedDescription)")
			print("❌ Error details: \(error)")
		}

		// MARK: - User Location Delegates

		func mapView(
			_ mapView: MKMapView,
			didUpdate userLocation: MKUserLocation
		) {
			// Silently handle user location updates
			// Logging can be added if needed for debugging
		}

		func mapView(
			_ mapView: MKMapView,
			didFailToLocateUserWithError error: Error
		) {
			print("⚠️ Map failed to locate user: \(error.localizedDescription)")
		}
	}
}

