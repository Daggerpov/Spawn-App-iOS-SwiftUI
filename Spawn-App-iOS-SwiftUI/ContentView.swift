//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    var user: BaseUserDTO
    @State private var showEventCreationDrawer: Bool = false
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack {
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
                FeedView(user: user)
                    .tag(2)
                    .tabItem {
                        Image(
                            uiImage: resizeImage(
                                UIImage(systemName: "plus.app")!,
                                targetSize: CGSize(width: 30, height: 27)
                            )!
                        )
                    }
                FriendsAndTagsView(user: user)
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
            .onChange(of: selectedTab) { newValue in
                if newValue == 2 {
                    // Reset tab selection to previous tab and show the drawer
                    DispatchQueue.main.async {
                        // Store the current tab value before changing it
                        let previousTab = selectedTab
                        // Return to previous tab (but avoid returning to the create tab itself)
                        selectedTab = previousTab == 2 ? 0 : previousTab
                        showEventCreationDrawer = true
                    }
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
        .sheet(isPresented: $showEventCreationDrawer) {
            EventCreationView(
                creatingUser: user,
                closeCallback: {
                    showEventCreationDrawer = false
                }
            )
            .presentationDragIndicator(.visible)
        }
    }
}

@available(iOS 17.0, *)
#Preview {
    @Previewable
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
