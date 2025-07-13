//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import CoreLocation
import MapKit
import SwiftUI

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

    // MARK - Activity Description State Vars
    @State private var showingActivityDescriptionPopup: Bool = false
    @State private var activityInPopup: FullFeedActivityDTO?
    @State private var colorInPopup: Color?

    @State private var showActivityCreationDrawer: Bool = false

    // for pop-ups:
    @State private var creationOffset: CGFloat = 1000

    // New state variables for filter overlay
    @State private var showFilterOverlay: Bool = false
    @State private var selectedTimeFilter: TimeFilter = .allActivities
    
    // Location error handling
    @State private var showLocationError: Bool = false
    @State private var locationErrorMessage: String = ""
    
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
                            activityInPopup = activity
                            colorInPopup = activityColors.randomElement()
                            showingActivityDescriptionPopup = true
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
                                    }
                                }
                                
                                // Location button
                                Button(action: {
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
                                }
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
            .sheet(isPresented: $showingActivityDescriptionPopup) {
                if let activity = activityInPopup, let color = colorInPopup {
                    ActivityDescriptionView(
                        activity: activity,
                        users: activity.participantUsers,
                        color: color,
                        userId: user.id
                    )
                    .presentationDragIndicator(.visible)
                }
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
        
        let newAnnotations = annotationItems.compactMap { activity -> MKPointAnnotation? in
            guard let location = activity.location else { return nil }
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            )
            annotation.title = activity.title
            return annotation
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
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }
            
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = UIColor(universalAccentColor)
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation,
               let title = annotation.title,
               let activity = parent.annotationItems.first(where: { $0.title == title }) {
                parent.onActivityTap(activity)
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
