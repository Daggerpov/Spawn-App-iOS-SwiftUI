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

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 0,
            longitude: 0
        ),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    // MARK - Event Description State Vars
    @State private var showingEventDescriptionPopup: Bool = false
    @State private var eventInPopup: FullFeedEventDTO?
    @State private var colorInPopup: Color?

    @State private var showEventCreationDrawer: Bool = false

    // for pop-ups:
    @State private var descriptionOffset: CGFloat = 1500
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
                    mapView
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
                    isActive: showEventCreationDrawer || showingEventDescriptionPopup
                )
            }
            .onAppear {
                Task { await viewModel.fetchAllData() }
                // Try to center on user immediately if location is available
                if let userLocation = locationManager.userLocation {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
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
            if showingEventDescriptionPopup {
                eventDescriptionPopupView
            }
        }
    }

    private func adjustRegionToUserLocation() {
        if let userLocation = locationManager.userLocation {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(
                    latitudeDelta: 0.01,
                    longitudeDelta: 0.01
                )
            )
        }
    }

    private func adjustRegionForEventsOrUserLocation() {
        if let userLocation = locationManager.userLocation {
            // Prioritize user location
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
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

    func closeDescription() {
        descriptionOffset = 500
        showingEventDescriptionPopup = false
    }

    func closeCreation() {
        EventCreationViewModel.reInitialize()
        creationOffset = 1000
        showEventCreationDrawer = false
    }
}

extension MapView {
    var mapView: some View {
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
                ),
                anchorPoint: CGPoint(x: 0.5, y: 1.0)
            ) {
                Button(action: {
                    eventInPopup = event
                    colorInPopup = eventColors.randomElement()
                    showingEventDescriptionPopup = true
                }) {
                    VStack(spacing: -8) {
                        ZStack {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(universalAccentColor)

                            if let pfpUrl = event.creatorUser.profilePicture {
                                AsyncImage(url: URL(string: pfpUrl)) {
                                    image in
                                    image
                                        .ProfileImageModifier(
                                            imageType: .mapView
                                        )
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 40, height: 40)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 40, height: 40)
                            }
                        }
                        Triangle()
                            .fill(universalAccentColor)
                            .frame(width: 40, height: 20)
                    }
                }
            }
        }
        .ignoresSafeArea()

    }

    var eventDescriptionPopupView: some View {
        Group {
            if let event = eventInPopup, let color = colorInPopup {
                ZStack {
                    Color(.black)
                        .opacity(0.5)
                        .onTapGesture {
                            closeDescription()
                        }

                    EventDescriptionView(
                        event: event,
                        users: event.participantUsers,
                        color: color,
                        userId: user.id
                    )
                    .offset(x: 0, y: descriptionOffset)
                    .onAppear {
                        descriptionOffset = 0
                    }
                    .padding(.horizontal)
                    // brute-force algorithm I wrote
                    .padding(
                        .vertical,
                        max(
                            330,
                            330
                                - CGFloat(
                                    100 * (event.chatMessages?.count ?? 0)
                                )
                                - CGFloat(event.note != nil ? 200 : 0)
                        )
                    )
                }
                .ignoresSafeArea()
            }
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    MapView(user: .danielAgapov).environmentObject(appCache)
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
