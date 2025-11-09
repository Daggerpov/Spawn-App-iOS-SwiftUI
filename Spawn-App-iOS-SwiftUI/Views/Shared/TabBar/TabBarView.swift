import MapKit
import SwiftUI

struct TabBarView: View {
	var body: some View {
		WithTabBar { selection in
			switch selection {
			case .home:
				TabScrollContentView(tab: .home)
			case .map:
				TabScrollContentView(tab: .map)
			case .activities:
				TabScrollContentView(tab: .activities)
			case .friends:
				TabScrollContentView(tab: .friends)
			case .profile:
				TabScrollContentView(tab: .profile)
			}
		}
	}
}

#Preview {
	TabBarView()
}
