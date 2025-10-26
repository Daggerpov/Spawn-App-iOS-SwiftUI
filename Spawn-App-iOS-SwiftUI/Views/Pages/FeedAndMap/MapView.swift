//
//  MapView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/11/24.
//

import CoreLocation
import MapKit
import SwiftUI

// Uses UnifiedMapViewRepresentable from Views/Components/UnifiedMapView.swift

struct MapView: View {
    @StateObject private var viewModel: FeedViewModel
    @StateObject private var locationManager = LocationManager()

    // Region for Map - using closer zoom level
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: defaultMapLatitude, longitude: defaultMapLongitude), // Default to UBC
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )

    @State private var is3DMode: Bool = false // Only used on iOS 17+

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
    // Note: viewModel.activities already excludes past activities for feed views
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
                    // Map layer using unified component
                    UnifiedMapViewRepresentable(
                        region: $region,
                        is3DMode: $is3DMode,
                        showsUserLocation: true,
                        annotationItems: filteredActivities.filter { $0.location != nil },
                        isLocationSelectionMode: false,
                        onMapWillChange: nil,
                        onMapDidChange: { _ in },
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
                                // 3D mode toggle button (works on iOS 9+ with MapKit camera)
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
            .onChange(of: locationManager.locationUpdated) {
                if locationManager.locationUpdated && locationManager.userLocation != nil && 
                   abs(region.center.latitude - defaultMapLatitude) < 0.0001 && 
                   abs(region.center.longitude - defaultMapLongitude) < 0.0001 {
                    adjustRegionToUserLocation()
                }
            }
            .onChange(of: viewModel.activities) {
                if locationManager.userLocation != nil {
                    adjustRegionForActivities()
                }
            }
            .onChange(of: locationManager.locationError) { _, error in
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
            .onAppear {
                Task {
                    // Force refresh activities when map appears to ensure no stale data
                    await viewModel.forceRefreshActivities()
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

            // Filter buttons - positioned above nav bar
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
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 120) // Position filter above nav bar with proper spacing
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

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
