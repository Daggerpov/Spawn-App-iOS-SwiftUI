import SwiftUI
import MapKit
import CoreLocation

struct LocationSelectionView: View {
    @EnvironmentObject var viewModel: EventCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var selectedMapItem: MKMapItem?
    @State private var isSearching = false
    @State private var pinLocation: CLLocationCoordinate2D?
    @State private var locationName: String = ""
    @StateObject private var locationManager = LocationManager()
    
    // For tracking map interaction
    @State private var isMapMoving = false
    @State private var mapInteractionTask: Task<Void, Never>?
    
    // Region for Map - setting a closer zoom level with span 0.005
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default to San Francisco
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map view
                MapViewRepresentable(region: $region, onRegionChange: {
                    updatePinLocation()
                })
                .ignoresSafeArea()
                
                // Centered pin that shows where location will be saved
                VStack {
                    Spacer()
                    Image(systemName: "mappin")
                        .font(.system(size: 30))
                        .foregroundColor(universalAccentColor)
                        .offset(y: -15) // Offset so bottom of pin is at center
                    Spacer()
                }
                
                VStack {
                    searchBarView
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    if isSearching && !searchResults.isEmpty {
                        searchResultsView
                            .background(universalBackgroundColor.opacity(0.95))
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
                                    // Update pin location first
                                    pinLocation = userLocation
                                    
                                    // Create a new region centered on user's location with a smoother animation
                                    withAnimation(.easeInOut(duration: 0.75)) {
                                        region = MKCoordinateRegion(
                                            center: userLocation,
                                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                        )
                                    }
                                    
                                    // Reverse geocode to get location name
                                    reverseGeocode(coordinate: userLocation)
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
                    .background(universalBackgroundColor.opacity(0.95))
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
                // Focus on user location immediately when view appears
                if let userLocation = locationManager.userLocation {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                    updatePinLocation()
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
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
            }
            .onDisappear {
                // Cancel any ongoing tasks
                mapInteractionTask?.cancel()
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
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
            updatePinLocation()
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
        // Cancel any ongoing task
        mapInteractionTask?.cancel()
        
        // Create a new task for this update - use DispatchQueue to further ensure we're outside view update cycle
        DispatchQueue.main.async {
            self.mapInteractionTask = Task {
                // Use MainActor to update UI
                await MainActor.run {
                    self.pinLocation = self.region.center
                    
                    // If we don't have a location name from search, get it from reverse geocoding
                    if self.selectedMapItem == nil {
                        self.reverseGeocode(coordinate: self.region.center)
                    }
                }
            }
        }
    }
    
    private func selectSearchResult(_ mapItem: MKMapItem) {
        // Use Task to ensure state updates happen outside the view update cycle
        Task { @MainActor in
            selectedMapItem = mapItem
            locationName = mapItem.name ?? ""
            pinLocation = mapItem.placemark.coordinate
            
            region = MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
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
        
        // Use Task to ensure state updates happen outside the view update cycle
        Task { @MainActor in
            viewModel.event.location = location
            await viewModel.validateEventForm()
        }
    }
}

// Custom UIViewRepresentable for MapKit that handles region changes
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var onRegionChange: () -> Void
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Check if this is a significant location change
        let isLocationChange = mapView.region.center.latitude != region.center.latitude || 
                               mapView.region.center.longitude != region.center.longitude
        
        if isLocationChange {
            // Use UIView animation for a smoother visual effect
            UIView.animate(withDuration: 0.75, delay: 0, 
                          options: [.curveEaseInOut], 
                          animations: {
                mapView.setRegion(region, animated: false)
            }, completion: nil)
        } else {
            // For minor adjustments, use standard animation
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            // Use async to prevent modifying state during view update
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.parent.onRegionChange()
            }
        }
    }
}

// MARK: - View Components
extension LocationSelectionView {
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
        .background(universalBackgroundColor)
        .cornerRadius(10)
        .shadow(radius: 2)
        .colorScheme(.light)
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
        .colorScheme(.light)
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

#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    LocationSelectionView()
        .environmentObject(EventCreationViewModel.shared)
} 

