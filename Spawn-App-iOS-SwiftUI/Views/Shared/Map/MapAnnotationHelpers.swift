//
//  MapAnnotationHelpers.swift
//  Spawn-App-iOS-SwiftUI
//
//  Shared map annotation helpers and utilities
//

import MapKit
import SwiftUI
import CoreLocation

// MARK: - Activity Annotation

/// Custom annotation type that carries the activity data needed for rendering
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

// MARK: - Map Annotation Utilities

enum MapAnnotationHelpers {
    
    /// Creates a custom pin image with an icon and color using Core Graphics
    /// - Parameters:
    ///   - icon: The emoji or text to display on the pin
    ///   - color: The color of the pin
    /// - Returns: A UIImage of the custom pin, or nil if creation fails
    static func createCustomPinImage(icon: String, color: UIColor) -> UIImage? {
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
    
    /// Gets the appropriate icon for an activity with fallback logic
    /// - Parameter activity: The activity to get the icon for
    /// - Returns: The icon string (emoji) for the activity
    static func getActivityIcon(for activity: FullFeedActivityDTO) -> String {
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

