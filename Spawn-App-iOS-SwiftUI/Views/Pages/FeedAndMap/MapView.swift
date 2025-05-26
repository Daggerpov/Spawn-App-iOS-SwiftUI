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

    // MARK - Event Description State Vars
    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: FullFeedEventDTO?
    @State private var colorInPopup: Color?

    @State private var showEventCreationDrawer: Bool = false

    // for pop-ups:
    @State private var creationOffset: CGFloat = 1000

    // New state variables for filter overlay
    @State private var showFilterOverlay: Bool = false
    @State private var selectedTimeFilter: TimeFilter = .allActivities
    
    enum TimeFilter: String, CaseIterable {
        case lateNight = "Late Night"
        case evening = "Evening"
        case afternoon = "Afternoon"
        case inTheNextHour = "In the next hour"
        case happeningNow = "Happening Now"
        case allActivities = "All Activities"
    }

    // Computed property for filtered events
    private var filteredEvents: [FullFeedEventDTO] {
        let now = Date()
        let calendar = Calendar.current
        
        return viewModel.events.filter { event in
            guard let startTime = event.startTime else { return false }
            
            switch selectedTimeFilter {
            case .allActivities:
                return true
                
            case .happeningNow:
                guard let endTime = event.endTime else { return false }
                return startTime <= now && endTime >= now
                
            case .inTheNextHour:
                let oneHourFromNow = calendar.date(byAdding: .hour, value: 1, to: now)!
                return startTime > now && startTime <= oneHourFromNow
                
            case .afternoon:
                let startOfDay = calendar.startOfDay(for: startTime)
                let noonTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: startTime)!
                let eveningTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: startTime)!
                
                return startTime >= noonTime && startTime < eveningTime &&
                       calendar.isDate(startTime, inSameDayAs: now)
                
            case .evening:
                let startOfDay = calendar.startOfDay(for: startTime)
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
            VStack {
                ZStack {
                    Map(
                        coordinateRegion: $region,
                        showsUserLocation: true,
                        userTrackingMode: $userTrackingMode,
                        annotationItems: filteredEvents
                    ) { event in
                        MapAnnotation(
                            coordinate: CLLocationCoordinate2D(
                                latitude: event.location?.latitude ?? 0,
                                longitude: event.location?.longitude ?? 0
                            )
                        ) {
                            Button(action: {
                                eventInPopup = event
                                colorInPopup = eventColors.randomElement()
                                showingEventDescriptionPopup = true
                            }) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(universalAccentColor)
                            }
                        }
                    }
                    
                    // Add the filter button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showFilterOverlay = true
                            }) {
                                HStack {
									if selectedTimeFilter == .allActivities {
										Circle().fill(figmaGreen).frame(width: 10, height: 10)
									}
                                    Text(selectedTimeFilter.rawValue)
                                        .font(.onestMedium(size: 16))
                                        .foregroundColor(.black)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .cornerRadius(20)
                                .shadow(radius: 2)
                            }
                            .padding(.trailing, 16)
                        }
                        .padding(.bottom, 85)
                    }
                }
                .ignoresSafeArea()
                .dimmedBackground(
                    isActive: showEventCreationDrawer || showFilterOverlay
                )
                .overlay(
                    Group {
                        if showFilterOverlay {
                            Color.clear
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showFilterOverlay = false
                                }
                            VStack(spacing: 8) {
                                ForEach(TimeFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        selectedTimeFilter = filter
                                        showFilterOverlay = false
                                    }) {
                                        HStack {
                                            if filter == .allActivities {
                                                Circle()
                                                    .fill(figmaGreen)
                                                    .frame(width: 10, height: 10)
                                            }
                                            Text(filter.rawValue)
                                                .font(.onestMedium(size: 16))
                                                .foregroundColor(.black)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.white)
                                        )
                                    }
                                }
                            }
                            .padding()
                            .background(Color.clear)
                            .transition(.move(edge: .bottom))
                            .animation(.easeInOut, value: showFilterOverlay)
                            .frame(width: 200)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                        }
                    }
                )
            }
            .task {
                // Fetch data
                await viewModel.fetchAllData()
                
                // Focus on user location or events after data is loaded
                await MainActor.run {
                    if let userLocation = locationManager.userLocation {
                        region = MKCoordinateRegion(
                            center: userLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    } else if !viewModel.events.isEmpty {
                        adjustRegionForEvents()
                    }
                }
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                // Only update region if we're still at the default location
                if locationManager.locationUpdated && locationManager.userLocation != nil && 
                   abs(region.center.latitude - defaultMapLatitude) < 0.0001 && 
                   abs(region.center.longitude - defaultMapLongitude) < 0.0001 {
                    adjustRegionToUserLocation()
                }
            }
            .onChange(of: viewModel.events) { _ in
                // Only adjust for events if we already have user location
                if locationManager.userLocation != nil {
                    adjustRegionForEvents()
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

    private func adjustRegionForEventsOrUserLocation() {
        if let userLocation = locationManager.userLocation {
            // Prioritize user location
            withAnimation {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        } else if !viewModel.events.isEmpty {
            adjustRegionForEvents()
        }
    }

    private func adjustRegionForEvents() {
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
        EventCreationViewModel.reInitialize()
        creationOffset = 1000
        showEventCreationDrawer = false
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}
