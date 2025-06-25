import SwiftUI
import MapKit
import CoreLocation

struct ActivityCreationLocationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207), // Default to Vancouver
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    @State private var searchText: String = "6133 University Blvd, Vancouver"
    @State private var isDragging = false
    @State private var showingLocationPicker = false
    
    let onNext: () -> Void
    let onBack: (() -> Void)?
    
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
                        onBack?()
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
                    
                    Button(action: {
                        // 3D toggle action
                    }) {
                        Text("3D")
                            .font(.caption)
                            .foregroundColor(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
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
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            Button(action: {
                                showingLocationPicker = true
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(figmaBlack300)
                                    .padding(12)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        
                        // Confirm button
                        ActivityNextStepButton(
                            title: "Confirm Location"
                        ) {
                            // Set the location in the view model based on current pin position
                            let location = Location(
                                id: UUID(),
                                name: searchText.isEmpty ? "Pacific Spirit Park" : searchText,
                                latitude: region.center.latitude,
                                longitude: region.center.longitude
                            )
                            viewModel.setLocation(location)
                            onNext()
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
            LocationPickerView(
                userLocation: locationManager.userLocation,
                onLocationSelected: { locationName in
                    searchText = locationName
                    showingLocationPicker = false
                }
            )
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
    @Environment(\.presentationMode) var presentationMode
    
    let userLocation: CLLocationCoordinate2D?
    let onLocationSelected: (String) -> Void
    
    // Predefined locations with coordinates for distance calculation
    private let predefinedLocations = [
        LocationData(name: "UBC Sauder School of Business", 
                    address: "2053 Main Mall, Vancouver, BC V6T 1Z2",
                    coordinate: CLLocationCoordinate2D(latitude: 49.2648, longitude: -123.2534)),
        LocationData(name: "AMS Student Nest", 
                    address: "6133 University Blvd, Vancouver, BC V6T 1Z1",
                    coordinate: CLLocationCoordinate2D(latitude: 49.2669, longitude: -123.2499)),
        LocationData(name: "Starbucks Coffee", 
                    address: "6138 Student Union Blvd, Vancouver, BC V6T 1Z1",
                    coordinate: CLLocationCoordinate2D(latitude: 49.2672, longitude: -123.2497)),
        LocationData(name: "Thunderbird Park", 
                    address: "2700 East Mall, Vancouver, BC V6T 1Z4",
                    coordinate: CLLocationCoordinate2D(latitude: 49.2525, longitude: -123.2592))
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(figmaBlack300)
                        .font(.system(size: 16))
                    
                    TextField("Where at?", text: $searchText)
                        .foregroundColor(universalAccentColor)
                        .font(.system(size: 16))
                        .onChange(of: searchText) { _ in
                            searchLocations()
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.top, 8) 
                
                List {
                    // Current Location
                    if userLocation != nil {
                        LocationRowView(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: "Current Location",
                            subtitle: "5934 University Blvd, Vancouver, BC V6T 1G2",
                            distance: nil
                        ) {
                            onLocationSelected("Current Location")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    // Predefined locations with distance
                    ForEach(predefinedLocations, id: \.name) { location in
                        LocationRowView(
                            icon: "mappin.circle",
                            iconColor: figmaBlack300,
                            title: location.name,
                            subtitle: location.address,
                            distance: distanceFromUser(to: location.coordinate)
                        ) {
                            onLocationSelected(location.address)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    // Search results
                    ForEach(searchResults, id: \.self) { item in
                        LocationRowView(
                            icon: "mappin.circle",
                            iconColor: figmaBlack300,
                            title: item.name ?? "Unknown Location",
                            subtitle: item.placemark.formattedAddress() ?? "",
                            distance: userLocation != nil ? distanceFromUser(to: item.placemark.coordinate) : nil
                        ) {
                            onLocationSelected(item.placemark.formattedAddress() ?? item.name ?? "Selected Location")
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    
                    // Set Location on Map option
                    LocationRowView(
                        icon: "map",
                        iconColor: figmaBlack300,
                        title: "Set Location on Map",
                        subtitle: nil,
                        distance: nil
                    ) {
                        onLocationSelected("Set Location on Map")
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .listStyle(PlainListStyle())
                .listRowSeparator(.hidden)
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
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
        if let userLocation = userLocation {
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                searchResults = []
                return
            }
            DispatchQueue.main.async {
                searchResults = Array(response.mapItems.prefix(10)) // Limit results
            }
        }
    }
    
    private func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation = userLocation else { return nil }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userCLLocation.distance(from: targetLocation)
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000
            if km < 10 {
                return String(format: "%.1fkm", km)  
            } else {
                return "\(Int(km))km"
            }
        }
    }
}

struct LocationRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let distance: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .foregroundColor(universalAccentColor)
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        if let distance = distance {
                            Text(distance)
                                .foregroundColor(figmaBlack300)
                                .font(.system(size: 14))
                        }
                    }
                    
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundColor(figmaBlack300)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LocationData {
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
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
        },
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(appCache)
} 
