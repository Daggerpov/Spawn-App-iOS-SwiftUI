import SwiftUI
import MapKit
import CoreLocation

// Extension to make MKCoordinateRegion conform to Equatable
extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        // Validate coordinates before comparing to prevent NaN issues
        guard CLLocationCoordinate2DIsValid(lhs.center) && CLLocationCoordinate2DIsValid(rhs.center) else {
            return false
        }
        
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
    // Drop effect state for the base ellipse and a brief pulse
    @State private var baseEllipseScale: CGFloat = 1.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.0
    @State private var showLocationError = false
    @State private var previousRegion: MKCoordinateRegion?
    
    let onNext: () -> Void
    let onBack: (() -> Void)?
    
    // 3D camera toggle (placeholder for SwiftUI Map). Used to reflect UI state.
    @State private var is3DMode: Bool = false
    
    var body: some View {
        ZStack {
            // Map View
            Map(coordinateRegion: $region, showsUserLocation: true)
                .ignoresSafeArea(.all, edges: .top)
                .onTapGesture {
                    print("🎯 Map tapped - triggering pin drop animation")
                    // Quick pin drop animation for taps
                    withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                        baseEllipseScale = 1.15
                    }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9).delay(0.05)) {
                        baseEllipseScale = 1.0
                    }
                    // Brief pulse effect
                    pulseOpacity = 0.2
                    pulseScale = 1.0
                    withAnimation(.easeOut(duration: 0.3)) {
                        pulseScale = 1.4
                        pulseOpacity = 0.0
                    }
                }
                .onReceive(locationManager.$userLocation) { location in
                    print("📍 ActivityCreationLocationView: Received user location: \(String(describing: location))")
                    if let location = location, !locationManager.locationUpdated {
                        // Validate coordinates before creating region to prevent NaN values
                        guard CLLocationCoordinate2DIsValid(location) else {
                            print("⚠️ ActivityCreationLocationView: Invalid user location received - \(location)")
                            return
                        }
                        
                        print("✅ ActivityCreationLocationView: Setting region with valid coordinates - lat: \(location.latitude), lng: \(location.longitude)")
                        
                        // Additional iOS 17 specific debugging
                        if #available(iOS 17, *) {
                            print("📍 iOS 17: Setting region with valid coordinates - lat: \(location.latitude), lng: \(location.longitude)")
                        }
                        
                        let newRegion = MKCoordinateRegion(
                            center: location,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        
                        // Validate the new region before setting
                        guard CLLocationCoordinate2DIsValid(newRegion.center) else {
                            print("⚠️ ActivityCreationLocationView: Invalid region center created")
                            return
                        }
                        
                        withAnimation(.easeInOut(duration: 1.0)) {
                            region = newRegion
                        }
                        
                        print("✅ ActivityCreationLocationView: Region updated successfully")
                    }
                }
                .onReceive(locationManager.$locationError) { error in
                    if let error = error {
                        print("Location error in ActivityCreationLocationView: \(error)")
                        showLocationError = true
                        if #available(iOS 17, *) {
                            print("⚠️ iOS 17: Location error occurred: \(error)")
                        }
                    }
                }
            
            
            // Pin in center of map
            VStack {
                Spacer()
                ZStack {
                    // Base ellipse under the pin
                    Ellipse()
                        .fill(Color(red: 0.15, green: 0.55, blue: 1))
                        .frame(width: 19.90, height: 9.95)
                        .scaleEffect(baseEllipseScale)
                        .opacity(0.9)
                        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 3)
                        .offset(y: 18)
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: baseEllipseScale)
                    // Expanding pulse when dropped
                    Ellipse()
                        .fill(Color(red: 0.15, green: 0.55, blue: 1))
                        .frame(width: 19.90, height: 9.95)
                        .scaleEffect(pulseScale)
                        .opacity(pulseOpacity)
                        .offset(y: 18)
                    
                    // Pin icon
                    Image(systemName: "mappin")
                        .font(.system(size: 34))
                        .foregroundColor(.blue)
                        .scaleEffect(isDragging ? 1.1 : 1.0)
                        .offset(y: isDragging ? -10 : 0)
                        .shadow(color: .black.opacity(isDragging ? 0.35 : 0.25), radius: isDragging ? 8 : 6, x: 0, y: isDragging ? 6 : 3)
                        .animation(.spring(response: 0.25, dampingFraction: 0.8), value: isDragging)
                }
                Spacer()
            }
            .allowsHitTesting(false) // Prevent pin from blocking gestures
            
            // Top navigation - back button aligned to safe area like other creation pages
            VStack {
                HStack {
                    Button(action: {
                        onBack?()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(red: 0.56, green: 0.52, blue: 0.52))
                    }
                    .frame(width: 48, height: 48)
                    .background(.white)
                    .cornerRadius(100)
                    .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.25), radius: 8, y: 2)
                    .padding(.leading, 24)
                    
                    Spacer()
                    
                    // Removed floating label
                    
                    Spacer()
                }
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                Spacer()
            }
            
            // Top-right controls: 3D toggle and recenter buttons
            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        // 3D mode toggle (visual only for SwiftUI Map)
                        if #available(iOS 17.0, *) {
                            Button(action: {
                                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                                impactGenerator.impactOccurred()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    is3DMode.toggle()
                                }
                            }) {
                                Text("3D")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 44, height: 44)
                                    .background(universalBackgroundColor)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 10,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 10
                                        )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            Button(action: {}) {
                                Text("3D")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(universalAccentColor)
                                    .frame(width: 44, height: 44)
                                    .background(universalBackgroundColor)
                                    .clipShape(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: 10,
                                            bottomLeadingRadius: 0,
                                            bottomTrailingRadius: 0,
                                            topTrailingRadius: 10
                                        )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Recenter to user location
                        Button(action: {
                            let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                            impactGenerator.impactOccurred()
                            if let userLocation = locationManager.userLocation {
                                withAnimation(.easeInOut(duration: 0.75)) {
                                    region = MKCoordinateRegion(
                                        center: userLocation,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    )
                                }
                            }
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(universalAccentColor)
                                .frame(width: 44, height: 44)
                                .background(universalBackgroundColor)
                                .clipShape(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 10,
                                        bottomTrailingRadius: 10,
                                        topTrailingRadius: 0
                                    )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.trailing, 16)
                }
                .padding(.top, 24)
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
                                .font(.onestSemiBold(size: 20))
                                .foregroundColor(universalAccentColor)
                            
                            Text("Drag map to move pin")
                                .font(.onestMedium(size: 16))
                                .foregroundColor(figmaBlack300)
                        }
                        
                        // Address field
                        HStack {
                            TextField("6133 University Blvd, Vancouver", text: $searchText)
                                .font(.onestMedium(size: 16))
                                .padding(.horizontal, 12)
                                .foregroundColor(universalAccentColor)
                                .background(Color.clear)
                            
                            Button(action: {
                                showingLocationPicker = true
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(universalAccentColor)
                                    .padding(12)
                                    .background(Color.clear)
                            }
                        }
                        .background(Color.clear)
                        .frame(height: 52)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: colorsGray700), lineWidth: 1)
                        )
                        
                        // Confirm button
                        ActivityNextStepButton(
                            title: "Confirm Location"
                        ) {
                            
                            guard CLLocationCoordinate2DIsValid(region.center) else {
                                print("⚠️ Confirm Location: Invalid region center coordinates - \(region.center)")
                                return
                            }
                            
                            // Set the location in the view model based on current pin position
                            let location = LocationDTO(
                                id: UUID(),
                                name: searchText.isEmpty ? "Selected Location" : searchText,
                                latitude: region.center.latitude,
                                longitude: region.center.longitude
                            )
                            viewModel.setLocation(location)
                            onNext()
                        }
                        // Step indicators
                        StepIndicatorView(currentStep: 2, totalSteps: 3)
                            .padding(.bottom, 8) // Standard bottom padding
        
                        
                    }
                }
                .padding(.horizontal, 25)
                .padding(.bottom, 80)
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
            print("📍 ActivityCreationLocationView: App entering foreground, checking location services...")
            // Update region when app becomes active
            if let userLocation = locationManager.userLocation {
                // Validate coordinates before creating region to prevent NaN values
                guard CLLocationCoordinate2DIsValid(userLocation) else {
                    print("⚠️ ActivityCreationLocationView: Invalid user location on foreground - \(userLocation)")
                    return
                }
                
                region = MKCoordinateRegion(
                    center: userLocation,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
            
            // Re-request location when app returns to foreground
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                print("📍 ActivityCreationLocationView: Restarting location updates after app foreground...")
                locationManager.startLocationUpdates()
            } else {
                print("⚠️ ActivityCreationLocationView: Location permission not granted when app entered foreground")
            }
        }
        .onAppear {
            print("📍 ActivityCreationLocationView: View appeared, checking location manager state...")
            print("📍 Current authorization status: \(locationManager.authorizationStatus.rawValue)")
            print("📍 Current user location: \(String(describing: locationManager.userLocation))")
            print("📍 Location updated flag: \(locationManager.locationUpdated)")
            
            // Ensure location manager is properly set up when view appears
            if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
                locationManager.startLocationUpdates()
            } else if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestLocationPermission()
            }
        }
        .onDisappear {
            print("📍 ActivityCreationLocationView: View disappeared, stopping location updates...")
            locationManager.stopLocationUpdates()
            // Clean up timers
            debounceTimer?.invalidate()
        }
        .onChange(of: region) { newRegion in
            // Validate region center before processing to prevent NaN issues
            guard CLLocationCoordinate2DIsValid(newRegion.center) else {
                print("⚠️ ActivityCreationLocationView: Invalid region change detected - \(newRegion.center)")
                if #available(iOS 17, *) {
                    print("⚠️ iOS 17: Invalid region center - resetting to default Vancouver coordinates")
                    // Reset to a valid default region
                    region = MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 49.2827, longitude: -123.1207),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }
                return
            }
            
            // Check if this is a user-initiated region change (not programmatic)
            if let previous = previousRegion, 
               CLLocationCoordinate2DIsValid(previous.center) && previous != newRegion {
                // Trigger pin animations when user drags the map
                print("🎯 Map region changed by user interaction")
                
                // Start dragging animation
                if !isDragging {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.75)) {
                        isDragging = true
                        baseEllipseScale = 0.88
                    }
                }
                
                // Use a timer to detect when dragging has stopped
                debounceTimer?.invalidate()
                debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    // Pin drop animation when dragging stops
                    print("🎯 Map dragging stopped - triggering pin drop animation")
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                        isDragging = false
                        baseEllipseScale = 1.18
                    }
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.8).delay(0.03)) {
                        baseEllipseScale = 1.0
                    }
                    // Pulse effect
                    pulseOpacity = 0.35
                    pulseScale = 1.0
                    withAnimation(.easeOut(duration: 0.5)) {
                        pulseScale = 1.8
                        pulseOpacity = 0.0
                    }
                }
            }
            
            // Update the previous region for next comparison
            previousRegion = newRegion
            
            // Update search text when region changes (when user drags map)
            updateLocationText(for: newRegion.center)
        }
        .alert("Location Error", isPresented: $showLocationError) {
            Button("OK") {
                showLocationError = false
            }
            if locationManager.authorizationStatus == .denied {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            }
        } message: {
            Text(locationManager.locationError ?? "An unknown location error occurred.")
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
        
        // Validate coordinates before reverse geocoding to prevent NaN values
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            print("⚠️ performReverseGeocoding: Invalid coordinates - \(coordinate)")
            return
        }
        
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
                    let searchResultsCopy = searchResults  // Create stable copy
                    ForEach(searchResultsCopy, id: \.self) { item in
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
            DispatchQueue.main.async {
                self.searchResults = []
            }
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        if let userLocation = userLocation {
            // Validate user location before using it in search region
            guard CLLocationCoordinate2DIsValid(userLocation) else {
                print("⚠️ searchLocations: Invalid user location - \(userLocation)")
                // Continue search without region restriction
                let search = MKLocalSearch(request: request)
                search.start { response, error in
                    guard let response = response, error == nil else {
                        DispatchQueue.main.async {
                            self.searchResults = []
                        }
                        return
                    }
                    DispatchQueue.main.async {
                        // Filter out results with invalid coordinates
                        let validResults = response.mapItems.filter { item in
                            CLLocationCoordinate2DIsValid(item.placemark.coordinate)
                        }
                        self.searchResults = Array(validResults.prefix(10)) // Limit results
                    }
                }
                return
            }
            
            request.region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let response = response, error == nil else {
                DispatchQueue.main.async {
                    self.searchResults = []
                }
                return
            }
            DispatchQueue.main.async {
                // Filter out results with invalid coordinates
                let validResults = response.mapItems.filter { item in
                    CLLocationCoordinate2DIsValid(item.placemark.coordinate)
                }
                self.searchResults = Array(validResults.prefix(10)) // Limit results
            }
        }
    }
    
    private func distanceFromUser(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userLocation = userLocation else { return nil }
        
        // Validate both coordinates before calculating distance to prevent NaN values
        guard CLLocationCoordinate2DIsValid(userLocation) && CLLocationCoordinate2DIsValid(coordinate) else {
            print("⚠️ distanceFromUser: Invalid coordinates - user: \(userLocation), target: \(coordinate)")
            return nil
        }
        
        let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let distance = userCLLocation.distance(from: targetLocation)
        
        // Additional check to ensure distance is valid
        guard distance.isFinite && !distance.isNaN else {
            print("⚠️ distanceFromUser: Invalid distance calculated: \(distance)")
            return nil
        }
        
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
