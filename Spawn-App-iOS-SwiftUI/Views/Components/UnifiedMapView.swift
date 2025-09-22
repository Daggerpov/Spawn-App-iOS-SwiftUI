//
//  UnifiedMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created By Daniel Agapov on 12/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Unified Map View Representable
// This component can be used for both activity display and location selection
struct UnifiedMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    let showsUserLocation: Bool
    var annotationItems: [FullFeedActivityDTO]
    let isLocationSelectionMode: Bool
    
    // Callbacks
    var onMapWillChange: (() -> Void)?
    var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    var onActivityTap: (FullFeedActivityDTO) -> Void
    
    // Custom annotation type that carries the activity data needed for rendering
    private class ActivityAnnotation: NSObject, MKAnnotation {
        let activityId: UUID
        dynamic var coordinate: CLLocationCoordinate2D
        var title: String?
        let activityIcon: String
        let activityUIColor: UIColor
        
        init(activityId: UUID, title: String?, coordinate: CLLocationCoordinate2D, icon: String, color: UIColor) {
            self.activityId = activityId
            self.title = title
            self.coordinate = coordinate
            self.activityIcon = icon
            self.activityUIColor = color
            super.init()
        }
    }
    
    func makeUIView(context: Context) -> MKMapView {
        print("🔍 DEBUG: UnifiedMapView makeUIView called")
        let mapView = MKMapView()
        print("🔍 DEBUG: Created MKMapView instance")
        
        // Ensure proper initialization for iOS < 17 compatibility
        mapView.frame = CGRect(x: 0, y: 0, width: 100, height: 100) // Set initial finite frame
        print("🔍 DEBUG: Set initial frame for MKMapView")
        
        mapView.showsUserLocation = showsUserLocation
        mapView.delegate = context.coordinator
        print("🔍 DEBUG: Set basic MKMapView properties")
        
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
        print("🔍 DEBUG: Set advanced MKMapView properties")
        
        print("🗺️ UnifiedMapView created with delegate set for iOS \(UIDevice.current.systemVersion)")
        
        // Validate region before setting to prevent crashes
        print("🔍 DEBUG: Validating region - center: \(region.center), span: \(region.span)")
        guard CLLocationCoordinate2DIsValid(region.center) &&
              region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0 &&
              region.span.latitudeDelta.isFinite && region.span.longitudeDelta.isFinite else {
            print("⚠️ UnifiedMapView: Invalid initial region, using default")
            let defaultRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            print("🔍 DEBUG: Setting default region: \(defaultRegion)")
            mapView.setRegion(defaultRegion, animated: false)
            print("🔍 DEBUG: Default region set, returning mapView")
            return mapView
        }
        
        // Set initial region using the basic setRegion method for better iOS < 17 compatibility
        print("🔍 DEBUG: Setting valid initial region: \(region)")
        mapView.setRegion(region, animated: false)
        print("🔍 DEBUG: Initial region set successfully")
        
        print("🔍 DEBUG: Returning configured mapView")
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        print("🔍 DEBUG: UnifiedMapView updateUIView called")
        // Keep coordinator in sync with latest parent values
        context.coordinator.parent = self
        
        // Validate coordinates before updating
        print("🔍 DEBUG: Validating region for update - center: \(region.center), span: \(region.span)")
        guard CLLocationCoordinate2DIsValid(region.center) &&
              region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0 &&
              region.span.latitudeDelta.isFinite && region.span.longitudeDelta.isFinite else {
            print("⚠️ UnifiedMapView: Invalid region - center: \(region.center), span: \(region.span)")
            return
        }
        
        // Check for significant location change
        let isLocationChange = abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 || 
                             abs(mapView.region.center.longitude - region.center.longitude) > 0.0001
        
        // Handle 3D mode only on iOS 17+
        if #available(iOS 17.0, *) {
            // 3D mode functionality with MapKit camera
            let currentCamera = mapView.camera
            let targetPitch = is3DMode ? 45.0 : 0.0
            
            if isLocationChange || abs(currentCamera.pitch - targetPitch) > 1.0 {
                // Create new camera while preserving current altitude and heading
                let newCamera = MKMapCamera(
                    lookingAtCenter: region.center,
                    fromDistance: max(currentCamera.altitude, 500), // Ensure minimum altitude
                    pitch: isLocationSelectionMode ? 0.0 : targetPitch, // Keep flat for location selection
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
            
            // Update region only if not in 3D mode or if it's a significant change
            if !is3DMode || isLocationChange {
                mapView.setRegion(region, animated: true)
            }
        } else {
            // For iOS < 17, use simple region updates with additional safety checks
            if isLocationChange {
                // Use a dispatch to main queue for better iOS < 17 compatibility
                DispatchQueue.main.async {
                    // Double-check region validity before setting
                    guard CLLocationCoordinate2DIsValid(self.region.center) else {
                        print("⚠️ UnifiedMapView: Invalid region center during iOS < 17 update")
                        return
                    }
                    mapView.setRegion(self.region, animated: true)
                }
            }
        }
        
        // Update annotations only if not in location selection mode
        if !isLocationSelectionMode {
            print("🔍 DEBUG: Updating annotations, annotationItems count: \(annotationItems.count)")
            let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
            print("🔍 DEBUG: Removing \(currentAnnotations.count) current annotations")
            mapView.removeAnnotations(currentAnnotations)
            
            print("🔍 DEBUG: Processing \(annotationItems.count) annotation items")
            let newAnnotations = annotationItems.compactMap { activity -> MKAnnotation? in
                print("🔍 DEBUG: Processing activity: \(activity.id)")
                guard let location = activity.location else { 
                    print("🔍 DEBUG: Activity \(activity.id) has no location")
                    return nil 
                }
                let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                let icon = (activity.icon?.isEmpty == false) ? activity.icon! : "⭐️"
                print("🔍 DEBUG: Getting color for activity \(activity.id)")
                let color = UIColor(ActivityColorService.shared.getColorForActivity(activity.id))
                print("🔍 DEBUG: Created annotation for activity \(activity.id)")
                return ActivityAnnotation(activityId: activity.id, title: activity.title, coordinate: coord, icon: icon, color: color)
            }
            print("🔍 DEBUG: Adding \(newAnnotations.count) new annotations")
            mapView.addAnnotations(newAnnotations)
            print("🔍 DEBUG: Annotations update completed")
        } else {
            print("🔍 DEBUG: In location selection mode, skipping annotation updates")
        }
    }
    
    func makeCoordinator() -> Coordinator {
        print("🔍 DEBUG: UnifiedMapView makeCoordinator called")
        let coordinator = Coordinator(self)
        print("🔍 DEBUG: Created coordinator: \(coordinator)")
        return coordinator
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UnifiedMapViewRepresentable
        
        init(_ parent: UnifiedMapViewRepresentable) {
            print("🔍 DEBUG: Coordinator init called with parent")
            self.parent = parent
            super.init()
            print("🔍 DEBUG: Coordinator initialized successfully")
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.onMapWillChange?()
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Safely handle region changes to prevent crashes
            guard CLLocationCoordinate2DIsValid(mapView.region.center) else {
                print("⚠️ UnifiedMapView: Invalid region center from map view - \(mapView.region.center)")
                return
            }
            
            // Validate region span to prevent invalid values
            let region = mapView.region
            guard region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0 &&
                  region.span.latitudeDelta.isFinite && region.span.longitudeDelta.isFinite else {
                print("⚠️ UnifiedMapView: Invalid region span - \(region.span)")
                return
            }
            
            DispatchQueue.main.async {
                // Only update region binding if not in 3D mode to prevent conflicts (for activity view)
                if self.parent.isLocationSelectionMode || !self.parent.is3DMode {
                    self.parent.region = region
                }
                self.parent.onMapDidChange?(region.center)
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Only create custom views for activity annotations, not in location selection mode
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
            
            // Resolve activity for this annotation
            print("🔍 DEBUG: Resolving activity for annotation, annotationItems count: \(parent.annotationItems.count)")
            let resolvedActivity: FullFeedActivityDTO? = {
                if let activityAnnotation = annotation as? ActivityAnnotation {
                    print("🔍 DEBUG: Looking for activity with ID: \(activityAnnotation.activityId)")
                    let result = parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId })
                    print("🔍 DEBUG: Found activity by ID: \(result != nil)")
                    return result
                }
                // Fallback: coordinate proximity match
                print("🔍 DEBUG: Using coordinate proximity match")
                let coord = annotation.coordinate
                let epsilon = 0.000001
                let result = parent.annotationItems.first(where: { act in
                    guard let loc = act.location else { return false }
                    return abs(loc.latitude - coord.latitude) < epsilon && abs(loc.longitude - coord.longitude) < epsilon
                })
                print("🔍 DEBUG: Found activity by coordinate: \(result != nil)")
                return result
            }()
            
            if let activityAnnotation = annotation as? ActivityAnnotation {
                if let customImage = createCustomPinImage(icon: activityAnnotation.activityIcon, color: activityAnnotation.activityUIColor) {
                    annotationView?.image = customImage
                    annotationView?.centerOffset = CGPoint(x: 0, y: -customImage.size.height / 2)
                }
            } else if let resolvedActivity = resolvedActivity {
                let activityIcon = getActivityIcon(for: resolvedActivity)
                let activityColor = UIColor(ActivityColorService.shared.getColorForActivity(resolvedActivity.id))
                if let customImage = createCustomPinImage(icon: activityIcon, color: activityColor) {
                    annotationView?.image = customImage
                    annotationView?.centerOffset = CGPoint(x: 0, y: -customImage.size.height / 2)
                }
            } else {
                if let fallbackImage = createCustomPinImage(icon: "⭐️", color: UIColor(Color(hex: "#333333"))) {
                    annotationView?.image = fallbackImage
                    annotationView?.centerOffset = CGPoint(x: 0, y: -fallbackImage.size.height / 2)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            print("🔍 DEBUG: didSelect annotation called")
            // Only handle activity selection if not in location selection mode
            guard !parent.isLocationSelectionMode else { 
                print("🔍 DEBUG: In location selection mode, ignoring tap")
                return 
            }
            
            print("🔍 DEBUG: Processing activity selection, annotationItems count: \(parent.annotationItems.count)")
            if let activityAnnotation = view.annotation as? ActivityAnnotation {
                print("🔍 DEBUG: Got ActivityAnnotation with ID: \(activityAnnotation.activityId)")
                if let activity = parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId }) {
                    print("🔍 DEBUG: Found matching activity, calling onActivityTap")
                    parent.onActivityTap(activity)
                } else {
                    print("🔍 DEBUG: No matching activity found for ID: \(activityAnnotation.activityId)")
                }
            } else if let annotation = view.annotation {
                print("🔍 DEBUG: Using coordinate fallback for annotation selection")
                // Fallback: coordinate proximity match
                let coord = annotation.coordinate
                let epsilon = 0.000001
                if let activity = parent.annotationItems.first(where: { act in
                    guard let loc = act.location else { return false }
                    return abs(loc.latitude - coord.latitude) < epsilon && abs(loc.longitude - coord.longitude) < epsilon
                }) {
                    print("🔍 DEBUG: Found activity by coordinate, calling onActivityTap")
                    parent.onActivityTap(activity)
                } else {
                    print("🔍 DEBUG: No matching activity found by coordinate")
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
            print("⚠️ UnifiedMapView: Failed to locate user - \(error.localizedDescription)")
        }
        
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            if let location = userLocation.location?.coordinate,
               CLLocationCoordinate2DIsValid(location) {
                print("📍 UnifiedMapView: User location updated - \(location)")
            }
        }
        
        // Helper method to create custom pin images using Core Graphics
        private func createCustomPinImage(icon: String, color: UIColor) -> UIImage? {
            let circleDiameter: CGFloat = 44
            let pointerHeight: CGFloat = 14
            let size = CGSize(width: circleDiameter, height: circleDiameter + pointerHeight)
            let renderer = UIGraphicsImageRenderer(size: size)
            
            let image = renderer.image { context in
                let cgContext = context.cgContext
                
                // Draw the circular head
                let circleRect = CGRect(x: 0, y: 0, width: circleDiameter, height: circleDiameter)
                cgContext.setFillColor(color.cgColor)
                cgContext.addEllipse(in: circleRect)
                cgContext.fillPath()
                
                // Draw the downward triangle pointer
                let baseY = circleRect.maxY - 5 // Slight overlap with circle
                let tipPoint = CGPoint(x: size.width / 2, y: size.height)
                let leftBase = CGPoint(x: size.width / 2 - 15, y: baseY)
                let rightBase = CGPoint(x: size.width / 2 + 15, y: baseY)
                
                cgContext.beginPath()
                cgContext.move(to: tipPoint)
                cgContext.addLine(to: leftBase)
                cgContext.addLine(to: rightBase)
                cgContext.closePath()
                cgContext.setFillColor(color.cgColor)
                cgContext.fillPath()
                
                // Draw the emoji centered within the circle
                let iconString = NSString(string: icon)
                let font = UIFont.systemFont(ofSize: 20)
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.white
                ]
                let textSize = iconString.size(withAttributes: textAttributes)
                let textRect = CGRect(
                    x: (circleDiameter - textSize.width) / 2,
                    y: (circleDiameter - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                )
                iconString.draw(in: textRect, withAttributes: textAttributes)
            }
            
            return image
        }
        
        // Helper method to get appropriate activity icon with fallback logic
        private func getActivityIcon(for activity: FullFeedActivityDTO) -> String {
            // First check if the activity has its own icon
            if let activityIcon = activity.icon, !activityIcon.isEmpty {
                return activityIcon
            }
            
            // Fall back to the activity type's icon if activityTypeId exists
            if let activityTypeId = activity.activityTypeId,
               let activityType = AppCache.shared.activityTypes.first(where: { $0.id == activityTypeId }),
               !activityType.icon.isEmpty {
                return activityType.icon
            }
            
            // Final fallback to default star emoji
            return "⭐️"
        }
    }
}
