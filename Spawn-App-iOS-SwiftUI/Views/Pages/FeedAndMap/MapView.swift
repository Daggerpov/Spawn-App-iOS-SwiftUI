//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import CoreLocation
import MapKit
import SwiftUI

// MARK: - Custom Activity Pin View
struct ActivityPinView: View {
    let icon: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Pin background with drop shadow
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
            
            // Activity icon
            Text(icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()

    // Region for Map - using closer zoom level
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: defaultMapLatitude, longitude: defaultMapLongitude), // Default to UBC
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    // Add state for tracking mode
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var is3DMode: Bool = false

    // MARK - Activity Description State Vars - now using global popup system

    @State private var showActivityCreationDrawer: Bool = false

    // for pop-ups:
    @State private var creationOffset: CGFloat = 1000

    // New state variables for filter overlay
    @State private var showFilterOverlay: Bool = false
    @State private var selectedTimeFilter: TimeFilter = .allActivities
    
    // Location error handling
    @State private var showLocationError: Bool = false
    @State private var locationErrorMessage: String = ""
    
    // Animation states for 3D effects on map control buttons
    @State private var toggle3DPressed = false
    @State private var toggle3DScale: CGFloat = 1.0
    @State private var locationPressed = false
    @State private var locationScale: CGFloat = 1.0
    
    enum TimeFilter: String, CaseIterable {
        case lateNight = "Late Night"
        case evening = "Evening"
        case afternoon = "Afternoon"
        case inTheNextHour = "In the next hour"
        case happeningNow = "Happening Now"
        case allActivities = "All Activities"
    }

    // Computed property for filtered activities
    private var filteredActivities: [FullFeedActivityDTO] {
        let now = Date()
        let calendar = Calendar.current
        
        let filtered = viewModel.activities.filter { activity in
            guard let startTime = activity.startTime else { return false }
            
            switch selectedTimeFilter {
            case .allActivities:
                return true
                
            case .happeningNow:
                guard let endTime = activity.endTime else { return false }
                return startTime <= now && endTime >= now
                
            case .inTheNextHour:
                let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: now)!
                return startTime > now && startTime <= oneHourFromNow
                
            case .afternoon:
					_ = calendar.startOfDay(for: startTime)
                let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startTime)!
                let eveningTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startTime)!
                
                return startTime >= noonTime && startTime < eveningTime &&
                       calendar.isDate(startTime, inSameDayAs: now)
                
