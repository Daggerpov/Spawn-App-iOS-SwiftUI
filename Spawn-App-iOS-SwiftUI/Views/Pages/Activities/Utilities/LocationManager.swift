//
//  LocationManager.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Michael Tham on 7/3/25.
//

import MapKit
import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var locationUpdated = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    
    private var locationManager = CLLocationManager()
    private var lastPublishedLocation: CLLocationCoordinate2D?
    private let significantDistanceThreshold: Double = 10.0 // Only publish updates > 10 meters

    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        self.locationManager.distanceFilter = 50.0
        
        // Get initial authorization status
        self.authorizationStatus = locationManager.authorizationStatus
        
        // Request authorization if needed - delegate will handle the response
        switch authorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        case .denied, .restricted:
            self.locationError = "Location access denied. Please enable location access in Settings."
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        
        // Only publish location updates if moved significantly
        let shouldPublish: Bool
        if let lastLocation = lastPublishedLocation {
            let distance = location.distance(from: CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude))
            shouldPublish = distance >= significantDistanceThreshold
        } else {
            shouldPublish = true
        }
        
        if shouldPublish {
            DispatchQueue.main.async {
                self.userLocation = location.coordinate
                self.locationUpdated = true
                self.locationError = nil
                self.lastPublishedLocation = location.coordinate
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.locationError = "Location access denied. Please enable location access in Settings."
            }
            manager.stopUpdatingLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            DispatchQueue.main.async {
                self.locationError = nil
            }
            // Start updating location - locationServicesEnabled check not needed here
            // as we're in the authorization callback
            manager.startUpdatingLocation()
        @unknown default:
            DispatchQueue.main.async {
                self.locationError = "Unknown location authorization status"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.locationError = "Location access denied"
                case .locationUnknown:
                    self.locationError = "Location unknown"
                case .network:
                    self.locationError = "Network error when getting location"
                default:
                    self.locationError = "Location error: \(clError.localizedDescription)"
                }
            } else {
                self.locationError = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Public Methods
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = "Location permission not granted"
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
}
