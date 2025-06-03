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
    @State private var selectedDay: DayOption = .today
    
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
                    // Compact Time Display Section
                    VStack(spacing: 16) {
                        // Compact time picker - inline with Today/Tomorrow
                        HStack(spacing: 30) {
                            // Hour column
                            VStack(spacing: 4) {
                                Button(action: { selectedHour = 6 }) {
                                    Text("6")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedHour == 6 ? .black : Color.gray.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { selectedHour = 7 }) {
                                    Text("7")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedHour == 7 ? .black : Color.gray.opacity(0.5))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { selectedHour = 8 }) {
                                    Text("8")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedHour == 8 ? .black : Color.gray.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text("\(selectedHour)")
                                    .font(.system(size: 32, weight: .regular))
                                    .foregroundColor(.black)
                                
                                Button(action: { selectedHour = 10 }) {
                                    Text("10")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedHour == 10 ? .black : Color.gray.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { selectedHour = 11 }) {
                                    Text("11")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedHour == 11 ? .black : Color.gray.opacity(0.5))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Minute column
                            VStack(spacing: 4) {
                                Button(action: { selectedMinute = 0 }) {
                                    Text("00")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedMinute == 0 ? .black : Color.gray.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { selectedMinute = 15 }) {
                                    Text("15")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedMinute == 15 ? .black : Color.gray.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(String(format: "%02d", selectedMinute))
                                    .font(.system(size: 32, weight: .regular))
                                    .foregroundColor(.black)
                                
                                Button(action: { selectedMinute = 45 }) {
                                    Text("45")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(selectedMinute == 45 ? .black : Color.gray.opacity(0.7))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // AM/PM column
                            VStack(spacing: 4) {
                                Button(action: { isAM = true }) {
                                    Text("AM")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(isAM ? .black : Color.gray.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { isAM = false }) {
                                    Text("PM")
                                        .font(.system(size: 24, weight: .light))
                                        .foregroundColor(!isAM ? .black : Color.gray.opacity(0.3))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(height: 160) // Reduced from 280 to 160
                        
                        // Today/Tomorrow section - moved to be inline and more compact
                        HStack(spacing: 40) {
                            ForEach(DayOption.allCases, id: \.self) { day in
                                Button(action: { selectedDay = day }) {
                                    Text(day.title)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(selectedDay == day ? .black : Color.gray.opacity(0.5))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Title Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.gray)
                            Spacer()
                        }
                        
                        TextField("Enter Activity Title", text: $activityTitle)
                            .font(.system(size: 16))
                            .foregroundColor(.black)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                    )
                            )
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
                                Button(action: { selectedDuration = duration }) {
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
                Button(action: onNext) {
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
