//
//  SMSShareServiceTests.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Claude AI on 2025-01-21.
//

import Foundation

// Simple test functions to verify SMS message generation
// This is not a formal test suite but can be used for manual verification

extension SMSShareService {
    
    /// Test function to verify the SMS message format
    static func testMessageGeneration() {
        print("🧪 Testing SMS message generation...")
        
        // Create a test activity
        let testActivity = FullFeedActivityDTO(
            id: UUID(),
            title: "Lunch",
            startTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date()),
            location: LocationDTO(
                id: UUID(),
                name: "Sahel's",
                latitude: 49.2827,
                longitude: -123.1207
            ),
            note: "Let's grab some food!",
            icon: "🍽️",
            creatorUser: BaseUserDTO(
                id: UUID(),
                username: "daniel",
                name: "Daniel",
                email: "daniel@example.com"
            )
        )
        
        let testURL = URL(string: "https://getspawn.com/activity/abc123")!
        
        let service = SMSShareService.shared
        let message = service.generateActivitySMSMessage(activity: testActivity, shareURL: testURL)
        
        print("📱 Generated SMS message:")
        print("---")
        print(message)
        print("---")
        
        // Verify message components
        let expectedComponents = [
            "Daniel has invited you to Lunch @ Sahel's",
            "in 30 min", // Should contain time reference
            "See this activity and its chats on Spawn to stay in the loop:",
            "https://apps.apple.com/ca/app/spawn/id6738635871?platform=iphone",
            "It's never been easier to be spontaneous. Join your friends today!"
        ]
        
        var allComponentsFound = true
        for component in expectedComponents {
            if !message.contains(component) {
                print("❌ Missing component: \(component)")
                allComponentsFound = false
            }
        }
        
        if allComponentsFound {
            print("✅ All expected message components found!")
        } else {
            print("❌ Some message components are missing")
        }
        
        print("🧪 SMS message generation test complete\n")
    }
    
    /// Test function to verify App Store constants
    static func testAppStoreConstants() {
        print("🧪 Testing App Store constants...")
        
        let expectedURL = "https://apps.apple.com/ca/app/spawn/id6738635871?platform=iphone"
        let actualURL = AppStoreLinks.appStoreURL
        
        if actualURL == expectedURL {
            print("✅ App Store URL is correct: \(actualURL)")
        } else {
            print("❌ App Store URL mismatch:")
            print("   Expected: \(expectedURL)")
            print("   Actual: \(actualURL)")
        }
        
        print("🧪 App Store constants test complete\n")
    }
    
    /// Run all tests
    static func runAllTests() {
        print("🧪 Starting SMSShareService tests...\n")
        testMessageGeneration()
        testAppStoreConstants()
        print("🧪 All SMSShareService tests complete!")
    }
}

// Usage example (call from somewhere in your app for testing):
// SMSShareService.runAllTests()
