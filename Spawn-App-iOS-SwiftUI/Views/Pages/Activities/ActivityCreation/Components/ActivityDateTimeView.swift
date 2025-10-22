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
        case yesterday
        case today
        case tomorrow
        
        var title: String {
            switch self {
            case .yesterday: return "Yesterday"
            case .today: return "Today"
            case .tomorrow: return "Tomorrow"
            }
        }
        
        // Only show options that make sense based on current context
        static var availableOptions: [DayOption] {
            let calendar = Calendar.current
            let now = Date()
            let viewModel = ActivityCreationViewModel.shared
            
            var options: [DayOption] = [.today, .tomorrow]
            
            // Add yesterday option if editing an existing activity and it was created yesterday
            if viewModel.isEditingExistingActivity,
               let activityDate = viewModel.originalDate {
                let activityDay = calendar.startOfDay(for: activityDate)
                let yesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
                
                if activityDay == yesterday {
                    options.insert(.yesterday, at: 0)
                }
            }
            
            return options
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
            ForEach(DayOption.availableOptions, id: \.self) { day in
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
            // Validate time in real-time when day changes
            Task {
                await viewModel.validateActivityForm()
            }
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
            // Validate time in real-time
            Task {
                await viewModel.validateActivityForm()
            }
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
            // Validate time in real-time
            Task {
                await viewModel.validateActivityForm()
            }
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
            // Validate time in real-time
            Task {
                await viewModel.validateActivityForm()
            }
        }
    }
    
    private func durationButton(for duration: ActivityDuration) -> some View {
        let isSelected = selectedDuration == duration
        let borderColor = isSelected ? Color(hex: colorsIndigo500) : secondaryTextColor
        
        return Button(action: { 
            selectedDuration = duration
            viewModel.selectedDuration = duration
            syncCurrentValuesToViewModel()
            // Validate time in real-time when duration changes
            Task {
                await viewModel.validateActivityForm()
            }
        }) {
            Text(duration.title)
                .font(.custom("Onest", size: 16).weight(isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? borderColor : secondaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .fixedSize(horizontal: true, vertical: false)
                .background(durationButtonBackground(isSelected: isSelected, borderColor: borderColor))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func durationButtonBackground(isSelected: Bool, borderColor: Color) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (Friend Requests style)
            if let onBack = onBack {
                HStack {
                    ActivityBackButton {
                        // Sync current values to view model before checking changes
                        // Check for local changes before syncing
                        let hasLocalChanges = hasAnyLocalChanges()
                        
                        if hasLocalChanges {
                            showSaveConfirmation = true
                        } else {
                            onBack()
                        }
                    }
                    
                    Spacer()
                    
                    Text("What time?")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(headerTextColor)
                    
                    Spacer()
                    
                    // Invisible chevron to balance the back button
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
            } else {
                HStack {
                    // Invisible chevron to balance layout when no back
                    Image(systemName: "chevron.left")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(.clear)
                    Spacer()
                    Text("What time?")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(headerTextColor)
                    Spacer()
                    Image(systemName: "chevron.left")
                        .font(.onestSemiBold(size: 20))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 25)
                .padding(.vertical, 12)
            }
            Text("Set a time for your Activity")
                .font(.custom("Onest", size: 16))
                .foregroundColor(secondaryTextColor)
            
            ScrollView {
                VStack(spacing: 0) {
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
                            HStack(spacing: 10) {
                                dayPickerView
                                hourPickerView
                                minutePickerView
                                amPmPickerView
                            }
                            .offset(x: 4, y: 1.13)
                        }
                        .frame(height: 265)
                    }
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
                                            .stroke(showTitleError ? .red : textFieldBorderColor, lineWidth: 1)
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
                    .padding(.horizontal, 50)
                    .padding(.bottom, 24)
                    
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
                        }
                        
                    }
                    .padding(.horizontal, 50)
                    .padding(.bottom, 50)
                    
                    
                    // Time validation error message
                    if !viewModel.timeValidationMessage.isEmpty {
                        Text(viewModel.timeValidationMessage)
                            .font(.custom("Onest", size: 12))
                            .foregroundColor(.red)
                            .padding(.bottom, 8)
                    }
                    
                    // Next Step Button
                    Enhanced3DButton(title: "Next Step (Location)") {
                        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                        if trimmedTitle.isEmpty {
                            showTitleError = true
                            return
                        }
                        showTitleError = false
                        
                        // Sync current values and validate time
                        syncCurrentValuesToViewModel()
                        Task {
                            await viewModel.validateActivityForm()
                            
                            await MainActor.run {
                                if viewModel.isTimeValid {
                                    onNext()
                                }
                                // If time is invalid, the error message will be displayed
                            }
                        }
                    }
                    .padding(.horizontal, 50)
                    
                    // Step indicators
                    StepIndicatorView(currentStep: 1, totalSteps: 3)
                        .padding(.top, 16)
                }
            }
            
          
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
            Text("You have unsaved changes.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func hasAnyLocalChanges() -> Bool {
        guard viewModel.isEditingExistingActivity else { return false }
        
        // Check title changes
        let currentTitle = activityTitle.trimmingCharacters(in: .whitespaces)
        let originalTitle = viewModel.originalTitle?.trimmingCharacters(in: .whitespaces) ?? ""
        if currentTitle != originalTitle {
            return true
        }
        
        // Check other changes using view model's computed properties
        // But first sync the current values to make sure they're up to date
        syncCurrentValuesToViewModel()
        
        return viewModel.dateChanged || viewModel.durationChanged || viewModel.locationChanged
    }
    
    
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
        case .yesterday:
            baseDate = calendar.date(byAdding: .day, value: -1, to: now) ?? now
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
        
        // Determine the correct day option based on the existing activity's date if editing
        if viewModel.isEditingExistingActivity {
            selectedDay = determineDayOptionFromActivityDate()
        }
        
        // Update the selected date with initial values
        updateSelectedDate()
    }
    
    private func determineDayOptionFromActivityDate() -> DayOption {
        guard let activityDate = viewModel.selectedDate != Date() ? viewModel.selectedDate : viewModel.originalDate else {
            return .today
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let activityDay = calendar.startOfDay(for: activityDate)
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        
        if activityDay == yesterday {
            return .yesterday
        } else if activityDay == today {
            return .today
        } else if activityDay == tomorrow {
            return .tomorrow
        } else {
            // For dates beyond yesterday/today/tomorrow, default to today
            // In the future, we might want to add more options or handle this differently
            return .today
        }
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
