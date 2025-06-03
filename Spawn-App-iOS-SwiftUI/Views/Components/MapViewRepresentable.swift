import SwiftUI
import MapKit

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