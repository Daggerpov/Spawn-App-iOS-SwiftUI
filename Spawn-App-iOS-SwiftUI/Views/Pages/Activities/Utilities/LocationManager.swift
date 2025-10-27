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

    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 5.0 // Update location every 5 meters
        
        // Check if location services are available at all on background queue
        DispatchQueue.global(qos: .userInitiated).async {
            guard CLLocationManager.locationServicesEnabled() else {
                print("⚠️ LocationManager: Location services not enabled on device")
                DispatchQueue.main.async {
                    self.locationError = "Location services are disabled on this device"
                }
                return
            }
            
            // Continue initialization on main queue if location services are enabled
            DispatchQueue.main.async {
                self.continueInitialization()
            }
        }
        
        // Initial authorization status will be handled in continueInitialization()
        // when called from the background queue after location services check
    }
    
    private func continueInitialization() {
        // Check current authorization status
        self.authorizationStatus = locationManager.authorizationStatus
        
        // Handle initial authorization state
        switch authorizationStatus {
        case .notDetermined:
            self.locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            self.locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("⚠️ LocationManager: Location access denied or restricted")
            DispatchQueue.main.async {
                self.locationError = "Location access denied. Please enable location access in Settings."
            }
        @unknown default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Validate coordinates before setting them to prevent NaN values
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            print("⚠️ LocationManager: Invalid coordinates received - latitude: \(location.coordinate.latitude), longitude: \(location.coordinate.longitude)")
            return
        }
        
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            self.locationUpdated = true
            self.locationError = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }
        
        switch status {
        case .notDetermined:
            // Authorization not determined, request it
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            print("⚠️ LocationManager: Location access denied or restricted")
            // Location access denied
            DispatchQueue.main.async {
                self.locationError = "Location access denied. Please enable location access in Settings."
            }
            manager.stopUpdatingLocation()
        case .authorizedWhenInUse, .authorizedAlways:
            // Authorization granted, start updating location
            DispatchQueue.main.async {
                self.locationError = nil
            }
            // Ensure location services are enabled before starting (on background queue)
            DispatchQueue.global(qos: .userInitiated).async {
                if CLLocationManager.locationServicesEnabled() {
                    DispatchQueue.main.async {
                        manager.startUpdatingLocation()
                    }
                } else {
                    DispatchQueue.main.async {
                        self.locationError = "Location services are disabled on this device"
                    }
                }
            }
        @unknown default:
            // Handle future authorization statuses
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
