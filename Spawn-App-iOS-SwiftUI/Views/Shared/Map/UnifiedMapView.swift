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
// Simplified version with reduced logging and simplified rendering
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
    var onMapLoaded: (() -> Void)?
    
    // Custom annotation type
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
        mapView.mapType = .standard
        mapView.showsUserLocation = showsUserLocation
        mapView.delegate = context.coordinator
        
        // Basic settings
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = false // Disable scale for slight performance gain
        
        // Set initial region
        if CLLocationCoordinate2DIsValid(region.center) &&
           region.span.latitudeDelta > 0 && region.span.longitudeDelta > 0 {
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.parent = self
        
        // Update region if changed significantly
        let regionDiff = abs(mapView.region.center.latitude - region.center.latitude) + 
                        abs(mapView.region.center.longitude - region.center.longitude)
        
        if regionDiff > 0.001 {
            if is3DMode, #available(iOS 17.0, *) {
                let camera = MKMapCamera(
                    lookingAtCenter: region.center,
                    fromDistance: max(mapView.camera.altitude, 500),
                    pitch: isLocationSelectionMode ? 0.0 : 45.0,
                    heading: mapView.camera.heading
                )
                mapView.setCamera(camera, animated: true)
            } else {
                mapView.setRegion(region, animated: true)
            }
        }
        
        // Update annotations if not in location selection mode
        if !isLocationSelectionMode {
            let newActivityIDs = Set(annotationItems.map { $0.id })
            if context.coordinator.lastAnnotationIDs != newActivityIDs {
                let currentAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
                mapView.removeAnnotations(currentAnnotations)
                
                let newAnnotations = annotationItems.compactMap { activity -> ActivityAnnotation? in
                    guard let location = activity.location else { return nil }
                    let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                    let icon = activity.icon ?? "⭐️"
                    let color = UIColor(ActivityColorService.shared.getColorForActivity(activity.id))
                    return ActivityAnnotation(activityId: activity.id, title: activity.title, coordinate: coord, icon: icon, color: color)
                }
                mapView.addAnnotations(newAnnotations)
                context.coordinator.lastAnnotationIDs = newActivityIDs
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: UnifiedMapViewRepresentable
        var lastAnnotationIDs: Set<UUID> = []
        
        init(_ parent: UnifiedMapViewRepresentable) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            parent.onMapWillChange?()
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            guard CLLocationCoordinate2DIsValid(mapView.region.center) else { return }
            
            if parent.isLocationSelectionMode {
                parent.region = mapView.region
            }
            parent.onMapDidChange?(mapView.region.center)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation || parent.isLocationSelectionMode {
                return nil
            }
            
            let identifier = "ActivityPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKAnnotationView
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            // Create custom pin image
            if let activityAnnotation = annotation as? ActivityAnnotation {
                if let customImage = createCustomPinImage(icon: activityAnnotation.activityIcon, color: activityAnnotation.activityUIColor) {
                    annotationView?.image = customImage
                    annotationView?.centerOffset = CGPoint(x: 0, y: -customImage.size.height / 2)
                }
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard !parent.isLocationSelectionMode,
                  let activityAnnotation = view.annotation as? ActivityAnnotation,
                  let activity = parent.annotationItems.first(where: { $0.id == activityAnnotation.activityId }) else {
                return
            }
            parent.onActivityTap(activity)
        }
        
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.onMapLoaded?()
            }
        }
        
        // Simplified custom pin image creation
        private func createCustomPinImage(icon: String, color: UIColor) -> UIImage? {
            let diameter: CGFloat = 40
            let pointerHeight: CGFloat = 12
            let size = CGSize(width: diameter, height: diameter + pointerHeight)
            
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                let cgContext = context.cgContext
                
                // Circle
                cgContext.setFillColor(color.cgColor)
                cgContext.fillEllipse(in: CGRect(x: 0, y: 0, width: diameter, height: diameter))
                
                // Triangle pointer
                let tipPoint = CGPoint(x: diameter / 2, y: size.height)
                let leftBase = CGPoint(x: diameter / 2 - 12, y: diameter - 4)
                let rightBase = CGPoint(x: diameter / 2 + 12, y: diameter - 4)
                
                cgContext.beginPath()
                cgContext.move(to: tipPoint)
                cgContext.addLine(to: leftBase)
                cgContext.addLine(to: rightBase)
                cgContext.closePath()
                cgContext.fillPath()
                
                // Icon
                let iconString = NSString(string: icon)
                let textAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18),
                    .foregroundColor: UIColor.white
                ]
                let textSize = iconString.size(withAttributes: textAttributes)
                iconString.draw(in: CGRect(
                    x: (diameter - textSize.width) / 2,
                    y: (diameter - textSize.height) / 2,
                    width: textSize.width,
                    height: textSize.height
                ), withAttributes: textAttributes)
            }
        }
    }
}
