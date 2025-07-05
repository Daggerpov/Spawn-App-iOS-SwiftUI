//
//  ProfilePictureCache.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2025-01-03.
//

import Foundation
import UIKit
import SwiftUI

/// A singleton service that manages profile picture caching
class ProfilePictureCache: ObservableObject {
    static let shared = ProfilePictureCache()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    // In-memory cache for recently accessed images
    private var memoryCache: NSCache<NSString, UIImage>
    
    // Metadata about cached images
    private var cacheMetadata: [String: CacheMetadata] = [:]
    private let metadataKey = "ProfilePictureCacheMetadata"
    
    // Currently downloading images to prevent duplicate downloads
    private var downloadingImages: Set<String> = []
    private let downloadingQueue = DispatchQueue(label: "ProfilePictureCache.downloading", attributes: .concurrent)
    
    // MARK: - Initialization
    private init() {
        // Create cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDirectory.appendingPathComponent("ProfilePictures")
        
        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // Initialize memory cache
        memoryCache = NSCache<NSString, UIImage>()
        memoryCache.countLimit = 100 // Cache up to 100 images in memory
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50MB memory limit
        
        // Load metadata
        loadMetadata()
        
        // Clean up old cache entries
        cleanupOldCache()
    }
    
    // MARK: - Public Methods
    
    /// Get a cached image for a user ID, or nil if not cached
    func getCachedImage(for userId: UUID) -> UIImage? {
        let key = userId.uuidString
        
        // Check memory cache first
        if let image = memoryCache.object(forKey: key as NSString) {
            return image
        }
        
        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }
        
        // Store in memory cache for next time
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Update access time
        cacheMetadata[key]?.lastAccessed = Date()
        saveMetadata()
        
        return image
    }
    
    /// Cache an image for a user ID
    func cacheImage(_ image: UIImage, for userId: UUID) {
        let key = userId.uuidString
        
        // Store in memory cache
        memoryCache.setObject(image, forKey: key as NSString)
        
        // Store on disk
        Task {
            await saveToDisk(image, for: key)
        }
    }
    
    /// Download and cache an image from a URL for a user ID
    func downloadAndCacheImage(from urlString: String, for userId: UUID) async -> UIImage? {
        let key = userId.uuidString
        
        // Check if already cached
        if let cachedImage = getCachedImage(for: userId) {
            return cachedImage
        }
        
        // Check if already downloading
        if isDownloading(key) {
            // Wait for the download to complete
            while isDownloading(key) {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            // Try to get the cached image after download completes
            return getCachedImage(for: userId)
        }
        
        // Start download
        startDownloading(key)
        defer { stopDownloading(key) }
        
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let image = UIImage(data: data) else {
                print("Failed to create image from downloaded data for user \(userId)")
                return nil
            }
            
            // Cache the image
            cacheImage(image, for: userId)
            
            print("Successfully downloaded and cached profile picture for user \(userId)")
            return image
            
        } catch {
            print("Failed to download profile picture for user \(userId): \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Remove cached image for a user ID
    func removeCachedImage(for userId: UUID) {
        let key = userId.uuidString
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: key as NSString)
        
        // Remove from disk
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        try? fileManager.removeItem(at: fileURL)
        
        // Remove metadata
        cacheMetadata.removeValue(forKey: key)
        saveMetadata()
    }
    
    /// Clear all cached images
    func clearAllCache() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for case let fileURL as URL in enumerator {
                try? fileManager.removeItem(at: fileURL)
            }
        }
        
        // Clear metadata
        cacheMetadata.removeAll()
        saveMetadata()
    }
    
    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        
        if let enumerator = fileManager.enumerator(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let fileURL as URL in enumerator {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }
        
        return totalSize
    }
    
    // MARK: - Private Methods
    
    private func isDownloading(_ key: String) -> Bool {
        return downloadingQueue.sync {
            return downloadingImages.contains(key)
        }
    }
    
    private func startDownloading(_ key: String) {
        downloadingQueue.async(flags: .barrier) {
            self.downloadingImages.insert(key)
        }
    }
    
    private func stopDownloading(_ key: String) {
        downloadingQueue.async(flags: .barrier) {
            self.downloadingImages.remove(key)
        }
    }
    
    private func saveToDisk(_ image: UIImage, for key: String) async {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("Failed to convert image to JPEG data for key \(key)")
            return
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).jpg")
        
        do {
            try imageData.write(to: fileURL)
            
            // Update metadata
            await MainActor.run {
                cacheMetadata[key] = CacheMetadata(
                    cachedAt: Date(),
                    lastAccessed: Date(),
                    fileSize: Int64(imageData.count)
                )
                saveMetadata()
            }
            
            // Clean up if cache is too large
            await cleanupIfNeeded()
            
        } catch {
            print("Failed to save image to disk for key \(key): \(error.localizedDescription)")
        }
    }
    
    private func loadMetadata() {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode([String: CacheMetadata].self, from: data) else {
            return
        }
        cacheMetadata = metadata
    }
    
    private func saveMetadata() {
        guard let data = try? JSONEncoder().encode(cacheMetadata) else {
            return
        }
        UserDefaults.standard.set(data, forKey: metadataKey)
    }
    
    private func cleanupOldCache() {
        let cutoffDate = Date().addingTimeInterval(-maxCacheAge)
        var keysToRemove: [String] = []
        
        for (key, metadata) in cacheMetadata {
            if metadata.cachedAt < cutoffDate {
                keysToRemove.append(key)
            }
        }
        
        for key in keysToRemove {
            if let userId = UUID(uuidString: key) {
                removeCachedImage(for: userId)
            }
        }
    }
    
    private func cleanupIfNeeded() async {
        let currentSize = getCacheSize()
        
        if currentSize > maxCacheSize {
            // Sort by last accessed time and remove oldest
            let sortedEntries = cacheMetadata.sorted { $0.value.lastAccessed < $1.value.lastAccessed }
            
            for (key, _) in sortedEntries {
                if let userId = UUID(uuidString: key) {
                    removeCachedImage(for: userId)
                }
                
                // Check if we're under the limit
                if getCacheSize() < maxCacheSize * 3 / 4 { // Clean up to 75% of max size
                    break
                }
            }
        }
    }
}

// MARK: - Supporting Types

private struct CacheMetadata: Codable {
    let cachedAt: Date
    var lastAccessed: Date
    let fileSize: Int64
} 