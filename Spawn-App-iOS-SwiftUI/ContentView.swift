//
//  ContentView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 4/19/25.
//

import SwiftUI

struct ContentView: View {
    var user: BaseUserDTO
    var body: some View {
        TabView{
            FeedView(user: user)
            .tabItem {
                Image(uiImage: resizeImage(UIImage(systemName: "house")!, targetSize: CGSize(width: 30, height: 27))!)
                }
            MapView(user: user)
                .tabItem {
                    Image(uiImage: resizeImage(UIImage(systemName: "map.circle")!, targetSize: CGSize(width: 30, height: 27))!)
                }
            EventCreationView(creatingUser: user, closeCallback: {})
                .tabItem {
                    Image(uiImage: resizeImage(UIImage(systemName: "plus.app")!, targetSize: CGSize(width: 30, height: 27))!)
                }
            FriendsAndTagsView(user: user)
                .tabItem {
                    Image(uiImage: resizeImage(UIImage(systemName: "person.2.circle")!, targetSize: CGSize(width: 30, height: 27))!)
                }
            ProfileView(user: user)
                .tabItem {
                    Image(uiImage: resizeImage(UIImage(systemName: "person.circle")!, targetSize: CGSize(width: 30, height: 27))!)
                }
        }
    }
}

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
    let yOffset = (targetSize.height - newSize.height) // Leave the top blank and align the bottom
    
    //Create a new image context
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let newImage = renderer.image { context in
        // Fill the background with a transparent color
        context.cgContext.setFillColor(UIColor.clear.cgColor)
        context.cgContext.fill(CGRect(origin: .zero, size: targetSize))
        
        // draw new image
        image.draw(in: CGRect(x: 0, y: yOffset, width: newSize.width, height: newSize.height))
    }
    
    return newImage
}


