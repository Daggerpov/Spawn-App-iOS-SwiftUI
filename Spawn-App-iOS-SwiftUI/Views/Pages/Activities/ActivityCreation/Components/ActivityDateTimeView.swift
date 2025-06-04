import SwiftUI

struct ActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    
    // Access to the view model to update selectedDate
    @ObservedObject private var viewModel = ActivityCreationViewModel.shared
    
    // Native date picker state
    @State private var selectedDate: Date = Date()
    @State private var selectedDay: DayOption = .today
    
    // Tomorrow's date state
    @State private var tomorrowDate: Date = Date()
    
    // Validation state
    @State private var showTitleError: Bool = false
    
    // Computed properties for today and tomorrow dates
    private var todayDate: Date {
        let calendar = Calendar.current
        let now = Date()
        let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
        
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour24
        components.minute = selectedMinute
        components.second = 0
        
        return calendar.date(from: components) ?? now
    }
    
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
            ScrollView {
                VStack(spacing: 32) {
                    // Time Selection Section - Using Native DatePickers
                    VStack(spacing: 24) {
                        // Today row - selected option
                        HStack {
                            // Today/Tomorrow selector
                            Button(action: { updateDay(.today) }) {
                                Text("Today")
                                    .font(.system(size: 16, weight: selectedDay == .today ? .medium : .regular))
                                    .foregroundColor(selectedDay == .today ? .black : Color.gray.opacity(0.5))
                                    .frame(width: 80, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Native DatePicker for Today
                            if selectedDay == .today {
                                DatePicker("", selection: Binding(
                                    get: { todayDate },
                                    set: { newDate in
                                        updateFromDate(newDate, isToday: true)
                                    }
                                ))
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .scaleEffect(1.0)
                            } else {
                                // Show static time when not selected
                                HStack(spacing: 20) {
                                    Text("\(selectedHour)")
                                        .font(.system(size: 32, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text(String(format: "%02d", selectedMinute))
                                        .font(.system(size: 32, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text(isAM ? "AM" : "PM")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Tomorrow row - alternative option
                        HStack {
                            // Today/Tomorrow selector
                            Button(action: { updateDay(.tomorrow) }) {
                                Text("Tomorrow")
                                    .font(.system(size: 16, weight: selectedDay == .tomorrow ? .medium : .regular))
                                    .foregroundColor(selectedDay == .tomorrow ? .black : Color.gray.opacity(0.5))
                                    .frame(width: 80, alignment: .leading)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                            
                            // Native DatePicker for Tomorrow
                            if selectedDay == .tomorrow {
                                DatePicker("", selection: $tomorrowDate)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .scaleEffect(1.0)
                                    .onChange(of: tomorrowDate) { newDate in
                                        updateFromDate(newDate, isToday: false)
                                    }
                            } else {
                                // Show static time when not selected
                                HStack(spacing: 20) {
                                    let calendar = Calendar.current
                                    let components = calendar.dateComponents([.hour, .minute], from: tomorrowDate)
                                    let hour24 = components.hour ?? 10
                                    let minute = components.minute ?? 45
                                    let displayHour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
                                    let isAMDisplay = hour24 < 12
                                    
                                    Text("\(displayHour)")
                                        .font(.system(size: selectedDay == .tomorrow ? 32 : 16, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text(String(format: "%02d", minute))
                                        .font(.system(size: selectedDay == .tomorrow ? 32 : 16, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                    
                                    Text(isAMDisplay ? "AM" : "PM")
                                        .font(.system(size: 16, weight: .regular))
                                        .foregroundColor(Color.gray.opacity(0.3))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(showTitleError ? .red : Color.gray)
                            Spacer()
                        }
                        
                        TextField("Enter Activity Title", text: $activityTitle)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showTitleError ? .red : Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
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
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Duration Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Activity Duration")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.gray)
                            Spacer()
                        }
                        
                        // Duration buttons - horizontal layout matching Figma
                        HStack(spacing: 12) {
                            ForEach(ActivityDuration.allCases, id: \.self) { duration in
                                Button(action: { 
                                    selectedDuration = duration
                                    viewModel.selectedDuration = duration
                                }) {
                                    Text(duration.title)
                                        .font(Font.custom("Onest", size: 16).weight(.bold))
                                        .foregroundColor(selectedDuration == duration ? figmaSoftBlue : Color.gray)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 24)
                                                .fill(selectedDuration == duration ? 
                                                     Color.blue.opacity(0.1) : 
                                                     Color.gray.opacity(0.1))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 24)
                                                        .stroke(selectedDuration == duration ? 
                                                               figmaSoftBlue :
                                                               Color.gray.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
            
            // Next Step Button
            VStack {
                Button(action: {
                    let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespaces)
                    if trimmedTitle.isEmpty {
                        showTitleError = true
                        return
                    }
                    onNext()
                }) {
                    HStack(alignment: .center, spacing: 8) {
                        Text("Next Step")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(16)
                    .frame(width: 375, height: 56, alignment: .center)
                    .background(Color(red: 0.42, green: 0.51, blue: 0.98))
                    .cornerRadius(16)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(universalBackgroundColor)
        .onAppear {
            initializeDateAndTime()
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateDay(_ day: DayOption) {
        selectedDay = day
        updateSelectedDate()
    }
    
    private func updateFromDate(_ date: Date, isToday: Bool) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        let hour24 = components.hour ?? 0
        let minute = components.minute ?? 0
        
        // Convert to 12-hour format
        let displayHour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
        let isAMValue = hour24 < 12
        
        if isToday {
            selectedHour = displayHour
            selectedMinute = minute
            isAM = isAMValue
        }
        
        updateSelectedDate()
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
        
        // Use the appropriate time based on selected day
        let finalDate: Date
        switch selectedDay {
        case .today:
            // Convert 12-hour to 24-hour format
            let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
            
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: baseDate)
            dateComponents.hour = hour24
            dateComponents.minute = selectedMinute
            dateComponents.second = 0
            
            finalDate = calendar.date(from: dateComponents) ?? baseDate
        case .tomorrow:
            finalDate = tomorrowDate
            
            // Update binding values to match tomorrow's selection
            let components = calendar.dateComponents([.hour, .minute], from: tomorrowDate)
            let hour24 = components.hour ?? 10
            let minute = components.minute ?? 45
            
            selectedHour = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24)
            selectedMinute = minute
            isAM = hour24 < 12
        }
        
        selectedDate = finalDate
        viewModel.selectedDate = finalDate
    }
    
    private func initializeDateAndTime() {
        let calendar = Calendar.current
        let now = Date()
        
        // Initialize today's date
        let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
        var todayComponents = calendar.dateComponents([.year, .month, .day], from: now)
        todayComponents.hour = hour24
        todayComponents.minute = selectedMinute
        
        if let initialDate = calendar.date(from: todayComponents) {
            selectedDate = initialDate
            viewModel.selectedDate = initialDate
        }
        
        // Initialize tomorrow's date (default to 10:45 PM)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        var tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        tomorrowComponents.hour = 22 // 10 PM in 24-hour format
        tomorrowComponents.minute = 45
        
        if let tomorrowInitialDate = calendar.date(from: tomorrowComponents) {
            tomorrowDate = tomorrowInitialDate
        }
        
        // Set initial duration in view model
        viewModel.selectedDuration = selectedDuration
        
        // Set initial title if not empty
        if !activityTitle.isEmpty {
            viewModel.activity.title = activityTitle
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
        }
    )
    .environmentObject(appCache)
} 
