//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
	var user: BaseUserDTO
	@State private var selectedTab: Int = 0

	var body: some View {
		TabView(selection: $selectedTab) {
			FeedView(user: user)
				.tag(0)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(systemName: "house")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
				}
			MapView(user: user)
				.tag(1)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(systemName: "location.circle")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
				}
			ActivityCreationView(
				creatingUser: user,
				closeCallback: {
					// Navigate back to home tab when closing
					selectedTab = 0
				},
				selectedTab: $selectedTab
			)
			.tag(2)
			.tabItem {
				Image(
					uiImage: resizeImage(
						UIImage(named: "activities_icon")!,
						targetSize: CGSize(width: 30, height: 27)
					)!
				)
			}
			FriendsView(user: user)
				.tag(3)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(systemName: "list.bullet")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
				}
			ProfileView(user: user)
				.tag(4)
				.tabItem {
					Image(
						uiImage: resizeImage(
							UIImage(systemName: "person.circle")!,
							targetSize: CGSize(width: 30, height: 27)
						)!
					)
				}
		}
		.onAppear {
			// TODO DANIEL A: when implementing dark/light theme, look at Quote Droplet's
			// code for how to do that here
			UITabBar
				.appearance().backgroundColor = UIColor.white
				.withAlphaComponent(0.9)
			UITabBar.appearance().unselectedItemTintColor = UIColor.black
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
