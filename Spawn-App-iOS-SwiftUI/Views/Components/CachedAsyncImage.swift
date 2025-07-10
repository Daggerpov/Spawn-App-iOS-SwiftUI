//
//  CachedAsyncImage.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2025-01-03.
//

import SwiftUI
import UIKit

/// A cached version of AsyncImage that stores profile pictures locally
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let userId: UUID
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let cache = ProfilePictureCache.shared
    
    init(
        userId: UUID,
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.userId = userId
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else if loadError != nil {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { newURL in
            loadImage()
        }
    }
    
    private func loadImage() {
        // Reset state
        loadError = nil
        
        // Check cache first
        if let cachedImage = cache.getCachedImage(for: userId) {
            image = cachedImage
            return
        }
        
        // If no cached image and no URL, nothing to load
        guard let url = url else {
            return
        }
        
        // Start loading
        isLoading = true
        
        Task {
            do {
                let downloadedImage = await cache.downloadAndCacheImage(from: url.absoluteString, for: userId)
                
                await MainActor.run {
                    isLoading = false
                    image = downloadedImage
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    loadError = error
                }
            }
        }
    }
}

// MARK: - Convenience Initializers

extension CachedAsyncImage where Content == Image, Placeholder == Color {
    /// Simple initializer that shows a gray placeholder
    init(userId: UUID, url: URL?) {
        self.init(
            userId: userId,
            url: url,
            content: { image in image },
            placeholder: { Color.gray }
        )
    }
}

extension CachedAsyncImage where Content == Image, Placeholder == ProgressView<EmptyView, EmptyView> {
    /// Initializer with progress view placeholder
    init(userId: UUID, url: URL?, @ViewBuilder content: @escaping (Image) -> Content) {
        self.init(
            userId: userId,
            url: url,
            content: content,
            placeholder: { ProgressView() }
        )
    }
}

extension CachedAsyncImage where Content == Image {
    /// Initializer with custom placeholder
    init(userId: UUID, url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.init(
            userId: userId,
            url: url,
            content: { image in image },
            placeholder: placeholder
        )
    }
}

// MARK: - Profile Picture Specific Views

/// A cached async image specifically for profile pictures with common styling
struct CachedProfileImage: View {
    let userId: UUID
    let url: URL?
    let imageType: ProfileImageType
    
    var body: some View {
        CachedAsyncImage(
            userId: userId,
            url: url,
            content: { image in
                image
                    .ProfileImageModifier(imageType: imageType)
            },
            placeholder: {
                Circle()
                    .fill(Color.gray)
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: imageSize * 0.5, height: imageSize * 0.5)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        )
    }
    
    private var imageSize: CGFloat {
        switch imageType {
        case .feedPage:
            return 55
        case .friendsListView:
            return 50
        case .activityParticipants, .chatMessage:
            return 25
        case .profilePage:
            return 150
        }
    }
}

/// A cached async image for profile pictures with flexible sizing
struct CachedProfileImageFlexible: View {
    let userId: UUID
    let url: URL?
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        CachedAsyncImage(
            userId: userId,
            url: url,
            content: { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(Circle())
            },
            placeholder: {
                Circle()
                    .fill(Color.gray)
                    .frame(width: width, height: height)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: width * 0.5, height: height * 0.5)
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        )
    }
} 