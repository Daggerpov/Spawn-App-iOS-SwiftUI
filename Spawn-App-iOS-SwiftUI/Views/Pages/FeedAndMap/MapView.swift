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
    
    // No additional state needed for map delegate
    
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
                    // Activity Viewing Map using new refactored components
                    ActivityViewingMapView(
                        region: $region,
                        is3DMode: $is3DMode,
                        activities: filteredActivities.filter { $0.location != nil },
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
                    ActivityViewingMapControls(
                        is3DMode: $is3DMode,
                        userLocation: locationManager.userLocation,
                        onRecenterTapped: {
                            if let userLocation = locationManager.userLocation {
                                if let newRegion = ActivityViewingMapView.adjustRegionToUserLocation(userLocation) {
                                    withAnimation(.easeInOut(duration: 0.75)) {
                                        region = newRegion
                                    }
                                }
                            }
                        },
                        on3DToggled: {
                            print("🗺️ MapView: 3D mode toggled to: \(is3DMode)")
                        }
                    )
                }
            }
            .task {
                await viewModel.fetchAllData()
                await MainActor.run {
                    if let userLocation = locationManager.userLocation {
                        if let newRegion = ActivityViewingMapView.adjustRegionToUserLocation(userLocation) {
                            region = newRegion
                        }
                    } else if !viewModel.activities.isEmpty {
                        if let newRegion = ActivityViewingMapView.adjustRegionForActivities(viewModel.activities) {
                            region = newRegion
                        }
                    }
                }
            }
            .onChange(of: locationManager.locationUpdated, perform: { _ in
                if locationManager.locationUpdated && locationManager.userLocation != nil && 
                   abs(region.center.latitude - defaultMapLatitude) < 0.0001 && 
                   abs(region.center.longitude - defaultMapLongitude) < 0.0001 {
                    if let userLocation = locationManager.userLocation,
                       let newRegion = ActivityViewingMapView.adjustRegionToUserLocation(userLocation) {
                        withAnimation {
                            region = newRegion
                        }
                    }
                }
            })
            .onChange(of: viewModel.activities, perform: { _ in
                if let userLocation = locationManager.userLocation {
                    if let newRegion = ActivityViewingMapView.adjustRegionForActivities(viewModel.activities) {
                        region = newRegion
                    }
                }
            })
            .onChange(of: locationManager.locationError, perform: { error in
                if let error = error {
                    locationErrorMessage = error
                    showLocationError = true
                }
            })
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

    // Region adjustment functions are now handled by ActivityViewingMapView helper functions

    func closeCreation() {
        ActivityCreationViewModel.reInitialize()
        creationOffset = 1000
        showActivityCreationDrawer = false
    }
}

// Old ActivityMapViewRepresentable removed - now using refactored components

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