            case .evening:
					_ = calendar.startOfDay(for: startTime)
                let eveningTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startTime)!
                let nightTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: startTime)!
                
                return startTime >= eveningTime && startTime < nightTime &&
                       calendar.isDate(startTime, inSameDayAs: now)
                
            case .lateNight:
                let startOfDay = calendar.startOfDay(for: startTime)
                let nightTime = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: startTime)!
                let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                return (startTime >= nightTime && startTime < nextDay) ||
                       (startTime >= startOfDay && startTime < calendar.date(bySettingHour: 4, minute: 0, second: 0, of: startTime)!)
            }
        }
        
        return filtered
    }

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
            // Base layer - Map and its components
            VStack {
                ZStack {
                    // Map layer
                    ActivityMapViewRepresentable(
                        region: $region,
                        is3DMode: $is3DMode,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: filteredActivities.filter { $0.location != nil },
                        onActivityTap: { activity in
                            // Use global popup system with fromMapView flag
                            NotificationCenter.default.post(
                                name: .showGlobalActivityPopup,
                                object: nil,
                                userInfo: [
                                    "activity": activity, 
                                    "color": ActivityColorService.shared.getColorForActivity(activity.id),
                                    "fromMapView": true
                                ]
                            )
                        }
                    )
                    .ignoresSafeArea()

                    // Top control buttons
                    VStack {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                // 3D mode toggle button (iOS 17+ only)
                                if #available(iOS 17.0, *) {
                                    Button(action: {
                                        // Haptic feedback
                                        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                        impactGenerator.impactOccurred()
                                        
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            is3DMode.toggle()
                                        }
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
                                }
                                
                                // Location button
                                Button(action: {
                                    // Haptic feedback
                                    let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                    impactGenerator.impactOccurred()
                                    
                                    if let userLocation = locationManager.userLocation {
                                        withAnimation(.easeInOut(duration: 0.75)) {
                                            region = MKCoordinateRegion(
                                                center: userLocation,
                                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                            )
                                        }
                                    }
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
                            }
                            .padding(.trailing, 16)
                        }
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                }
            }
            .task {
                await viewModel.fetchAllData()
                await MainActor.run {
                    if let userLocation = locationManager.userLocation {
                        region = MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    } else if !viewModel.activities.isEmpty {
                        adjustRegionForActivities()
                    }
                }
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                if locationManager.locationUpdated && locationManager.userLocation != nil && 
                   abs(region.center.latitude - defaultMapLatitude) < 0.0001 && 
                   abs(region.center.longitude - defaultMapLongitude) < 0.0001 {
                    adjustRegionToUserLocation()
                }
            }
            .onChange(of: viewModel.activities) { _ in
                if locationManager.userLocation != nil {
                    adjustRegionForActivities()
                }
            }
            .onChange(of: locationManager.locationError) { error in
                if let error = error {
                    locationErrorMessage = error
                    showLocationError = true
                }
            }
            .alert("Location Error", isPresented: $showLocationError) {
                Button("OK") {
                    showLocationError = false
                }
                if locationManager.authorizationStatus == .denied {
                    Button("Settings") {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }
                }
            } message: {
                Text(locationErrorMessage)
            }


            // Dimming overlay
            if showActivityCreationDrawer || showFilterOverlay {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut, value: showActivityCreationDrawer || showFilterOverlay)
                    .blur(radius: 0) // Ensure overlay itself isn't blurred
            }

            // Base content blur when filters are shown
            if showFilterOverlay {
                Rectangle()
                    .fill(.clear)
					.background(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeInOut, value: showFilterOverlay)
            }

            // Filter overlay and buttons
            if showFilterOverlay {
                // Clear overlay for dismissal
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showFilterOverlay = false
                        }
                    }
            }

            // Filter buttons - always on top
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        if showFilterOverlay {
                            // Show "All Activities" at the top if it's not currently selected
                            if selectedTimeFilter != .allActivities {
                                Button(action: {
                                    print("Filter selected: All Activities")
                                    withAnimation(.spring()) {
                                        selectedTimeFilter = .allActivities
                                        showFilterOverlay = false
                                    }
                                }) {
                                    HStack {
                                        Text(TimeFilter.allActivities.rawValue)
                                            .font(.onestMedium(size: 16))
                                            .foregroundColor(universalAccentColor)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(universalBackgroundColor)
                                    .cornerRadius(20)
                                }
                            }
                            
                            // Show all other filters except the currently selected one and "All Activities"
                            ForEach(Array(TimeFilter.allCases.dropLast().filter { $0 != selectedTimeFilter }).reversed(), id: \.self) { filter in
                                Button(action: {
                                    print("Filter selected: \(filter.rawValue)")
                                    withAnimation(.spring()) {
                                        selectedTimeFilter = filter
                                        showFilterOverlay = false
                                    }
                                }) {
                                    HStack {
                                        Text(filter.rawValue)
                                            .font(.onestMedium(size: 16))
                                            .foregroundColor(universalAccentColor)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(universalBackgroundColor)
                                    .cornerRadius(20)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        
                        Button(action: {
                            withAnimation(.spring()) {
                                showFilterOverlay.toggle()
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(figmaGreen)
                                    .frame(width: 10, height: 10)
                                Text(selectedTimeFilter.rawValue)
                                    .font(.onestMedium(size: 16))
                                    .foregroundColor(universalAccentColor)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(universalBackgroundColor)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        }
                    }
                    .frame(maxWidth: 155)
                    .padding(.trailing)
                }
                .padding(.bottom)
            }
        }
    }

    private func adjustRegionToUserLocation() {
        if let userLocation = locationManager.userLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }

    private func adjustRegionForActivitiesOrUserLocation() {
        if let userLocation = locationManager.userLocation {
            // Prioritize user location
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        } else if !viewModel.activities.isEmpty {
            adjustRegionForActivities()
        }
    }

    private func adjustRegionForActivities() {
        guard !viewModel.activities.isEmpty else { return }
        
        let latitudes = viewModel.activities.compactMap { $0.location?.latitude }
        let longitudes = viewModel.activities.compactMap { $0.location?.longitude }
        
        guard let minLatitude = latitudes.min(),
              let maxLatitude = latitudes.max(),
              let minLongitude = longitudes.min(),
              let maxLongitude = longitudes.max()
        else { return }
        
        let centerLatitude = (minLatitude + maxLatitude) / 2
        let centerLongitude = (minLongitude + maxLongitude) / 2
        let latitudeDelta = (maxLatitude - minLatitude) * 1.5  // Add padding
        let longitudeDelta = (maxLongitude - minLongitude) * 1.5  // Add padding
        
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: centerLatitude,
                    longitude: centerLongitude
                ),
                span: MKCoordinateSpan(
                    latitudeDelta: max(latitudeDelta, 0.01),
                    longitudeDelta: max(longitudeDelta, 0.01)
                )
            )
        }
    }

    func closeCreation() {
        ActivityCreationViewModel.reInitialize()
        creationOffset = 1000
        showActivityCreationDrawer = false
    }
}

// MARK: - ActivityMapViewRepresentable
struct ActivityMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var is3DMode: Bool
    var userTrackingMode: Binding<MapUserTrackingMode>
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
        
        if #available(iOS 17.0, *) {
            // Configure initial camera safely
            let camera = MKMapCamera(lookingAtCenter: region.center, 
                                   fromDistance: 2000, // Initial distance in meters
                                   pitch: 0, // Initial pitch (0 for top-down)
                                   heading: 0) // Initial heading (0 for north)
            mapView.camera = camera
        } else {
            // For iOS 16 and below, just set the region
            mapView.setRegion(region, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Keep coordinator in sync with latest parent values
        context.coordinator.parent = self
        
        if #available(iOS 17.0, *) {
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
        } else {
            // For iOS 16 and below, just update the region
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
            
            if #available(iOS 17.0, *) {
                // Only update region binding if not in 3D mode
                if !parent.is3DMode {
                    DispatchQueue.main.async {
                        self.parent.region = mapView.region
                    }
                }
            } else {
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
                let activityIcon = (resolvedActivity.icon?.isEmpty == false) ? resolvedActivity.icon! : "⭐️"
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
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            print("🗺️ Map pin deselected!")
        }
        
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
