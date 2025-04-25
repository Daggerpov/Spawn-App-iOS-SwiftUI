import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionView: View {
    @EnvironmentObject var viewModel: EventCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false
    @State private var pinLocation: CLLocationCoordinate2D?
    @State private var locationName: String = ""
    @StateObject private var locationManager = LocationManager()
    
    // Add these for tracking map changes
    @State private var lastMapMoveTime = Date()
    @State private var isDraggingMap = false
    @State private var mapMovementTimer: Timer?
    @State private var lastCenterLatitude: Double = 0
    @State private var lastCenterLongitude: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                mapView
                    .ignoresSafeArea()
                
                VStack {
                    searchBarView
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if isSearching && !searchResults.isEmpty {
                        searchResultsView
                            .background(Color(.systemBackground).opacity(0.95))
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Center on user location button
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                if let userLocation = locationManager.userLocation {
                                    region = MKCoordinateRegion(
                                        center: userLocation,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                    updatePinLocation()
                                }
                            }) {
                                Image(systemName: "location.fill")
                                    .padding(12)
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 2)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        }
                    }
                    
                    if pinLocation != nil {
                        VStack {
                            locationNameInputView
                                .padding(.horizontal)
                            
                            Button(action: {
                                saveLocation()
                                dismiss()
                            }) {
                                Text("Confirm Location")
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(locationName.isEmpty ? Color.gray : universalSecondaryColor)
                                    .cornerRadius(15)
                                    .padding(.horizontal)
                                    .padding(.bottom)
                            }
                            .disabled(locationName.isEmpty)
                        }
                        .background(Color(.systemBackground).opacity(0.95))
                    }
                }
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let userLocation = locationManager.userLocation {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                
                // If there's an existing location, show it
                if let existingLocation = viewModel.event.location,
                   existingLocation.latitude != 0,
                   existingLocation.longitude != 0 {
                    
                    pinLocation = CLLocationCoordinate2D(
                        latitude: existingLocation.latitude,
                        longitude: existingLocation.longitude
                    )
                    locationName = existingLocation.name
                    
                    region = MKCoordinateRegion(
                        center: pinLocation!,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                
                // Start a timer to check for map movements
                mapMovementTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                    let now = Date()
                    if isDraggingMap && now.timeIntervalSince(lastMapMoveTime) > 0.3 {
                        // It's been more than 0.3 seconds since the last movement, assume dragging stopped
                        isDraggingMap = false
                        self.updatePinLocation()
                    }
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                mapMovementTimer?.invalidate()
                mapMovementTimer = nil
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                if locationManager.locationUpdated && locationManager.userLocation != nil && pinLocation == nil {
                    updateRegionWithUserLocation()
                }
            }
        }
    }
    
    private func updateRegionWithUserLocation() {
        if let userLocation = locationManager.userLocation {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func searchLocations() {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = region
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                self.searchResults = []
                return
            }
            
            self.searchResults = response.mapItems
        }
    }
    
    func updatePinLocation() {
        // Use DispatchQueue to avoid modifying state during view update
        DispatchQueue.main.async {
            let mapCenter = region.center
            pinLocation = mapCenter
            
            // If we don't have a location name from search, get it from reverse geocoding
            if selectedMapItem == nil {
                reverseGeocode(coordinate: mapCenter)
            }
        }
    }
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        DispatchQueue.main.async {
            selectedMapItem = mapItem
            locationName = mapItem.name ?? ""
            pinLocation = mapItem.placemark.coordinate
            
            region = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
            
            searchText = locationName
            isSearching = false
            searchResults = []
        }
    }
    
    private func saveLocation() {
        guard let pinLocation = pinLocation, !locationName.isEmpty else { return }
        
        let location = Location(
            id: viewModel.event.location?.id ?? UUID(),
            name: locationName,
            latitude: pinLocation.latitude,
            longitude: pinLocation.longitude
        )
        
        DispatchQueue.main.async {
            viewModel.event.location = location
            Task {
                await viewModel.validateEventForm()
            }
        }
    }
}

// MARK: - View Components
extension LocationSelectionView {
    var mapView: some View {
        ZStack {
            Map(
                coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: .constant(.follow),
                annotationItems: pinLocation != nil ? [PinAnnotation(coordinate: pinLocation!)] : []
            ) { annotation in
                MapAnnotation(coordinate: annotation.coordinate) {
                    VStack(spacing: -8) {
                        ZStack {
                            Image(systemName: "mappin.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(universalAccentColor)
                        }
                        Triangle()
                            .fill(universalAccentColor)
                            .frame(width: 40, height: 20)
                    }
                }
            }
            .onChange(of: region.center.latitude) { _ in
                // Track that the map is being moved
                lastMapMoveTime = Date()
                isDraggingMap = true
            }
            .onChange(of: region.center.longitude) { _ in
                // Track that the map is being moved
                lastMapMoveTime = Date()
                isDraggingMap = true
            }
            
            // Center indicator
            if pinLocation == nil {
                Image(systemName: "plus")
                    .foregroundColor(universalAccentColor)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                    )
            }
            
            // Invisible overlay to capture tap gestures
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { _ in
                    // Update pin location on tap
                    updatePinLocation()
                }
        }
    }
    
    var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for a location", text: $searchText)
                .onChange(of: searchText) { _ in
                    isSearching = !searchText.isEmpty
                    searchLocations()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    isSearching = false
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    var searchResultsView: some View {
        List {
            ForEach(searchResults, id: \.self) { mapItem in
                Button(action: {
                    selectSearchResult(mapItem)
                }) {
                    VStack(alignment: .leading) {
                        Text(mapItem.name ?? "Unknown Location")
                            .fontWeight(.medium)
                        
                        if let addressLine = mapItem.placemark.formattedAddress() {
                            Text(addressLine)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listStyle(PlainListStyle())
        .frame(maxHeight: 250)
    }
    
    var locationNameInputView: some View {
        VStack {
            TextField("Location name", text: $locationName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            
            Text("Drag the map to adjust the pin location")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding()
    }
    
    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                locationName = "Custom Location"
                return
            }
            
            if let placemark = placemarks?.first {
                // Create a meaningful name from address components
                let name = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.locality,
                    placemark.administrativeArea
                ]
                .compactMap { $0 }
                .first ?? "Custom Location"
                
                locationName = name
            } else {
                locationName = "Custom Location"
            }
        }
    }
}

// MKPlacemark extension to get formatted address
extension MKPlacemark {
    func formattedAddress() -> String? {
        let components = [
            thoroughfare,
            locality,
            administrativeArea,
            postalCode,
            country
        ]
        return components
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

// Simple annotation for the map pin
struct PinAnnotation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    LocationSelectionView()
        .environmentObject(EventCreationViewModel.shared)
        .environmentObject(appCache)
} 
