//
//  ActivityViewingMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 12/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Activity Viewing Map View
struct ActivityViewingMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    let activities: [FullFeedActivityDTO]
    
    // Callbacks
    var onMapWillChange: (() -> Void)?
    var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    var onActivityTap: ((FullFeedActivityDTO) -> Void)?
    
    var body: some View {
        ActivityViewingMapRepresentable(
            region: $region,
            is3DMode: $is3DMode,
            activities: activities,
            onMapWillChange: onMapWillChange,
            onMapDidChange: onMapDidChange,
            onActivityTap: onActivityTap
        )
    }
}

// MARK: - Activity Viewing Map Representable
private struct ActivityViewingMapRepresentable: View {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    let activities: [FullFeedActivityDTO]
    
    // Callbacks
    var onMapWillChange: (() -> Void)?
    var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    var onActivityTap: ((FullFeedActivityDTO) -> Void)?
    
    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                ModernMapView(
                    region: $region,
                    is3DMode: $is3DMode,
                    configuration: .default,
                    annotationItems: activities,
                    isLocationSelectionMode: false,
                    onMapWillChange: onMapWillChange,
                    onMapDidChange: onMapDidChange,
                    onActivityTap: onActivityTap
                )
            } else {
                BaseMapView(
                    region: $region,
                    is3DMode: $is3DMode,
                    configuration: .default,
                    annotationItems: activities,
                    isLocationSelectionMode: false,
                    onMapWillChange: onMapWillChange,
                    onMapDidChange: onMapDidChange,
                    onActivityTap: onActivityTap
                )
            }
        }
    }
}

// MARK: - Activity Viewing Map Controls
struct ActivityViewingMapControls: View {
    @Binding var is3DMode: Bool
    let userLocation: CLLocationCoordinate2D?
    let onRecenterTapped: () -> Void
    let on3DToggled: () -> Void
    
    // Animation states for 3D effects
    @State private var toggle3DPressed = false
    @State private var toggle3DScale: CGFloat = 1.0
    @State private var locationPressed = false
    @State private var locationScale: CGFloat = 1.0
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    // 3D mode toggle button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            is3DMode.toggle()
                        }
                        on3DToggled()
                    }) {
                        Image(systemName: is3DMode ? "view.3d" : "view.2d")
                            .font(.system(size: 18))
                            .foregroundColor(universalAccentColor)
                            .padding(12)
                            .background(universalBackgroundColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .scaleEffect(toggle3DScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.15), value: toggle3DScale)
                    .animation(.easeInOut(duration: 0.15), value: toggle3DPressed)
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        toggle3DPressed = pressing
                        toggle3DScale = pressing ? 0.95 : 1.0
                        
                        // Additional haptic feedback for press down
                        if pressing {
                            let selectionGenerator = UISelectionFeedbackGenerator()
                            selectionGenerator.selectionChanged()
                        }
                    }, perform: {})
                    
                    // Location button
                    Button(action: {
                        // Haptic feedback
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        
                        onRecenterTapped()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18))
                            .foregroundColor(universalAccentColor)
                            .padding(12)
                            .background(universalBackgroundColor)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                            .scaleEffect(locationScale)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .animation(.easeInOut(duration: 0.15), value: locationScale)
                    .animation(.easeInOut(duration: 0.15), value: locationPressed)
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                        locationPressed = pressing
                        locationScale = pressing ? 0.95 : 1.0
                        
                        // Additional haptic feedback for press down
                        if pressing {
                            let selectionGenerator = UISelectionFeedbackGenerator()
                            selectionGenerator.selectionChanged()
                        }
                    }, perform: {})
                    .disabled(userLocation == nil)
                    .opacity(userLocation == nil ? 0.6 : 1.0)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

// MARK: - Activity Map Helper Functions
extension ActivityViewingMapView {
    
    // MARK: - Region Adjustment Functions
    static func adjustRegionToUserLocation(_ userLocation: CLLocationCoordinate2D) -> MKCoordinateRegion? {
        guard MapValidationUtils.validateCoordinate(userLocation) else {
            print("⚠️ ActivityViewingMapView: Invalid user location for region adjustment")
            return nil
        }
        
        return MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    static func adjustRegionForActivities(_ activities: [FullFeedActivityDTO]) -> MKCoordinateRegion? {
        guard !activities.isEmpty else { return nil }
        
        let validLocations = activities.compactMap { activity -> CLLocationCoordinate2D? in
            guard let location = activity.location else { return nil }
            let coord = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
            return MapValidationUtils.validateCoordinate(coord) ? coord : nil
        }
        
        guard !validLocations.isEmpty else { return nil }
        
        let latitudes = validLocations.map { $0.latitude }
        let longitudes = validLocations.map { $0.longitude }
        
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max()
        else { return nil }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let latitudeDelta = (maxLatitude - minLatitude) * 1.5  // Add padding
        let longitudeDelta = (maxLongitude - minLongitude) * 1.5  // Add padding
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLatitude,
                longitude: centerLongitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(latitudeDelta, 0.01),
                longitudeDelta: max(longitudeDelta, 0.01)
            )
        )
        
        return MapValidationUtils.validateRegion(region) ? region : nil
    }
    
    static func adjustRegionForActivitiesOrUserLocation(
        activities: [FullFeedActivityDTO],
        userLocation: CLLocationCoordinate2D?
    ) -> MKCoordinateRegion? {
        if let userLocation = userLocation {
            // Prioritize user location
            return adjustRegionToUserLocation(userLocation)
        } else if !activities.isEmpty {
            return adjustRegionForActivities(activities)
        }
        return nil
    }
}
