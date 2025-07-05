//
//  ActivityColorService.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-03.
//

import Foundation
import SwiftUI

/// Service responsible for managing activity color assignments with even distribution and caching
class ActivityColorService: ObservableObject {
    static let shared = ActivityColorService()
    
    // MARK: - Color Distribution State
    @Published private var activityColors: [UUID: Color] = [:]
    private var colorUsageCount: [Color: Int] = [:]
    private var nextColorIndex: Int = 0
    
    // MARK: - Constants
    private let availableColors: [Color] = [
        Color(hex: "#FD4E4C"), // Red
        Color(hex: "#FF6B35"), // Orange
        Color(hex: "#536AEE"), // Indigo
        Color(hex: "#1AB979"), // Green
        Color(hex: "#ED64A6"), // Pink
        Color(hex: "#38B2AC"), // Teal
        Color(hex: "#1D85E7"), // Blue
        Color(hex: "#703CE5"), // Purple
        Color(hex: "#242CBB")  // Dark Indigo
    ]
    
    private enum CacheKeys {
        static let activityColors = "activityColors"
        static let colorUsageCount = "colorUsageCount"
        static let nextColorIndex = "nextColorIndex"
    }
    
    private init() {
        loadFromCache()
    }
    
    // MARK: - Public Methods
    
    /// Get color for an activity, assigning a new one if needed
    func getColorForActivity(_ activityId: UUID) -> Color {
        // Return cached color if available
        if let existingColor = activityColors[activityId] {
            return existingColor
        }
        
        // Assign new color with even distribution
        let newColor = assignNextColor()
        activityColors[activityId] = newColor
        
        // Update usage count
        colorUsageCount[newColor, default: 0] += 1
        
        // Save to cache
        saveToCache()
        
        return newColor
    }
    
    /// Get hex string for an activity color
    func getColorHexForActivity(_ activityId: UUID) -> String {
        let color = getColorForActivity(activityId)
        return color.toHex()
    }
    
    /// Pre-assign colors for a batch of activities to ensure even distribution
    func assignColorsForActivities(_ activityIds: [UUID]) {
        var newAssignments: [UUID: Color] = [:]
        
        for activityId in activityIds {
            // Skip if already assigned
            if activityColors[activityId] != nil {
                continue
            }
            
            let newColor = assignNextColor()
            newAssignments[activityId] = newColor
            activityColors[activityId] = newColor
            colorUsageCount[newColor, default: 0] += 1
        }
        
        if !newAssignments.isEmpty {
            saveToCache()
        }
    }
    
    /// Clear all color assignments (useful for testing or reset)
    func clearAllColorAssignments() {
        activityColors.removeAll()
        colorUsageCount.removeAll()
        nextColorIndex = 0
        saveToCache()
    }
    
    /// Get statistics about color distribution
    func getColorDistributionStats() -> [String: Int] {
        var stats: [String: Int] = [:]
        for (color, count) in colorUsageCount {
            stats[color.toHex()] = count
        }
        return stats
    }
    
    // MARK: - Private Methods
    
    /// Assign the next color using round-robin distribution
    private func assignNextColor() -> Color {
        let color = availableColors[nextColorIndex]
        nextColorIndex = (nextColorIndex + 1) % availableColors.count
        return color
    }
    
    /// Load cached color assignments from UserDefaults
    private func loadFromCache() {
        // Load activity colors
        if let colorsData = UserDefaults.standard.data(forKey: CacheKeys.activityColors),
           let colorDict = try? JSONDecoder().decode([String: String].self, from: colorsData) {
            for (uuidString, hexString) in colorDict {
                if let uuid = UUID(uuidString: uuidString) {
                    activityColors[uuid] = Color(hex: hexString)
                }
            }
        }
        
        // Load color usage count
        if let usageData = UserDefaults.standard.data(forKey: CacheKeys.colorUsageCount),
           let usageDict = try? JSONDecoder().decode([String: Int].self, from: usageData) {
            for (hexString, count) in usageDict {
                colorUsageCount[Color(hex: hexString)] = count
            }
        }
        
        // Load next color index
        nextColorIndex = UserDefaults.standard.integer(forKey: CacheKeys.nextColorIndex)
    }
    
    /// Save color assignments to UserDefaults
    private func saveToCache() {
        // Save activity colors
        var colorDict: [String: String] = [:]
        for (uuid, color) in activityColors {
            colorDict[uuid.uuidString] = color.toHex()
        }
        if let colorsData = try? JSONEncoder().encode(colorDict) {
            UserDefaults.standard.set(colorsData, forKey: CacheKeys.activityColors)
        }
        
        // Save color usage count
        var usageDict: [String: Int] = [:]
        for (color, count) in colorUsageCount {
            usageDict[color.toHex()] = count
        }
        if let usageData = try? JSONEncoder().encode(usageDict) {
            UserDefaults.standard.set(usageData, forKey: CacheKeys.colorUsageCount)
        }
        
        // Save next color index
        UserDefaults.standard.set(nextColorIndex, forKey: CacheKeys.nextColorIndex)
    }
}

// MARK: - Color Extension for Hex Conversion
extension Color {
    /// Convert Color to hex string
    func toHex() -> String {
        return self.hex
    }
} 