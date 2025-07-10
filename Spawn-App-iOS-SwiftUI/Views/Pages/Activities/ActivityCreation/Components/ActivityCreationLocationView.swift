import SwiftUI
import MapKit
import CoreLocation

// Extension to make MKCoordinateRegion conform to Equatable
extension MKCoordinateRegion: Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        return lhs.center.latitude == rhs.center.latitude &&
               lhs.center.longitude == rhs.center.longitude &&
               lhs.span.latitudeDelta == rhs.span.latitudeDelta &&
               lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

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
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded = false
    @State private var isUpdatingLocation = false
    @State private var debounceTimer: Timer?
    
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
                .onReceive(locationManager.$locationError) { error in
                    if let error = error {
                        print("Location error in ActivityCreationLocationView: \(error)")
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
                            .foregroundColor(universalAccentColor)
                            .background(Circle().fill(universalBackgroundColor).frame(width: 32, height: 32))
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
                            .foregroundColor(universalAccentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(universalBackgroundColor.opacity(0.9))
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
                
                VStack(spacing: 0) {
                    // Handle bar
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.4))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    
                    VStack(spacing: 16) {
                        // Title and instruction
                        VStack(spacing: 6) {
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
                        
                        // Step indicators
                        StepIndicatorView(currentStep: 2, totalSteps: 3)
                            .padding(.bottom, 8)
                        
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
                .background(
                    universalBackgroundColor
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 20,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 20
                            )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                )
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let translation = value.translation.height
                            if translation < 0 {
                                // Dragging up
                                dragOffset = translation * 0.3
                            } else {
                                // Dragging down
                                dragOffset = translation * 0.1
                            }
                        }
                        .onEnded { value in
                            let translation = value.translation.height
                            let velocity = value.velocity.height

                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                if translation < -100 || velocity < -500 {
                                    // Dragged up enough or fast enough - show location picker
                                    showingLocationPicker = true
                                }
                                dragOffset = 0
                            }
                        }
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
        .onChange(of: region) { newRegion in
            // Update search text when region changes (when user drags map)
            updateLocationText(for: newRegion.center)
        }
    }
    
    // Function to update location text based on coordinates
    private func updateLocationText(for coordinate: CLLocationCoordinate2D) {
        // Cancel any existing timer
        debounceTimer?.invalidate()
        
        // Create a new timer with a delay to debounce the calls
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { _ in
            performReverseGeocoding(for: coordinate)
        }
    }
    
    // Function to perform the actual reverse geocoding
    private func performReverseGeocoding(for coordinate: CLLocationCoordinate2D) {
        // Prevent multiple simultaneous updates
        guard !isUpdatingLocation else { return }
        isUpdatingLocation = true
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                defer { isUpdatingLocation = false }
                
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    print("No placemark found")
                    return
                }
                
                // Create a formatted address string
                var addressComponents: [String] = []
                
                if let streetNumber = placemark.subThoroughfare {
                    addressComponents.append(streetNumber)
                }
                
                if let street = placemark.thoroughfare {
                    addressComponents.append(street)
                }
                
                if let city = placemark.locality {
                    addressComponents.append(city)
                }
                
                if let state = placemark.administrativeArea {
                    addressComponents.append(state)
                }
                
                let formattedAddress = addressComponents.joined(separator: ", ")
                
                // Update search text if we have a valid address
                if !formattedAddress.isEmpty {
                    searchText = formattedAddress
                }
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
