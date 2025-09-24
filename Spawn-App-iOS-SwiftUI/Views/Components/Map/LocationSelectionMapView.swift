//
//  LocationSelectionMapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 12/22/24.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Location Selection Map View
struct LocationSelectionMapView: View {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    
    // Callbacks
    var onMapWillChange: (() -> Void)?
    var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    
    var body: some View {
        LocationSelectionMapRepresentable(
            region: $region,
            is3DMode: $is3DMode,
            onMapWillChange: onMapWillChange,
            onMapDidChange: onMapDidChange
        )
    }
}

// MARK: - Location Selection Map Representable
private struct LocationSelectionMapRepresentable: View {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    
    // Callbacks
    var onMapWillChange: (() -> Void)?
    var onMapDidChange: ((CLLocationCoordinate2D) -> Void)?
    
    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                ModernMapView(
                    region: $region,
                    is3DMode: $is3DMode,
                    configuration: .locationSelection,
                    annotationItems: [], // No activities in location selection
                    isLocationSelectionMode: true,
                    onMapWillChange: onMapWillChange,
                    onMapDidChange: onMapDidChange,
                    onActivityTap: nil
                )
            } else {
                BaseMapView(
                    region: $region,
                    is3DMode: $is3DMode,
                    configuration: .locationSelection,
                    annotationItems: [], // No activities in location selection
                    isLocationSelectionMode: true,
                    onMapWillChange: onMapWillChange,
                    onMapDidChange: onMapDidChange,
                    onActivityTap: nil
                )
            }
        }
    }
}

// MARK: - Location Selection Pin Overlay
struct LocationSelectionPinOverlay: View {
    @State private var baseEllipseScale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var pinOffset: CGFloat = 0
    @State private var pinScale: CGFloat = 1.0
    @State private var isMapMoving = false
    
    var body: some View {
        VStack {
            Spacer()
            ZStack {
                // Base ellipse under the pin
                Ellipse()
                    .fill(Color(red: 0.15, green: 0.55, blue: 1))
                    .frame(width: 19.90, height: 9.95)
                    .scaleEffect(baseEllipseScale)
                    .opacity(0.9)
                    .shadow(
                        color: Color.black.opacity(0.25),
                        radius: 12,
                        x: 0,
                        y: 3
                    )
                    .offset(y: 18)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.85),
                        value: baseEllipseScale
                    )
                
                // Expanding pulse when dropped
                Ellipse()
                    .fill(Color(red: 0.15, green: 0.55, blue: 1))
                    .frame(width: 19.90, height: 9.95)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
                    .offset(y: 18)
                
                // Pin icon
                Image(systemName: "mappin")
                    .font(.system(size: 34))
                    .foregroundColor(.blue)
                    .scaleEffect(pinScale)
                    .offset(y: pinOffset)
                    .shadow(
                        color: .black.opacity(isMapMoving ? 0.35 : 0.25),
                        radius: isMapMoving ? 8 : 6,
                        x: 0,
                        y: isMapMoving ? 6 : 3
                    )
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.8),
                        value: isMapMoving
                    )
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.8),
                        value: pinOffset
                    )
                    .animation(
                        .spring(response: 0.25, dampingFraction: 0.8),
                        value: pinScale
                    )
            }
            Spacer()
        }
        .allowsHitTesting(false) // Prevent pin from blocking gestures
    }
    
    // MARK: - Public Animation Methods
    func startMapMoving() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            isMapMoving = true
            pinOffset = -8
            pinScale = 1.1
            baseEllipseScale = 0.8
        }
    }
    
    func stopMapMoving() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isMapMoving = false
            pinOffset = 0
            pinScale = 1.0
            baseEllipseScale = 1.0
        }
        
        // Pulse animation when pin drops
        withAnimation(.easeOut(duration: 0.6)) {
            pulseScale = 2.0
            pulseOpacity = 0.6
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.5)) {
                pulseScale = 1.0
                pulseOpacity = 0.0
            }
        }
    }
}

// MARK: - Location Selection Map Controls
struct LocationSelectionMapControls: View {
    @Binding var is3DMode: Bool
    let userLocation: CLLocationCoordinate2D?
    let onRecenterTapped: () -> Void
    let on3DToggled: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    // 3D mode toggle (works on iOS 9+ with MapKit camera)
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        withAnimation(.easeInOut(duration: 0.3)) {
                            is3DMode.toggle()
                        }
                        on3DToggled()
                    }) {
                        Image(systemName: is3DMode ? "view.3d" : "view.2d")
                            .font(.system(size: 20))
                            .foregroundColor(universalAccentColor)
                            .padding(12)
                            .background(universalBackgroundColor)
                            .clipShape(Circle())
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Recenter to user location
                    Button(action: {
                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                        impactGenerator.impactOccurred()
                        onRecenterTapped()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(universalAccentColor)
                            .padding(12)
                            .background(universalBackgroundColor)
                            .clipShape(Circle())
                            .shadow(
                                color: Color.black.opacity(0.2),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(userLocation == nil)
                    .opacity(userLocation == nil ? 0.6 : 1.0)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 24)
            Spacer()
        }
    }
}
