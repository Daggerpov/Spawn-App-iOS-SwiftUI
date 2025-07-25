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
    
    // Environment for color scheme detection
    @Environment(\.colorScheme) private var colorScheme
    
    // State for day selection
    @State private var selectedDay: DayOption = .today
    
    // State for tomorrow's default time
    @State private var tomorrowHour: Int = 10
    @State private var tomorrowMinute: Int = 45
    @State private var tomorrowIsAM: Bool = false
    
    // Validation state
    @State private var showTitleError: Bool = false
    
    // State for comprehensive changes confirmation
    @State private var showSaveConfirmation: Bool = false
    
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
    
    // MARK: - Adaptive Colors
    
    private var pickerBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .light:
            return .white
        @unknown default:
            return .white
        }
    }
    
    private var pickerTextColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        @unknown default:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        }
    }
    
    private var separatorColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var headerTextColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        @unknown default:
            return Color(red: 0.11, green: 0.11, blue: 0.11)
        }
    }
    
    private var secondaryTextColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.7)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var textFieldBackgroundColor: Color {
        switch colorScheme {
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .light:
            return .white
        @unknown default:
            return .white
        }
    }
    
    private var textFieldBorderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        @unknown default:
            return Color(red: 0.52, green: 0.49, blue: 0.49)
        }
    }
    
    private var titleLabelColor: Color {
        switch colorScheme {
        case .dark:
            return .white
        case .light:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        @unknown default:
            return Color(red: 0.15, green: 0.14, blue: 0.14)
        }
    }
    
    private var stepIndicatorInactiveColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.3)
        case .light:
            return Color(red: 0.88, green: 0.85, blue: 0.85)
        @unknown default:
            return Color(red: 0.88, green: 0.85, blue: 0.85)
        }
    }
    
    // MARK: - Picker Views
    
    private var dayPickerView: some View {
        Picker("Day", selection: $selectedDay) {
            ForEach(DayOption.allCases, id: \.self) { day in
                Text(day.title)
                    .font(Font.custom("Onest", size: 22))
                    .foregroundColor(pickerTextColor)
                    .tag(day)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: 130)
        .clipped()
        .onChange(of: selectedDay) { _ in
            if selectedDay == .tomorrow {
                selectedHour = tomorrowHour
                selectedMinute = tomorrowMinute
                isAM = tomorrowIsAM
            }
            updateSelectedDate()
            syncCurrentValuesToViewModel()
        }
    }
    
    private var hourPickerView: some View {
        Picker("Hour", selection: $selectedHour) {
            ForEach(hours, id: \.self) { h in
                Text("\(h)")
                    .font(.custom("Onest", size: 26))
                    .foregroundColor(pickerTextColor)
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
            syncCurrentValuesToViewModel()
        }
    }
    
    private var minutePickerView: some View {
        Picker("Minute", selection: $selectedMinute) {
            ForEach(minutes, id: \.self) { m in
                Text(String(format: "%02d", m))
                    .font(.custom("Onest", size: 26))
                    .foregroundColor(pickerTextColor)
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
            syncCurrentValuesToViewModel()
        }
    }
    
    private var amPmPickerView: some View {
        Picker("AM/PM", selection: $isAM) {
            Text("AM")
                .font(.custom("Onest", size: 26))
                .foregroundColor(pickerTextColor)
                .tag(true)
            Text("PM")
                .font(.custom("Onest", size: 26))
                .foregroundColor(pickerTextColor)
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
            syncCurrentValuesToViewModel()
        }
    }
    
    private func durationButton(for duration: ActivityDuration) -> some View {
        let isSelected = selectedDuration == duration
        let borderColor = Color(red: 0.33, green: 0.42, blue: 0.93)
        
        return Button(action: { 
            selectedDuration = duration
            viewModel.selectedDuration = duration
            syncCurrentValuesToViewModel()
        }) {
            Text(duration.title)
                .font(.custom("Onest", size: 16).weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? borderColor : secondaryTextColor)
                .padding(12)
                .background(durationButtonBackground(isSelected: isSelected, borderColor: borderColor))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func durationButtonBackground(isSelected: Bool, borderColor: Color) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .inset(by: isSelected ? 1 : 0.5)
                    .stroke(borderColor, lineWidth: isSelected ? 1 : 0.5)
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Back button at the top
            if let onBack = onBack {
                HStack {
                    ActivityBackButton {
                        // Sync current values to view model before checking changes
                        syncCurrentValuesToViewModel()
                        
                        if viewModel.hasAnyChanges {
                            showSaveConfirmation = true
                        } else {
                            onBack()
                        }
                    }
                    .padding(.leading, 24)
                    
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.bottom, 12)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    // Header Section
                    VStack(spacing: 12) {
                        Text("What time?")
                            .font(.custom("Onest", size: 20).weight(.semibold))
                            .foregroundColor(headerTextColor)
                        
                        Text("Set a time for your \"\(viewModel.selectedActivityType?.title ?? "Activity")\" Activity")
                            .font(.custom("Onest", size: 16).weight(.medium))
                            .foregroundColor(secondaryTextColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    
                    // Time Picker Section - Updated to match Figma design
                    VStack(spacing: 0) {
                        ZStack {
                            // Background
                            Rectangle()
                                .fill(pickerBackgroundColor)
                                .frame(height: 265)
                                .cornerRadius(12)
                            
                            // Horizontal separator lines
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(separatorColor)
                                    .frame(height: 0.31)
                                    .offset(y: -18.25)
                                Rectangle()
                                    .fill(separatorColor)
                                    .frame(height: 0.31)
                                    .offset(y: 20.5)
                            }
                            
                            // Picker content
                            HStack(spacing: 24) {
                                dayPickerView
                                hourPickerView
                                minutePickerView
                                amPmPickerView
                            }
                            .offset(x: 4, y: 1.13)
                        }
                        .frame(height: 265)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 4)
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Title")
                                .font(.custom("Onest", size: 16))
                                .foregroundColor(showTitleError ? .red : titleLabelColor)
                            
                            if showTitleError {
                                Text("*")
                                    .font(.custom("Onest", size: 16))
                                    .foregroundColor(.red)
                            }
                            Spacer()
                        }
                        
                        TextField("Enter Activity Title", text: $activityTitle)
                            .font(.custom("Onest", size: 16))
                            .foregroundColor(secondaryTextColor)
                            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(textFieldBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .inset(by: 0.5)
                                            .stroke(showTitleError ? .red : textFieldBorderColor, lineWidth: 0.5)
                                    )
                            )
                            .onChange(of: activityTitle) { newValue in
                                // Update the activity title in the view model
                                viewModel.activity.title = newValue.isEmpty ? nil : newValue
                                // Hide error when user starts typing
                                if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                                    showTitleError = false
                                }
                                syncCurrentValuesToViewModel()
                            }
                        
                        if showTitleError {
                            Text("Activity title is required")
                                .font(.custom("Onest", size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Duration Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Activity Duration")
                                .font(.custom("Onest", size: 16).weight(.medium))
                                .foregroundColor(titleLabelColor)
                            Spacer()
                        }
                        
                        // Duration buttons - horizontal layout with Figma styling
                        HStack(spacing: 8) {
                            ForEach(ActivityDuration.allCases, id: \.self) { duration in
                                durationButton(for: duration)
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)
            }
            
            Spacer()
            
            // Next Step Button
            Enhanced3DButton(title: "Next Step (Location)") {
                let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                if trimmedTitle.isEmpty {
                    showTitleError = true
                    return
                }
                showTitleError = false
                syncCurrentValuesToViewModel()
                onNext()
            }
            .padding(.horizontal, 20)
            
            // Step indicators
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.27, green: 0.87, blue: 0.63))
                    .frame(width: 32, height: 8)
                RoundedRectangle(cornerRadius: 16)
                    .fill(stepIndicatorInactiveColor)
                    .frame(width: 32, height: 8)
                RoundedRectangle(cornerRadius: 16)
                    .fill(stepIndicatorInactiveColor)
                    .frame(width: 32, height: 8)
            }
            .padding(.top, 16)
            .padding(.bottom, 30)
        }
        .background(universalBackgroundColor)
        .onAppear {
            initializeDateAndTime()
        }
        .alert("Save All Changes?", isPresented: $showSaveConfirmation) {
            Button("Don't Save", role: .destructive) {
                // Reset to original values and go back without saving
                viewModel.resetToOriginalValues()
                onBack?()
            }
			Button("Save All Changes") {
                // Save changes by calling onNext to proceed through the flow
                let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                if trimmedTitle.isEmpty {
                    showTitleError = true
                    return
                }
                showTitleError = false
                syncCurrentValuesToViewModel()
                
                // For editing flow, we need to save ALL changes and close the flow
                // This means updating the activity with all the accumulated changes
                Task {
                    await viewModel.updateActivity()
                    await MainActor.run {
                        onBack?()
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                // Stay on the current screen
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("You have unsaved changes across multiple screens:")
                Text(viewModel.getChangesSummaryText())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func syncCurrentValuesToViewModel() {
        // Update activity title
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
        viewModel.activity.title = trimmedTitle.isEmpty ? nil : trimmedTitle
        
        // Update selected date
        updateSelectedDate()
        
        // Update duration
        viewModel.selectedDuration = selectedDuration
    }
    
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
