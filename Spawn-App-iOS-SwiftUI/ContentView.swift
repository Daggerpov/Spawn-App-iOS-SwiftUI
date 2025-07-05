//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
	var user: BaseUserDTO
    @State private var selectedTab: TabType = .home

	var body: some View {
		TabView(selection: $selectedTab) {
            ActivityFeedView(user: user, selectedTab: $selectedTab)
                .tag(TabType.home)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(named: "home_nav_icon")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
					Text("Home")
				}
			MapView(user: user)
                .tag(TabType.map)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(named: "map_nav_icon")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
					Text("Map")
				}
			ActivityCreationView(
				creatingUser: user,
				closeCallback: {
					// Navigate back to home tab when closing
                    selectedTab = .home
				},
				selectedTab: $selectedTab
			)
            .tag(TabType.creation)
			.tabItem {
				Image(
					uiImage: resizeImage(
						UIImage(named: "activities_nav_icon")!,
						targetSize: CGSize(width: 30, height: 27)
					)!
				)
				Text("Activities")
			}
			FriendsView(user: user)
                .tag(TabType.friends)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(named: "friends_nav_icon")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
					Text("Friends")
				}
			ProfileView(user: user)
                .tag(TabType.profile)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(named: "profile_nav_icon")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
					Text("Profile")
				}
		}
		.tint(universalSecondaryColor) // Set the tint color for selected tabs to purple
		.onAppear {
			// Configure tab bar appearance for theme compatibility
			let appearance = UITabBarAppearance()
			appearance.configureWithOpaqueBackground()
			appearance.backgroundColor = UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor.systemBackground.withAlphaComponent(0.9)
				default:
					return UIColor.systemBackground.withAlphaComponent(0.9)
				}
			}
			
			UITabBar.appearance().standardAppearance = appearance
			UITabBar.appearance().scrollEdgeAppearance = appearance
			UITabBar.appearance().unselectedItemTintColor = UIColor { traitCollection in
				switch traitCollection.userInterfaceStyle {
				case .dark:
					return UIColor.label
				default:
					return UIColor.label
				}
			}
		}
	}
}

@available(iOS 17.0, *)
#Preview {
	ContentView(user: BaseUserDTO.danielAgapov)
}

func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage? {
	let size = image.size

	// Calculate the scaling factor to fit the image to the target dimensions while maintaining the aspect ratio
	let widthRatio = targetSize.width / size.width
	let heightRatio = targetSize.height / size.height
	let ratio = min(widthRatio, heightRatio)

	let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
	// Add padding by using a percentage of the available space (e.g., 40% from top, 60% from bottom)
	let paddingFactor = 0.9
	let yOffset = (targetSize.height - newSize.height) * paddingFactor

	//Create a new image context
	let renderer = UIGraphicsImageRenderer(size: targetSize)
	let newImage = renderer.image { context in
		// Fill the background with a transparent color
		context.cgContext.setFillColor(UIColor.clear.cgColor)
		context.cgContext.fill(CGRect(origin: .zero, size: targetSize))

		// draw new image
		image.draw(
			in: CGRect(
				x: 0,
				y: yOffset,
				width: newSize.width,
				height: newSize.height
			)
		)
	}

	return newImage
}
