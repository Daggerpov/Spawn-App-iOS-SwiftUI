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
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
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
                    Map(
                        coordinateRegion: $region,
                        showsUserLocation: true,
                        userTrackingMode: .constant(.follow),
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
            .task {
                // Fetch data
                await viewModel.fetchAllData()
                
                // Focus on user location after data is loaded
                await MainActor.run {
                    if let userLocation = locationManager.userLocation {
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
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                // Update map when user location becomes available
                if locationManager.locationUpdated && locationManager.userLocation != nil {
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
