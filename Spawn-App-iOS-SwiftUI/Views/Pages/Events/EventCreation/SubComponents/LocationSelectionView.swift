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
                    
                    if pinLocation != nil {
                        locationNameInputView
                            .padding()
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveLocation()
                        dismiss()
                    }
                    .disabled(pinLocation == nil || locationName.isEmpty)
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
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        selectedMapItem = mapItem
        locationName = mapItem.name ?? ""
        pinLocation = mapItem.placemark.coordinate
        
        region = MKCoordinateRegion(
            center: mapItem.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        
        isSearching = false
        searchText = locationName
    }
    
    private func saveLocation() {
        guard let pinLocation = pinLocation, !locationName.isEmpty else { return }
        
        let location = Location(
            id: viewModel.event.location?.id ?? UUID(),
            name: locationName,
            latitude: pinLocation.latitude,
            longitude: pinLocation.longitude
        )
        
        viewModel.event.location = location
    }
}

// MARK: - View Components
extension LocationSelectionView {
    var mapView: some View {
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
        .gesture(
            DragGesture()
                .onEnded { value in
                    let mapCenter = region.center
                    pinLocation = mapCenter
                    
                    // If we don't have a location name from search, get it from reverse geocoding
                    if selectedMapItem == nil {
                        reverseGeocode(coordinate: mapCenter)
                    }
                }
        )
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
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
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