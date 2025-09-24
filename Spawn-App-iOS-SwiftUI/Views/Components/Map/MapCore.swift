//
//  MapCore.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 12/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Core Map Configuration
struct MapConfiguration {
    let showsUserLocation: Bool
    let isZoomEnabled: Bool
    let isScrollEnabled: Bool
    let isRotateEnabled: Bool
    let showsCompass: Bool
    let showsScale: Bool
    let showsBuildings: Bool
    let isPitchEnabled: Bool
    
    static let `default` = MapConfiguration(
        showsUserLocation: true,
        isZoomEnabled: true,
        isScrollEnabled: true,
        isRotateEnabled: true,
        showsCompass: true,
        showsScale: true,
        showsBuildings: true,
        isPitchEnabled: true
    )
    
    static let locationSelection = MapConfiguration(
        showsUserLocation: true,
        isZoomEnabled: true,
        isScrollEnabled: true,
        isRotateEnabled: false, // Disable rotation for location selection
        showsCompass: false,
        showsScale: false,
        showsBuildings: true,
        isPitchEnabled: false // Keep flat for location selection
    )
}

// MARK: - Map Validation Utilities
enum MapValidationUtils {
    static func validateCoordinate(_ coordinate: CLLocationCoordinate2D) -> Bool {
        return CLLocationCoordinate2DIsValid(coordinate) &&
               coordinate.latitude.isFinite &&
               coordinate.longitude.isFinite &&
               !coordinate.latitude.isNaN &&
               !coordinate.longitude.isNaN
    }
    
    static func validateRegion(_ region: MKCoordinateRegion) -> Bool {
        return validateCoordinate(region.center) &&
               region.span.latitudeDelta > 0 &&
               region.span.longitudeDelta > 0 &&
               region.span.latitudeDelta.isFinite &&
               region.span.longitudeDelta.isFinite
    }
    
    static func createDefaultRegion() -> MKCoordinateRegion {
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Vancouver
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    static func createSafeRegion(center: CLLocationCoordinate2D, span: MKCoordinateSpan) -> MKCoordinateRegion? {
        let region = MKCoordinateRegion(center: center, span: span)
        return validateRegion(region) ? region : nil
    }
}

// MARK: - Activity Annotation
class ActivityAnnotation: NSObject, MKAnnotation {
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

// MARK: - Map Delegate Protocols (using closures instead of protocols for better SwiftUI integration)

// MARK: - Custom Pin Image Generator
enum CustomPinImageGenerator {
    static func createPinImage(icon: String, color: UIColor) -> UIImage? {
        let circleDiameter: CGFloat = 44
        let pointerHeight: CGFloat = 14
        let size = CGSize(width: circleDiameter, height: circleDiameter + pointerHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Draw the circular head
            let circleRect = CGRect(x: 0, y: 0, width: circleDiameter, height: circleDiameter)
            cgContext.setFillColor(color.cgColor)
            cgContext.addEllipse(in: circleRect)
            cgContext.fillPath()
            
            // Draw the downward triangle pointer
            let baseY = circleRect.maxY - 5
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
    }
}

// MARK: - Activity Icon Helper
enum ActivityIconHelper {
    static func getIcon(for activity: FullFeedActivityDTO) -> String {
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
