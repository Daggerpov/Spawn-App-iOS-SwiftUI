//
//  ActivityCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI
import MCEmojiPicker

struct ActivityCreationView: View {
    @ObservedObject var viewModel: ActivityCreationViewModel = ActivityCreationViewModel.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ActivityCreationStep = .activityType
    @State private var selectedDuration: ActivityDuration = .indefinite
    @State private var showLocationPicker = false
    @State private var showShareSheet = false
    
    // Time selection state - now initialized with calculated default values
    @State private var selectedHour: Int
    @State private var selectedMinute: Int
    @State private var isAM: Bool
    @State private var activityTitle: String = ""
    
    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void
    
    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
        
        // Calculate the next 15-minute interval after current time
        let nextInterval = Self.calculateNextFifteenMinuteInterval()
        self._selectedHour = State(initialValue: nextInterval.hour)
        self._selectedMinute = State(initialValue: nextInterval.minute)
        self._isAM = State(initialValue: nextInterval.isAM)
    }
    
    // Helper function to calculate the next 15-minute interval
    static func calculateNextFifteenMinuteInterval() -> (hour: Int, minute: Int, isAM: Bool) {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Calculate next 15-minute interval
        let nextMinute: Int
        var nextHour = currentHour
        
        if currentMinute < 15 {
            nextMinute = 15
        } else if currentMinute < 30 {
            nextMinute = 30
        } else if currentMinute < 45 {
            nextMinute = 45
        } else {
            nextMinute = 0
            nextHour += 1
            if nextHour >= 24 {
                nextHour = 0
            }
        }
        
        // Convert to 12-hour format
        let isAM = nextHour < 12
        let displayHour = nextHour == 0 ? 12 : (nextHour > 12 ? nextHour - 12 : nextHour)
        
        return (hour: displayHour, minute: nextMinute, isAM: isAM)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content
            content
                .animation(.easeInOut, value: currentStep)
        }
        .background(universalBackgroundColor)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet()
        }
        .onAppear {
            // Initialize activityTitle from view model if it exists
            if let title = viewModel.activity.title, !title.isEmpty {
                activityTitle = title
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch currentStep {
        case .activityType:
            ActivityTypeView(selectedType: $viewModel.selectedType) {
                currentStep = .dateTime
            }
        case .dateTime:
            ActivityDateTimeView(
                selectedHour: $selectedHour,
                selectedMinute: $selectedMinute,
                isAM: $isAM,
                activityTitle: $activityTitle,
                selectedDuration: $selectedDuration
            ) {
                // Sync the activity title with the view model before proceeding
                viewModel.activity.title = activityTitle.trimmingCharacters(in: .whitespaces)
                
                // Validate the title is not empty
                if viewModel.activity.title?.isEmpty ?? true {
                    // Show error or prevent progression
                    return
                }
                
                currentStep = .location
            }
        case .location:
            ActivityCreationLocationView {
                // Ensure title is still synced when moving from location to confirmation
                if !activityTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.activity.title = activityTitle.trimmingCharacters(in: .whitespaces)
                }
                currentStep = .confirmation
            }
        case .confirmation:
            ActivityConfirmationView(
                showShareSheet: $showShareSheet,
                onClose: {
                    ActivityCreationViewModel.reInitialize()
                    closeCallback()
                }
            )
        }
    }
}

// MARK: - Supporting Types

enum ActivityCreationStep {
    case activityType
    case dateTime
    case location
    case confirmation
    
    var title: String {
        switch self {
        case .activityType: return "What are you up to?"
        case .dateTime: return "Activity Details"
        case .location: return "Choose Location"
        case .confirmation: return "Confirm"
        }
    }
    
    func previous() -> ActivityCreationStep {
        switch self {
        case .activityType: return .activityType
        case .dateTime: return .activityType
        case .location: return .dateTime
        case .confirmation: return .location
        }
    }
}

enum ActivityType: String, CaseIterable {
    case foodAndDrink = "Food & Drink"
    case active = "Active"
    case grind = "Grind"
    case chill = "Chill"
    case general = "General"
    
    var icon: String {
        switch self {
        case .foodAndDrink: return "🍽️"
        case .active: return "🏃"
        case .grind: return "💼"
        case .chill: return "🛋️"
        case .general: return "⭐️"
        }
    }
    
    var peopleCount: Int {
        switch self {
        case .foodAndDrink: return 19
        case .active: return 12
        case .grind: return 17
        case .chill: return 7
        case .general: return 14
        }
    }
}

enum ActivityDuration: CaseIterable {
    case indefinite
    case twoHours
    case oneHour
    case thirtyMinutes
    
    var title: String {
        switch self {
        case .indefinite: return "Indefinite"
        case .twoHours: return "2 hours"
        case .oneHour: return "1 hour"
        case .thirtyMinutes: return "30 mins"
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    ActivityCreationView(
        creatingUser: .danielAgapov,
        closeCallback: {
        }
    ).environmentObject(appCache)
}
