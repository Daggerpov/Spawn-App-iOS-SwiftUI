import SwiftUI
import MapKit
import CoreLocation

struct ActivityCreationLocationView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Default to Vancouver
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var searchText: String = "6133 University Blvd, Vancouver"
    @State private var isDragging = false
    @State private var showingLocationPicker = false
    
    let onNext: () -> Void
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea(.all, edges: .top)
                .onReceive(locationManager.$userLocation) { location in
                    if let location = location, !locationManager.locationUpdated {
                        region = MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    }
                }
            
            // Pin in center of map
            VStack {
                Spacer()
                Image(systemName: "mappin")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                    .scaleEffect(isDragging ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                Spacer()
            }
            
            // Top navigation
            VStack {
                HStack {
                    Button(action: {
                        // Handle back action
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                            .background(Circle().fill(Color.white).frame(width: 32, height: 32))
                    }
                    
                    Spacer()
                    
                    Text("Burrard Inlet")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    // Placeholder for right side
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Spacer()
            }
            
            // Bottom sheet
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                    
                    VStack(spacing: 20) {
                        // Title and instruction
                        VStack(spacing: 8) {
                            Text("Set Location")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(universalAccentColor)
                            
                            Text("Drag map to move pin")
                                .font(.subheadline)
                                .foregroundColor(figmaBlack300)
                        }
                        
                        // Address field
                        HStack {
                            TextField("6133 University Blvd, Vancouver", text: $searchText)
                                .font(.body)
                                .foregroundColor(universalAccentColor)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                showingLocationPicker = true
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(figmaBlack300)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Confirm button
                        Button(action: onNext) {
                            Text("Confirm Location")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(universalSecondaryColor)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 16)
                .padding(.bottom, 32)
                .background(
                    Color.white
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 10)
                )
            }
        }
        .background(universalBackgroundColor)
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(onLocationSelected: { location in
                searchText = location
                showingLocationPicker = false
            })
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Update region when app becomes active
            if let userLocation = locationManager.userLocation {
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

struct LocationPickerView: View {
    @State private var searchText = ""
    @State private var searchResults: [MKMapItem] = []
    @StateObject private var locationManager = LocationManager()
    
    let onLocationSelected: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(figmaBlack300)
                    
                    TextField("Where at?", text: $searchText)
                        .foregroundColor(universalAccentColor)
                        .onChange(of: searchText) { _ in
                            searchLocations()
                        }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                List {
                    // Current Location
					if locationManager.userLocation != nil {
                        Button(action: {
                            onLocationSelected("Current Location")
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Current Location")
                                        .foregroundColor(universalAccentColor)
                                    Text("5934 University Blvd, Vancouver, BC V6T 1G2")
                                        .font(.caption)
                                        .foregroundColor(figmaBlack300)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Predefined locations
                    ForEach([
                        ("UBC Sauder School of Business", "2053 Main Mall, Vancouver, BC V6T 1Z2"),
                        ("AMS Student Nest", "6133 University Blvd, Vancouver, BC V6T 1Z1"),
                        ("Starbucks Coffee", "6138 Student Union Blvd, Vancouver, BC V6T 1Z1"),
                        ("Thunderbird Park", "2700 East Mall, Vancouver, BC V6T 1Z4")
                    ], id: \.0) { location in
                        Button(action: {
                            onLocationSelected(location.1)
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(figmaBlack300)
                                VStack(alignment: .leading) {
                                    Text(location.0)
                                        .foregroundColor(universalAccentColor)
                                    Text(location.1)
                                        .font(.caption)
                                        .foregroundColor(figmaBlack300)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    // Set Location on Map option
                    Button(action: {
                        onLocationSelected("Set Location on Map")
                    }) {
                        HStack {
                            Image(systemName: "map")
                                .foregroundColor(figmaBlack300)
                            Text("Set Location on Map")
                                .foregroundColor(universalAccentColor)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Saved Locations option
                    Button(action: {
                        onLocationSelected("Saved Locations")
                    }) {
                        HStack {
                            Image(systemName: "star")
                                .foregroundColor(figmaBlack300)
                            Text("Saved Locations")
                                .foregroundColor(universalAccentColor)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // Search results
                    ForEach(searchResults, id: \.self) { item in
                        Button(action: {
                            onLocationSelected(item.placemark.formattedAddress() ?? item.name ?? "Selected Location")
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle")
                                    .foregroundColor(figmaBlack300)
                                VStack(alignment: .leading) {
                                    Text(item.name ?? "Unknown Location")
                                        .foregroundColor(universalAccentColor)
                                    if let address = item.placemark.formattedAddress() {
                                        Text(address)
                                            .font(.caption)
                                            .foregroundColor(figmaBlack300)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onLocationSelected("")
                }
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
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                searchResults = []
                return
            }
            DispatchQueue.main.async {
                searchResults = response.mapItems
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

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityCreationLocationView(
        onNext: {
            print("Next step tapped")
        }
    )
    .environmentObject(appCache)
} 
