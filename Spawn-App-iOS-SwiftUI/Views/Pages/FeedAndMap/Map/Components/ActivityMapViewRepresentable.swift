//
//  ActivityMapViewRepresentable.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//
import CoreLocation
import MapKit
import SwiftUI

struct ActivityMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    var annotationItems: [FullFeedActivityDTO]
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
        let mapView = MKMapView()
        
        // CRITICAL: Set map type to standard to ensure tiles load
        mapView.mapType = .standard
        
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        
        // Set additional properties for better stability
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
        // Ensure annotation interactions are enabled
        mapView.isUserInteractionEnabled = true
        
        print("🗺️ MapView created with delegate set")
        
        // Configure initial camera - MapKit camera is available on iOS 9+
        let camera = MKMapCamera(lookingAtCenter: region.center, 
                               fromDistance: 2000, // Initial distance in meters
                               pitch: 0, // Initial pitch (0 for top-down)
                               heading: 0) // Initial heading (0 for north)
        mapView.camera = camera
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep coordinator in sync with latest parent values
        context.coordinator.parent = self
        
        // 3D mode functionality works on iOS 9+ with MapKit camera
        // Get current camera state
        let currentCamera = mapView.camera
        let targetPitch = is3DMode ? 45.0 : 0.0
        
        // Only update camera if mode changed or significant location change
        let isLocationChange = abs(mapView.region.center.latitude - region.center.latitude) > 0.0001 || 
                             abs(mapView.region.center.longitude - region.center.longitude) > 0.0001
        
        if isLocationChange || abs(currentCamera.pitch - targetPitch) > 1.0 {
            // Create new camera while preserving current altitude and heading
            let newCamera = MKMapCamera(
                lookingAtCenter: region.center,
                fromDistance: max(currentCamera.altitude, 500), // Ensure minimum altitude
                pitch: targetPitch,
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
        
        // Update annotations
        let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(currentAnnotations)
        
        let newAnnotations = annotationItems.compactMap { activity -> MKAnnotation? in
            guard let location = activity.location else { return nil }
            let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            let icon = (activity.icon?.isEmpty == false) ? activity.icon! : "⭐️"
            let color = UIColor(ActivityColorService.shared.getColorForActivity(activity.id))
            return ActivityAnnotation(activityId: activity.id, title: activity.title, coordinate: coord, icon: icon, color: color)
        }
        mapView.addAnnotations(newAnnotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ActivityMapViewRepresentable
        
        init(_ parent: ActivityMapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Safely handle region changes to prevent crashes
            guard CLLocationCoordinate2DIsValid(mapView.region.center) else {
                return
            }
            
            // Only update region binding if not in 3D mode to prevent conflicts
            if !parent.is3DMode {
                DispatchQueue.main.async {
                    self.parent.region = mapView.region
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
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
            
            // Resolve activity for this annotation (ID preferred, else coordinate fallback)
            let resolvedActivity: FullFeedActivityDTO? = {
                if let activityAnnotation = annotation as? ActivityAnnotation {
                    return parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId })
                }
                // Fallback: coordinate proximity match
                let coord = annotation.coordinate
                let epsilon = 0.000001
                return parent.annotationItems.first(where: { act in
                    guard let loc = act.location else { return false }
                    return abs(loc.latitude - coord.latitude) < epsilon && abs(loc.longitude - coord.longitude) < epsilon
                })
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
            
            annotationView?.isEnabled = true
            annotationView?.canShowCallout = false
            annotationView?.isUserInteractionEnabled = true
            
            return annotationView
        }
        
        // Helper method to create custom pin images using Core Graphics
        func createCustomPinImage(icon: String, color: UIColor) -> UIImage? {
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
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let activityAnnotation = view.annotation as? ActivityAnnotation,
               let activity = parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId }) {
                parent.onActivityTap(activity)
            } else if let annotation = view.annotation {
                // Fallback: coordinate proximity match
                let coord = annotation.coordinate
                let epsilon = 0.000001
                if let activity = parent.annotationItems.first(where: { act in
                    guard let loc = act.location else { return false }
                    return abs(loc.latitude - coord.latitude) < epsilon && abs(loc.longitude - coord.longitude) < epsilon
                }) {
                    parent.onActivityTap(activity)
                } else if let title = annotation.title ?? nil {
                    if let activity = parent.annotationItems.first(where: { $0.title == title }) {
                        parent.onActivityTap(activity)
                    }
                }
            }
        }
        
        // Helper method to get appropriate activity icon with fallback logic
        func getActivityIcon(for activity: FullFeedActivityDTO) -> String {
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
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            print("🗺️ Map pin deselected!")
        }
        
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            // This delegate method is called when MapKit finishes loading and rendering the map
            print("✅ ActivityMapViewRepresentable: Map tiles finished loading")
        }
        
        func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
            // This is called when the map finishes rendering
            if fullyRendered {
                print("✅ ActivityMapViewRepresentable: Map fully rendered")
            }
        }
        
    }
}

