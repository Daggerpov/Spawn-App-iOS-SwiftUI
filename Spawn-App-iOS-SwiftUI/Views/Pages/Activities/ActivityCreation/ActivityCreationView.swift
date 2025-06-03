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
            .background(Color(.systemBackground))
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
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
            .padding()
            
            Spacer()
            
            Text(currentStep.title)
                .font(.headline)
            
            Spacer()
            
            if currentStep == .activityType {
                Button(action: {
                    ActivityCreationViewModel.reInitialize()
                    closeCallback()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
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
            activityTypeView
        case .dateTime:
            dateTimeView
        case .location:
            locationView
        case .confirmation:
            confirmationView
        }
    }
    
    private var activityTypeView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What are you up to?")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(ActivityType.allCases, id: \.self) { type in
                        ActivityTypeCard(type: type, selectedType: $viewModel.selectedType)
                    }
                }
                .padding()
            }
            
            Button(action: {
                currentStep = .dateTime
            }) {
                Text("Next Step")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(universalSecondaryColor)
                    .cornerRadius(12)
            }
            .padding()
            .disabled(viewModel.selectedType == nil)
            .opacity(viewModel.selectedType == nil ? 0.6 : 1)
        }
    }
    
    private var dateTimeView: some View {
        VStack(spacing: 20) {
            // Date Picker
            DatePicker(
                "Select Date",
                selection: $viewModel.selectedDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.graphical)
            .padding()
            
            // Duration Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Activity Duration")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ActivityDuration.allCases, id: \.self) { duration in
                            Button(action: { selectedDuration = duration }) {
                                Text(duration.title)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(selectedDuration == duration ? universalSecondaryColor : Color.gray.opacity(0.1))
                                    )
                                    .foregroundColor(selectedDuration == duration ? .white : .primary)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
            
            Button(action: {
                currentStep = .location
            }) {
                Text("Next Step")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(universalSecondaryColor)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var locationView: some View {
        VStack(spacing: 20) {
            TextField("Where at?", text: .constant(""))
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // Current Location
            Button(action: {
                // Handle current location selection
            }) {
                HStack {
                    Image(systemName: "location.fill")
                    Text("Current Location")
                    Spacer()
                    Text("5934 University Blvd")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .foregroundColor(.primary)
            
            List {
                ForEach(["UBC Sauder School of Business", "AMS Student Nest", "Starbucks Coffee", "Thunderbird Park"], id: \.self) { location in
                    Button(action: {
                        // Handle location selection
                    }) {
                        HStack {
                            Text(location)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .listStyle(PlainListStyle())
            
            Button(action: {
                currentStep = .confirmation
            }) {
                Text("Next Step")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(universalSecondaryColor)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var confirmationView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)
            
            Text("Success!")
                .font(.title)
                .fontWeight(.bold)
            
            Text("You've spawned in and \"Morning Stroll\" is now live for your friends.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button(action: {
                // Handle share action
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share with your network")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button(action: {
                ActivityCreationViewModel.reInitialize()
                closeCallback()
            }) {
                Text("Return to Home")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
        }
        .padding()
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

struct ActivityTypeCard: View {
    let type: ActivityType
    @Binding var selectedType: ActivityType?
    
    var body: some View {
        Button(action: { selectedType = type }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(type.icon)
                        .font(.title)
                    Spacer()
                    Text("\(type.peopleCount) people")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(type.rawValue)
                    .font(.headline)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedType == type ? universalSecondaryColor.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedType == type ? universalSecondaryColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .foregroundColor(.primary)
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
