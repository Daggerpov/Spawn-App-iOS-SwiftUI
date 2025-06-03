import SwiftUI

struct ActivityDateTimeView: View {
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    @Binding var isAM: Bool
    @Binding var activityTitle: String
    @Binding var selectedDuration: ActivityDuration
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    Text("Title")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    // Title Input
                    TextField("Enter Activity Title", text: $activityTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    // Activity Duration
                    Text("Activity Duration")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    // Duration Selection
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
                    
                    // Time Selection
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Today")
                            .font(.system(size: 32, weight: .bold))
                            .padding(.horizontal)
                        
                        HStack(spacing: 0) {
                            // Hour Picker
                            Picker("Hour", selection: $selectedHour) {
                                ForEach(1...12, id: \.self) { hour in
                                    Text("\(hour)")
                                        .font(.system(size: 32, weight: .bold))
                                        .tag(hour)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            
                            Text(":")
                                .font(.system(size: 32, weight: .bold))
                            
                            // Minute Picker
                            Picker("Minute", selection: $selectedMinute) {
                                ForEach(0...59, id: \.self) { minute in
                                    Text(String(format: "%02d", minute))
                                        .font(.system(size: 32, weight: .bold))
                                        .tag(minute)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                            
                            // AM/PM Picker
                            Picker("AM/PM", selection: $isAM) {
                                Text("AM").tag(true)
                                Text("PM").tag(false)
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 60)
                        }
                        .padding(.horizontal)
                        
                        Text("Tomorrow")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Next Step Button
            Button(action: onNext) {
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
        .background(universalBackgroundColor)
    }
} 