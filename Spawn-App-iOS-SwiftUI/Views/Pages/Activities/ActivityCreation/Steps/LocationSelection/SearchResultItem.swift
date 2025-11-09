import MapKit

struct SearchResultItem: Identifiable {
	let id = UUID()
	let mapItem: MKMapItem

	init(_ mapItem: MKMapItem) {
		self.mapItem = mapItem
	}
}
