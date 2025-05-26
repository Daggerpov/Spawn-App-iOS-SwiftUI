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
        center: CLLocationCoordinate2D(latitude: 49.26468617023799, longitude: -123.25859833051356), // Default to UBC
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
                        annotationItems: viewModel.events
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
                                    Text(selectedTimeFilter.rawValue)
                                        .font(.onestMedium(size: 16))
                                        .foregroundColor(.black)
                                    Image(systemName: "chevron.up")
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
                        .padding(.bottom, 16)
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
                                ForEach(TimeFilter.allCases.reversed(), id: \.self) { filter in
                                    Button(action: {
                                        selectedTimeFilter = filter
                                        showFilterOverlay = false
                                    }) {
                                        Text(filter.rawValue)
                                            .font(.onestMedium(size: 16))
                                            .foregroundColor(.black)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
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
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                        }
                    }
                )
            }
            .task {
                // Fetch data
                await viewModel.fetchAllData()
                
                // Focus on user location only on initial load
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
                // Only update region if we haven't set it yet
                if locationManager.locationUpdated && locationManager.userLocation != nil && region.center.latitude == 49.26468617023799 {
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
