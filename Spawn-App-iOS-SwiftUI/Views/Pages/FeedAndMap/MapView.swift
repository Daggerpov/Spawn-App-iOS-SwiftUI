//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import CoreLocation
import MapKit
import SwiftUI
import MapLibre

struct MapView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()

    // Camera state for MapLibre
    @State private var camera = CameraState(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        zoom: 10
    )

    // MARK - Event Description State Vars
    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: FullFeedEventDTO?
    @State private var colorInPopup: Color?

    @State private var showEventCreationDrawer: Bool = false

    // for pop-ups:
    @State private var creationOffset: CGFloat = 1000
    // ------------

    var user: BaseUserDTO

    init(user: BaseUserDTO) {
        self.user = user
        _viewModel = StateObject(
            wrappedValue: FeedViewModel(
                apiService: MockAPIService.isMocking
                    ? MockAPIService(userId: user.id) : APIService(),
                userId: user.id
            )
        )
    }

    var body: some View {
        ZStack {
            VStack {
                ZStack {
                    mapLibreMapView
                    VStack {
                        VStack {
                            TagsScrollView(
                                tags: viewModel.tags,
                                activeTag: $viewModel.activeTag
                            )
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        Spacer()
                    }
                    .padding(.top, 50)
                }
                .ignoresSafeArea()
                .dimmedBackground(
                    isActive: showEventCreationDrawer
                )
            }
            .onAppear {
                Task { await viewModel.fetchAllData() }
                // Try to center on user immediately if location is available
                if let userLocation = locationManager.userLocation {
                    camera.center = userLocation
                    camera.zoom = 14
                }
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                // Update map when user location becomes available
                if locationManager.locationUpdated && locationManager.userLocation != nil {
                    adjustCameraToUserLocation()
                }
            }
            .onChange(of: viewModel.events) { _ in
                // Only adjust for events if we already have user location
                if locationManager.userLocation != nil {
                    adjustCameraForEvents()
                }
            }
            .sheet(isPresented: $showingEventDescriptionPopup) {
                if let event = eventInPopup, let color = colorInPopup {
                    EventDescriptionView(
                        event: event,
                        users: event.participantUsers,
                        color: color,
                        userId: user.id
                    )
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }

    private func adjustCameraToUserLocation() {
        if let userLocation = locationManager.userLocation {
            camera.center = userLocation
            camera.zoom = 14
        }
    }

    private func adjustCameraForEventsOrUserLocation() {
        if let userLocation = locationManager.userLocation {
            // Prioritize user location
            camera.center = userLocation
            camera.zoom = 14
        } else if !viewModel.events.isEmpty {
            adjustCameraForEvents()
        }
    }

    private func adjustCameraForEvents() {
        guard !viewModel.events.isEmpty else { return }

        let latitudes = viewModel.events.compactMap { $0.location?.latitude }
        let longitudes = viewModel.events.compactMap { $0.location?.longitude }

        guard let minLatitude = latitudes.min(),
            let maxLatitude = latitudes.max(),
            let minLongitude = longitudes.min(),
            let maxLongitude = longitudes.max()
        else { return }

        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        
        // Calculate zoom level based on the bounding box
        let latitudeDelta = maxLatitude - minLatitude
        let longitudeDelta = maxLongitude - minLongitude
        
        // Use the larger delta to determine zoom (smaller zoom value = more zoomed out)
        let maxDelta = max(latitudeDelta, longitudeDelta) * 1.5
        let zoom = calculateZoomLevel(for: maxDelta)

        camera.center = CLLocationCoordinate2D(
            latitude: centerLatitude,
            longitude: centerLongitude
        )
        camera.zoom = zoom
    }
    
    // Calculate an appropriate zoom level based on coordinate delta
    private func calculateZoomLevel(for delta: Double) -> Double {
        // Roughly calculate zoom level: log2(360 / delta) + 1
        // This is an approximation for MapLibre zoom levels
        let zoom = log2(360 / delta) + 1
        return min(max(zoom, 2), 18) // Constrain between zoom levels 2-18
    }

    func closeCreation() {
        EventCreationViewModel.reInitialize()
        creationOffset = 1000
        showEventCreationDrawer = false
    }
}

extension MapView {
    var mapLibreMapView: some View {
        MapLibreEventsView(
            camera: $camera,
            events: viewModel.events,
            onEventTapped: { event in
                eventInPopup = event
                colorInPopup = eventColors.randomElement()
                showingEventDescriptionPopup = true
            }
        )
    }
}

// MapLibre View Component with event annotations
struct MapLibreEventsView: UIViewRepresentable {
    @Binding var camera: CameraState
    let events: [FullFeedEventDTO]
    let onEventTapped: (FullFeedEventDTO) -> Void
    
    func makeUIView(context: Context) -> MLNMapView {
        // Set up the style URL - using OSM style
        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        
        // Create the map view
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        
        // Enable user location
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Set initial camera position
        mapView.setCenter(camera.center, zoomLevel: camera.zoom, animated: false)
        
        // Set up delegate
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Update the camera if changed externally
        if let lastCamera = context.coordinator.lastCameraCenter,
           lastCamera.latitude != camera.center.latitude || 
           lastCamera.longitude != camera.center.longitude ||
           context.coordinator.lastZoom != camera.zoom {
            mapView.setCenter(camera.center, zoomLevel: camera.zoom, animated: true)
        }
        
        // Update event annotations
        context.coordinator.updateEventAnnotations(events, on: mapView)
        context.coordinator.events = events
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapLibreEventsView
        var events: [FullFeedEventDTO] = []
        var onEventTapped: (FullFeedEventDTO) -> Void
        var lastCameraCenter: CLLocationCoordinate2D?
        var lastZoom: Double?
        var eventAnnotations: [String: MLNPointAnnotation] = [:]
        
        init(_ parent: MapLibreEventsView) {
            self.parent = parent
            self.onEventTapped = parent.onEventTapped
            super.init()
        }
        
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            let center = mapView.centerCoordinate
            let zoom = mapView.zoomLevel
            
            // Only update if the camera has meaningfully changed
            if lastCameraCenter == nil || lastZoom == nil ||
               abs(lastCameraCenter!.latitude - center.latitude) > 0.00001 ||
               abs(lastCameraCenter!.longitude - center.longitude) > 0.00001 ||
               abs(lastZoom! - zoom) > 0.01 {
                
                lastCameraCenter = center
                lastZoom = zoom
                
                // Update the parent's camera binding
                DispatchQueue.main.async {
                    self.parent.camera.center = center
                    self.parent.camera.zoom = zoom
                }
            }
        }
        
        // Handle tapping on an annotation
        func mapView(_ mapView: MLNMapView, didSelect annotation: MLNAnnotation) {
            // Skip if it's the user location annotation
            if annotation is MLNUserLocation {
                return
            }
            
            // Find the event that corresponds to this annotation
            if let pointAnnotation = annotation as? MLNPointAnnotation,
               let identifier = pointAnnotation.title,
               let eventId = UUID(uuidString: identifier),
               let event = events.first(where: { $0.id == eventId }) {
                onEventTapped(event)
            }
            
            // Deselect the annotation to allow selecting it again later
            mapView.deselectAnnotation(annotation, animated: true)
        }
        
        func updateEventAnnotations(_ events: [FullFeedEventDTO], on mapView: MLNMapView) {
            // Track which annotations to keep
            var annotationsToKeep = Set<String>()
            
            // Add/update annotations for each event
            for event in events {
                guard let location = event.location else { continue }
                
                let eventId = event.id.uuidString
                annotationsToKeep.insert(eventId)
                
                let coordinate = CLLocationCoordinate2D(
                    latitude: location.latitude,
                    longitude: location.longitude
                )
                
                // Check if we already have an annotation for this event
                if let existingAnnotation = eventAnnotations[eventId] {
                    // Update its position if needed
                    if existingAnnotation.coordinate.latitude != coordinate.latitude ||
                       existingAnnotation.coordinate.longitude != coordinate.longitude {
                        existingAnnotation.coordinate = coordinate
                    }
                } else {
                    // Create a new annotation
                    let annotation = MLNPointAnnotation()
                    annotation.coordinate = coordinate
                    annotation.title = eventId // Store the event ID for later reference
                    
                    mapView.addAnnotation(annotation)
                    eventAnnotations[eventId] = annotation
                }
            }
            
            // Remove annotations for events that no longer exist
            let annotationsToRemove = Set(eventAnnotations.keys).subtracting(annotationsToKeep)
            for eventId in annotationsToRemove {
                if let annotation = eventAnnotations[eventId] {
                    mapView.removeAnnotation(annotation)
                    eventAnnotations.removeValue(forKey: eventId)
                }
            }
        }
        
        // Custom annotation view for events
        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            // Use default view for user location
            if annotation is MLNUserLocation {
                return nil
            }
            
            // Custom view for event pins
            let reuseId = "eventPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            
            if annotationView == nil {
                annotationView = MLNAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                annotationView?.centerOffset = CGVector(dx: 0, dy: -30) // Offset so the bottom of pin points to location
                
                // Create the custom event marker
                if let pointAnnotation = annotation as? MLNPointAnnotation,
                   let eventId = pointAnnotation.title,
                   let uuid = UUID(uuidString: eventId),
                   let event = events.first(where: { $0.id == uuid }) {
                    
                    let containerView = createEventMarkerView(for: event)
                    annotationView?.addSubview(containerView)
                }
            } else {
                annotationView?.annotation = annotation
                
                // Update the custom event marker
                for subview in annotationView?.subviews ?? [] {
                    subview.removeFromSuperview()
                }
                
                if let pointAnnotation = annotation as? MLNPointAnnotation,
                   let eventId = pointAnnotation.title,
                   let uuid = UUID(uuidString: eventId),
                   let event = events.first(where: { $0.id == uuid }) {
                    
                    let containerView = createEventMarkerView(for: event)
                    annotationView?.addSubview(containerView)
                }
            }
            
            return annotationView
        }
        
        // Helper to create the marker view for each event
        private func createEventMarkerView(for event: FullFeedEventDTO) -> UIView {
            let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 80))
            
            // Pin image
            let pinImageView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
            pinImageView.tintColor = UIColor(universalAccentColor)
            pinImageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            containerView.addSubview(pinImageView)
            
            // Profile picture inside pin
            let profileContainer = UIView(frame: CGRect(x: 10, y: 10, width: 40, height: 40))
            profileContainer.backgroundColor = .gray
            profileContainer.layer.cornerRadius = 20
            profileContainer.clipsToBounds = true
            containerView.addSubview(profileContainer)
            
            // Load profile image asynchronously
            if let profileURL = event.creatorUser.profilePicture {
                loadImage(from: profileURL) { image in
                    DispatchQueue.main.async {
                        if let image = image {
                            let imageView = UIImageView(image: image)
                            imageView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                            imageView.contentMode = .scaleAspectFill
                            profileContainer.addSubview(imageView)
                        }
                    }
                }
            }
            
            // Triangle pointer
            let triangleView = TriangleView(frame: CGRect(x: 10, y: 55, width: 40, height: 20))
            triangleView.backgroundColor = .clear
            triangleView.tintColor = UIColor(universalAccentColor)
            containerView.addSubview(triangleView)
            
            return containerView
        }
        
        // Helper to load images asynchronously
        private func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
            guard let url = URL(string: urlString) else {
                completion(nil)
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    completion(image)
                } else {
                    completion(nil)
                }
            }.resume()
        }
    }
}

// Triangle view for marker pointer
class TriangleView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.beginPath()
        context.move(to: CGPoint(x: rect.midX, y: rect.maxY))    // bottom point
        context.addLine(to: CGPoint(x: rect.minX, y: rect.minY)) // top left
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.minY)) // top right
        context.closePath()
        
        context.setFillColor(self.tintColor.cgColor)
        context.fillPath()
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
