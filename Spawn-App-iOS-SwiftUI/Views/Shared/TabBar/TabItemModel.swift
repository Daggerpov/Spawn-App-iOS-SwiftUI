import Foundation
import SwiftUI

struct TabItem: Identifiable, Hashable {
	let id = UUID()
	let title: String
	let activeIcon: String
	let inactiveIcon: String
	let color: Color
}
