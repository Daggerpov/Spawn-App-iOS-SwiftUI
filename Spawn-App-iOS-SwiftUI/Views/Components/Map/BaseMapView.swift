//
//  BaseMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 12/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Base Map View (iOS < 17)
struct BaseMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    let configuration: MapConfiguration
    let annotationItems: [FullFeedActivityDTO]
    let isLocationSelectionMode: Bool
    
    // Callbacks
    let onMapWillChange: (() -> Void)?
    let onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    let onActivityTap: ((FullFeedActivityDTO) -> Void)?
    
    func makeUIView(context: Context) -> MKMapView {
        print("🗺️ BaseMapView (iOS < 17): Creating MKMapView")
        let mapView = MKMapView()
        
        // Set initial frame for iOS < 17 compatibility
        mapView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        // Apply configuration
        configureMapView(mapView, with: configuration)
        
        // Set delegate
        mapView.delegate = context.coordinator
        
        // Set initial region with validation
        if let safeRegion = MapValidationUtils.createSafeRegion(center: region.center, span: region.span) {
            mapView.setRegion(safeRegion, animated: false)
        } else {
            print("⚠️ BaseMapView: Invalid initial region, using default")
            mapView.setRegion(MapValidationUtils.createDefaultRegion(), animated: false)
        }
        
        print("✅ BaseMapView (iOS < 17): MKMapView created successfully")
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        print("🗺️ BaseMapView (iOS < 17): Updating MKMapView")
        
        // Keep coordinator in sync with thread safety
        DispatchQueue.main.async {
            context.coordinator.parent = self
        }
        
        // Validate region before updating
        guard MapValidationUtils.validateRegion(region) else {
            print("⚠️ BaseMapView: Invalid region during update")
            return
        }
        
        // Check for significant location change
        let isLocationChange = abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 || 
                             abs(mapView.region.center.longitude - region.center.longitude) > 0.0001
        
        // Update region for iOS < 17 (no 3D mode support)
        if isLocationChange {
            DispatchQueue.main.async {
                guard MapValidationUtils.validateRegion(self.region) else {
                    print("⚠️ BaseMapView: Invalid region during async update")
                    return
                }
                mapView.setRegion(self.region, animated: true)
            }
        }
        
        // Update annotations if not in location selection mode
        if !isLocationSelectionMode {
            updateAnnotations(on: mapView)
        }
        
        print("✅ BaseMapView (iOS < 17): Update completed")
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    private func configureMapView(_ mapView: MKMapView, with config: MapConfiguration) {
        mapView.showsUserLocation = config.showsUserLocation
        mapView.isZoomEnabled = config.isZoomEnabled
        mapView.isScrollEnabled = config.isScrollEnabled
        mapView.isRotateEnabled = config.isRotateEnabled
        mapView.showsCompass = config.showsCompass
        mapView.showsScale = config.showsScale
        mapView.showsBuildings = config.showsBuildings
        mapView.isPitchEnabled = config.isPitchEnabled
        mapView.isUserInteractionEnabled = true
        
        // Use pointOfInterestFilter for iOS 13+
        if #available(iOS 13.0, *) {
            mapView.pointOfInterestFilter = .includingAll
        } else {
            mapView.showsPointsOfInterest = true
        }
    }
    
    private func updateAnnotations(on mapView: MKMapView) {
        print("🗺️ BaseMapView: Updating annotations, count: \(annotationItems.count)")
        
        // Additional safety check to prevent crashes on iOS < 17
        guard !annotationItems.isEmpty else {
            print("🗺️ BaseMapView: No annotations to update, skipping")
            return
        }
        
        // Remove existing annotations (except user location)
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(currentAnnotations)
        
        // Add new annotations with thread safety
        DispatchQueue.main.async {
            let newAnnotations = self.annotationItems.compactMap { activity -> MKAnnotation? in
                guard let location = activity.location else { return nil }
                
                let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                guard MapValidationUtils.validateCoordinate(coord) else { return nil }
                
                let icon = ActivityIconHelper.getIcon(for: activity)
                let color = UIColor(ActivityColorService.shared.getColorForActivity(activity.id))
                
                return ActivityAnnotation(
                    activityId: activity.id,
                    title: activity.title,
                    coordinate: coord,
                    icon: icon,
                    color: color
                )
            }
            
            mapView.addAnnotations(newAnnotations)
            print("✅ BaseMapView: Added \(newAnnotations.count) annotations")
        }
    }
}

// MARK: - Base Map View Coordinator
extension BaseMapView {
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: BaseMapView
        
        init(_ parent: BaseMapView) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.onMapWillChange?()
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard MapValidationUtils.validateRegion(mapView.region) else {
                print("⚠️ BaseMapView: Invalid region from map view")
                return
            }
            
            // Ensure we're on the main thread and add additional safety checks
            DispatchQueue.main.async {
                // Additional validation to prevent crashes on iOS < 17
                guard MapValidationUtils.validateRegion(mapView.region) else {
                    print("⚠️ BaseMapView: Region validation failed during async update")
                    return
                }
                
                // Update region binding for location selection or non-3D mode
                if self.parent.isLocationSelectionMode || !self.parent.is3DMode {
                    self.parent.region = mapView.region
                }
                self.parent.onMapDidChange?(mapView.region.center)
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Return nil for user location or in location selection mode
            if annotation is MKUserLocation || parent.isLocationSelectionMode {
                return nil
            }
            
            let identifier = "ActivityPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                annotationView?.isDraggable = false
                annotationView?.isEnabled = true
                annotationView?.isUserInteractionEnabled = true
            } else {
                annotationView?.annotation = annotation
            }
            
            // Set custom pin image
            if let activityAnnotation = annotation as? ActivityAnnotation {
                if let customImage = CustomPinImageGenerator.createPinImage(
                    icon: activityAnnotation.activityIcon,
                    color: activityAnnotation.activityUIColor
                ) {
                    annotationView?.image = customImage
                    annotationView?.centerOffset = CGPoint(x: 0, y: -customImage.size.height / 2)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !parent.isLocationSelectionMode else { return }
            
            if let activityAnnotation = view.annotation as? ActivityAnnotation {
                // Thread-safe array access with bounds checking
                DispatchQueue.main.async {
                    guard !self.parent.annotationItems.isEmpty,
                          let activity = self.parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId }) else {
                        print("⚠️ BaseMapView: Activity not found or empty annotation items")
                        return
                    }
                    self.parent.onActivityTap?(activity)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
            print("⚠️ BaseMapView: Failed to locate user - \(error.localizedDescription)")
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let location = userLocation.location?.coordinate,
               MapValidationUtils.validateCoordinate(location) {
                print("📍 BaseMapView: User location updated - \(location)")
            }
        }
    }
}
