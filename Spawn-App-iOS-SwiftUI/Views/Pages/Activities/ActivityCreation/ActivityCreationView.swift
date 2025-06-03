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
    
    // Time selection state
    @State private var selectedHour: Int = 9
    @State private var selectedMinute: Int = 30
    @State private var isAM: Bool = true
    @State private var activityTitle: String = ""
    
    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void
    
    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                content
                    .animation(.easeInOut, value: currentStep)
            }
            .background(universalBackgroundColor)
            .sheet(isPresented: $showShareSheet) {
                ShareSheet()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: {
                switch currentStep {
                case .activityType:
                    ActivityCreationViewModel.reInitialize()
                    closeCallback()
                default:
                    currentStep = currentStep.previous()
                }
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(universalAccentColor)
                    .imageScale(.large)
            }
            .padding()
            
            Spacer()
            
            Text(currentStep.title)
                .font(.headline)
                .foregroundColor(universalAccentColor)
            
            Spacer()
            
            if currentStep == .activityType {
                Button(action: {
                    ActivityCreationViewModel.reInitialize()
                    closeCallback()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(universalAccentColor)
                        .imageScale(.large)
                }
                .padding()
            } else {
                // Empty view to maintain spacing
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
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
                currentStep = .location
            }
        case .location:
            ActivityCreationLocationView {
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
