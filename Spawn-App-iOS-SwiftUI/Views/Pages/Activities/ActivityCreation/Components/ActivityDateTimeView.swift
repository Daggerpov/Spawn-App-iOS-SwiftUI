import SwiftUI

struct ActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    
    // Native date picker state
    @State private var selectedDate: Date = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Native Time Picker Section
                    VStack(spacing: 16) {
                        DatePicker(
                            "",
                            selection: $selectedDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .padding(.horizontal, 20)
                        .onChange(of: selectedDate) { newValue in
                            let calendar = Calendar.current
                            let hour = calendar.component(.hour, from: newValue)
                            let minute = calendar.component(.minute, from: newValue)
                            
                            // Convert to 12-hour format
                            if hour == 0 {
                                selectedHour = 12
                                isAM = true
                            } else if hour < 12 {
                                selectedHour = hour
                                isAM = true
                            } else if hour == 12 {
                                selectedHour = 12
                                isAM = false
                            } else {
                                selectedHour = hour - 12
                                isAM = false
                            }
                            
                            selectedMinute = minute
                        }
                    }
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(figmaBlack300)
                            Spacer()
                        }
                        
                        TextField("Enter Activity Title", text: $activityTitle)
                            .font(.system(size: 16))
                            .foregroundColor(universalAccentColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(universalPassiveColor, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 20)
                    
                    // Activity Duration Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Activity Duration")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(figmaBlack300)
                            Spacer()
                        }
                        
                        // Duration buttons - horizontal layout
                        HStack(spacing: 8) {
                            ForEach(ActivityDuration.allCases, id: \.self) { duration in
                                Button(action: { selectedDuration = duration }) {
                                    Text(duration.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedDuration == duration ? figmaBlue : universalPassiveColor.opacity(0.3))
                                        )
                                        .foregroundColor(selectedDuration == duration ? .white : figmaBlack300)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            
            // Next Step Button
            VStack {
                Button(action: onNext) {
                    Text("Next Step")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(figmaBlue)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(universalBackgroundColor)
        .onAppear {
            // Initialize selectedDate with current time
            let calendar = Calendar.current
            let now = Date()
            
            // Set the date picker to the current bound values if they exist
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            
            // Convert 12-hour to 24-hour format
            let hour24 = isAM ? (selectedHour == 12 ? 0 : selectedHour) : (selectedHour == 12 ? 12 : selectedHour + 12)
            dateComponents.hour = hour24
            dateComponents.minute = selectedMinute
            
            if let initialDate = calendar.date(from: dateComponents) {
                selectedDate = initialDate
            }
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