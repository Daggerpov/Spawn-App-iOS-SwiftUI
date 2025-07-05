import SwiftUI

struct ActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    let onBack: (() -> Void)?
    
    // Access to the view model to update selectedDate
    @ObservedObject private var viewModel = ActivityCreationViewModel.shared
    
    // State for day selection
    @State private var selectedDay: DayOption = .today
    
    // State for tomorrow's default time
    @State private var tomorrowHour: Int = 10
    @State private var tomorrowMinute: Int = 45
    @State private var tomorrowIsAM: Bool = false
    
    // Validation state
    @State private var showTitleError: Bool = false
    
    // Available options for the pickers
    private let hours = Array(1...12)
    private let minutes = [0, 15, 30, 45]
    private let amPmOptions = ["AM", "PM"]
    
    enum DayOption: CaseIterable {
        case today
        case tomorrow
        
        var title: String {
            switch self {
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button at the top
            if let onBack = onBack {
                HStack {
                    ActivityBackButton {
                        onBack()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    VStack(spacing: 12) {
                        Text("What time?")
                            .font(.onestSemiBold(size: 28))
                            .foregroundColor(universalAccentColor)
                        
                        Text("Set a time for your \"\(viewModel.selectedType?.rawValue ?? "Activity")\" Activity")
                            .font(.onestRegular(size: 16))
                            .foregroundColor(figmaBlack300)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 32)
                    
                    // Time Picker Section - Improved Layout with more spacing
                    VStack(spacing: 24) {
                        HStack(spacing: 8) {
                            // Day picker (Today/Tomorrow)
                            Picker("Day", selection: $selectedDay) {
                                ForEach(DayOption.allCases, id: \.self) { day in
                                    Text(day.title)
                                        .font(.onestRegular(size: 28.75))
                                        .foregroundColor(universalAccentColor)
                                        .tag(day)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                            .clipped()
                            .onChange(of: selectedDay) { _ in
                                if selectedDay == .tomorrow {
                                    selectedHour = tomorrowHour
                                    selectedMinute = tomorrowMinute
                                    isAM = tomorrowIsAM
                                }
                                updateSelectedDate()
                            }
                            
                            // Visual separator
                            Rectangle()
                                .fill(figmaLightGrey)
                                .frame(width: 1, height: 80)
                            
                            // Hour picker
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(hours, id: \.self) { h in
                                    Text("\(h)")
                                        .font(.onestRegular(size: 28.75))
                                        .foregroundColor(universalAccentColor)
                                        .tag(h)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 50)
                            .clipped()
                            .onChange(of: selectedHour) { _ in
                                if selectedDay == .tomorrow {
                                    tomorrowHour = selectedHour
                                }
                                updateSelectedDate()
                            }
                            
                            // Minute picker
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(minutes, id: \.self) { m in
                                    Text(String(format: "%02d", m))
                                        .font(.onestRegular(size: 28.75))
                                        .foregroundColor(universalAccentColor)
                                        .tag(m)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: selectedMinute) { _ in
                                if selectedDay == .tomorrow {
                                    tomorrowMinute = selectedMinute
                                }
                                updateSelectedDate()
                            }
                            
                            // AM/PM picker
                            Picker("AM/PM", selection: $isAM) {
                                Text("AM")
                                    .font(.onestRegular(size: 28.75))
                                    .foregroundColor(universalAccentColor)
                                    .tag(true)
                                Text("PM")
                                    .font(.onestRegular(size: 28.75))
                                    .foregroundColor(universalAccentColor)
                                    .tag(false)
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            .clipped()
                            .onChange(of: isAM) { _ in
                                if selectedDay == .tomorrow {
                                    tomorrowIsAM = isAM
                                }
                                updateSelectedDate()
                            }
                        }
                        .frame(height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(figmaGrey.opacity(0.5))
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Title")
                                .font(.onestMedium(size: 16))
                                .foregroundColor(showTitleError ? .red : figmaBlack300)
                            
                            if showTitleError {
                                Text("*")
                                    .font(.onestMedium(size: 16))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        
                        TextField("Enter Activity Title", text: $activityTitle)
                            .font(.onestRegular(size: 16))
                            .foregroundColor(universalAccentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(universalBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(showTitleError ? .red : figmaLightGrey, lineWidth: 1.5)
                                    )
                            )
                            .onChange(of: activityTitle) { newValue in
                                // Update the activity title in the view model
                                viewModel.activity.title = newValue.isEmpty ? nil : newValue
                                // Hide error when user starts typing
                                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    showTitleError = false
                                }
                            }
                        
                        if showTitleError {
                            Text("Activity title is required")
                                .font(.onestRegular(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Duration Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Activity Duration")
                                .font(.onestMedium(size: 16))
                                .foregroundColor(figmaBlack300)
                            Spacer()
                        }
                        
                        // Duration buttons - horizontal layout with better styling
                        HStack(spacing: 12) {
                            ForEach(ActivityDuration.allCases, id: \.self) { duration in
                                Button(action: { 
                                    selectedDuration = duration
                                    viewModel.selectedDuration = duration
                                }) {
                                    Text(duration.title)
                                        .font(.onestMedium(size: 16))
                                        .foregroundColor(selectedDuration == duration ? .white : figmaBlack300)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(selectedDuration == duration ? 
                                                     figmaSoftBlue : 
                                                     figmaLightGrey)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
            
            Spacer()
            
            // Step indicators
            StepIndicatorView(currentStep: 1, totalSteps: 3)
                .padding(.bottom, 20)
            
            // Next Step Button
            ActivityNextStepButton(
                title: "Next Step (Location)",
                isEnabled: true
            ) {
                let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                if trimmedTitle.isEmpty {
                    showTitleError = true
                    return
                }
                showTitleError = false
                updateSelectedDate()
                onNext()
            }
        }
        .background(universalBackgroundColor)
        .onAppear {
            initializeDateAndTime()
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateSelectedDate() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get the base date (today or tomorrow)
        let baseDate: Date
        switch selectedDay {
        case .today:
            baseDate = now
        case .tomorrow:
            baseDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        }
        
        // Convert 12-hour to 24-hour format
        let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
        dateComponents.hour = hour24
        dateComponents.minute = selectedMinute
        dateComponents.second = 0
        
        if let finalDate = calendar.date(from: dateComponents) {
            viewModel.selectedDate = finalDate
        }
    }
    
    private func initializeDateAndTime() {
        // Set initial duration in view model
        viewModel.selectedDuration = selectedDuration
        
        // Set initial title if not empty
        if !activityTitle.isEmpty {
            viewModel.activity.title = activityTitle
        }
        
        // Update the selected date with initial values
        updateSelectedDate()
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var selectedHour: Int = 9
    @Previewable @State var selectedMinute: Int = 30
    @Previewable @State var isAM: Bool = true
    @Previewable @State var activityTitle: String = "Morning Coffee"
    @Previewable @State var selectedDuration: ActivityDuration = .oneHour
    @Previewable @StateObject var appCache = AppCache.shared
    
    ActivityDateTimeView(
        selectedHour: $selectedHour,
        selectedMinute: $selectedMinute,
        isAM: $isAM,
        activityTitle: $activityTitle,
        selectedDuration: $selectedDuration,
        onNext: {
            print("Next step tapped")
        },
        onBack: {
            print("Back tapped")
        }
    )
    .environmentObject(appCache)
} 
