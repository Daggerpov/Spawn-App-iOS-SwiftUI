import Foundation
import SwiftUICore

enum Tabs: CaseIterable {

	case home, map, activities, friends, profile
    
    // Simple conversion to/from TabType (now that names match)
    init(from tabType: TabType) {
        switch tabType {
        case .home: self = .home
        case .activities: self = .activities
        case .map: self = .map
        case .friends: self = .friends
        case .profile: self = .profile
        }
    }
    
    var toTabType: TabType {
        switch self {
        case .home: return .home
        case .activities: return .activities
        case .map: return .map
        case .friends: return .friends
        case .profile: return .profile
        }
    }
	var item: TabItem {
		switch self {
		case .home:
			.init(
				title: "Home",
				activeIcon: "nav/home-icon-active",
				inactiveIcon: "nav/home-icon",
				color: Color(hex: colorsTabIconInactive)
			)
		case .map:
			.init(
				title: "Map",
				activeIcon: "nav/map-icon-active",
				inactiveIcon: "nav/map-icon",
				color: Color(hex: colorsTabIconInactive)
			)
		case .activities:
			.init(
				title: "Activities",
				activeIcon: "nav/activities-icon-active",
				inactiveIcon: "nav/activities-icon",
				color: Color(hex: colorsTabIconInactive)
			)
		case .friends:
			.init(
				title: "Friends",
				activeIcon: "nav/friends-icon-active",
				inactiveIcon: "nav/friends-icon",
				color: Color(hex: colorsTabIconInactive)
			)
		case .profile:
			.init(
				title: "Profile",
				activeIcon: "nav/profile-icon-active",
				inactiveIcon: "nav/profile-icon",
				color: Color(hex: colorsTabIconInactive)
			)
		}
	}
}
