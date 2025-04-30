import SwiftUI
import MapKit
import CoreLocation
import MapLibre

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
    
    // MapLibre camera state
    @State private var camera = CameraState(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        zoom: 14
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Map view
                mapLibreMapView
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
                                    camera.center = userLocation
                                    camera.zoom = 14
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
                    camera.center = userLocation
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
                    
                    camera.center = pinLocation!
                }
            }
            .onDisappear {
                // Cancel any ongoing tasks
                mapInteractionTask?.cancel()
            }
            .onChange(of: locationManager.locationUpdated) { _ in
                if locationManager.locationUpdated && locationManager.userLocation != nil && pinLocation == nil {
                    updateCameraWithUserLocation()
                }
            }
        }
    }
    
    private func updateCameraWithUserLocation() {
        if let userLocation = locationManager.userLocation {
            camera.center = userLocation
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
        request.region = MKCoordinateRegion(
            center: camera.center,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
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
        
        // Create a new task for this update
        mapInteractionTask = Task {
            // Use DispatchQueue to avoid modifying state during view update
            await MainActor.run {
                pinLocation = camera.center
                
                // If we don't have a location name from search, get it from reverse geocoding
                if selectedMapItem == nil {
                    reverseGeocode(coordinate: camera.center)
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
            
            camera.center = mapItem.placemark.coordinate
            
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

// MARK: - View Components
extension LocationSelectionView {
    var mapLibreMapView: some View {
        MapLibreView(
            camera: $camera,
            onCameraChanged: {
                updatePinLocation()
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

// MapLibre Maps View Component using UIViewRepresentable
struct MapLibreView: UIViewRepresentable {
    @Binding var camera: CameraState
    var onCameraChanged: () -> Void
    
    func makeUIView(context: Context) -> MLNMapView {
        // Set up the style URL - using OSM style
        let styleURL = URL(string: "https://demotiles.maplibre.org/style.json")
        
        // Create the map view
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        
        // Enable user location
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        // Set initial camera position
        mapView.setCenter(camera.center, zoomLevel: camera.zoom, animated: false)
        
        // Set up delegate
        mapView.delegate = context.coordinator
        
        return mapView
    }
    
    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Update the camera if changed externally
        if let lastCamera = context.coordinator.lastCameraCenter,
           lastCamera.latitude != camera.center.latitude || 
           lastCamera.longitude != camera.center.longitude {
            mapView.setCenter(camera.center, zoomLevel: camera.zoom, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: MapLibreView
        var lastCameraCenter: CLLocationCoordinate2D?
        
        init(_ parent: MapLibreView) {
            self.parent = parent
        }
        
        // MapLibre delegate method for when the map finishes rendering a frame
        func mapView(_ mapView: MLNMapView, regionDidChangeAnimated animated: Bool) {
            let center = mapView.centerCoordinate
            let zoom = mapView.zoomLevel
            
            // Only update if the camera has meaningfully changed
            if lastCameraCenter == nil || 
               abs(lastCameraCenter!.latitude - center.latitude) > 0.00001 ||
               abs(lastCameraCenter!.longitude - center.longitude) > 0.00001 {
                
                lastCameraCenter = center
                
                // Update the parent's camera binding
                DispatchQueue.main.async {
                    self.parent.camera.center = center
                    self.parent.camera.zoom = zoom
                    self.parent.onCameraChanged()
                }
            }
        }
    }
}

// Camera state structure to track map camera position
struct CameraState {
    var center: CLLocationCoordinate2D
    var zoom: Double
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

@available(iOS 17.0, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    LocationSelectionView()
        .environmentObject(EventCreationViewModel.shared)
        .environmentObject(appCache)
} 

