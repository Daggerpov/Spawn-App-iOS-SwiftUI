import SwiftUI

struct ActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    
    // Time picker state
    @State private var selectedDay: Int = 0 // 0 = Today, 1 = Tomorrow
    @State private var todayHour: Int = 9
    @State private var todayMinute: Int = 30
    @State private var todayIsAM: Bool = true
    @State private var tomorrowHour: Int = 10
    @State private var tomorrowMinute: Int = 45
    @State private var tomorrowIsAM: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Picker Section
                    VStack(spacing: 0) {
                        // Number columns
                        HStack(spacing: 0) {
                            Spacer()
                            
                            // Hour column
                            VStack(spacing: 8) {
                                ForEach([6, 7, 8, 9, 10, 11, 12], id: \.self) { hour in
                                    Text("\(hour)")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(
                                            (selectedDay == 0 && todayHour == hour) || 
                                            (selectedDay == 1 && tomorrowHour == hour) 
                                            ? universalAccentColor : figmaBlack300
                                        )
                                        .onTapGesture {
                                            if selectedDay == 0 {
                                                todayHour = hour
                                                selectedHour = hour
                                            } else {
                                                tomorrowHour = hour
                                            }
                                        }
                                }
                            }
                            
                            Spacer()
                            
                            // Minute column
                            VStack(spacing: 8) {
                                ForEach([0, 15, 30, 45], id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(
                                            (selectedDay == 0 && todayMinute == minute) || 
                                            (selectedDay == 1 && tomorrowMinute == minute) 
                                            ? universalAccentColor : figmaBlack300
                                        )
                                        .onTapGesture {
                                            if selectedDay == 0 {
                                                todayMinute = minute
                                                selectedMinute = minute
                                            } else {
                                                tomorrowMinute = minute
                                            }
                                        }
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 20)
                        
                        // Day selection with time display
                        VStack(spacing: 12) {
                            // Today row
                            HStack {
                                Button(action: {
                                    selectedDay = 0
                                    selectedHour = todayHour
                                    selectedMinute = todayMinute
                                    isAM = todayIsAM
                                }) {
                                    HStack {
                                        Text("Today")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 0 ? universalAccentColor : figmaBlack300)
                                        
                                        Spacer()
                                        
                                        Text("\(todayHour)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 0 ? universalAccentColor : figmaBlack300)
                                        
                                        Text(String(format: "%02d", todayMinute))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 0 ? universalAccentColor : figmaBlack300)
                                        
                                        Text(todayIsAM ? "AM" : "PM")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 0 ? universalAccentColor : figmaBlack300)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDay == 0 ? universalPassiveColor.opacity(0.3) : Color.clear)
                            )
                            
                            // Tomorrow row
                            HStack {
                                Button(action: {
                                    selectedDay = 1
                                    selectedHour = tomorrowHour
                                    selectedMinute = tomorrowMinute
                                    isAM = tomorrowIsAM
                                }) {
                                    HStack {
                                        Text("Tomorrow")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 1 ? universalAccentColor : figmaBlack300)
                                        
                                        Spacer()
                                        
                                        Text("\(tomorrowHour)")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 1 ? universalAccentColor : figmaBlack300)
                                        
                                        Text(String(format: "%02d", tomorrowMinute))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 1 ? universalAccentColor : figmaBlack300)
                                        
                                        Text(tomorrowIsAM ? "AM" : "PM")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(selectedDay == 1 ? universalAccentColor : figmaBlack300)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedDay == 1 ? universalPassiveColor.opacity(0.3) : Color.clear)
                            )
                        }
                        .padding(.horizontal, 20)
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
                        
                        // Duration buttons
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
            // Initialize with today's selection
            selectedHour = todayHour
            selectedMinute = todayMinute
            isAM = todayIsAM
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