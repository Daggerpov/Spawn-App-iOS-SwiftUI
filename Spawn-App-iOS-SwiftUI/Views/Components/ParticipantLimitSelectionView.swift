//
//  ParticipantLimitSelectionView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-01.
//

import SwiftUI

struct ParticipantLimitSelectionView: View {
    @Binding var selectedLimit: Int?
    @State private var customLimit: String = ""
    @State private var showCustomInput: Bool = false
    
    let presetOptions = [
        (label: "Any amount!", value: nil as Int?),
        (label: "10", value: 10),
        (label: "50", value: 50)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How many people can come?")
                .font(.onestSemiBold(size: 16))
                .lineSpacing(19.20)
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                // Preset options
                ForEach(0..<presetOptions.count, id: \.self) { index in
                    let option = presetOptions[index]
                    let isSelected = (option.value == selectedLimit) || 
                                   (option.value == nil && selectedLimit == nil)
                    
                    Button(action: {
                        selectedLimit = option.value
                        showCustomInput = false
                        customLimit = ""
                    }) {
                        HStack(spacing: 15) {
                            Text(option.label)
                                .font(.onestMedium(size: 16))
                                .lineSpacing(19.20)
                                .foregroundColor(isSelected ? Color(red: 0.42, green: 0.51, blue: 0.98) : Color(red: 0.52, green: 0.49, blue: 0.49))
                        }
                        .padding(12)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: isSelected ? 1 : 0.5)
                                .stroke(
                                    isSelected ? Color(red: 0.42, green: 0.51, blue: 0.98) : Color(red: 0.52, green: 0.49, blue: 0.49),
                                    lineWidth: isSelected ? 1 : 0.5
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Custom option
                Button(action: {
                    showCustomInput = true
                }) {
                    HStack(spacing: 15) {
                        Text("Custom")
                            .font(.onestMedium(size: 16))
                            .lineSpacing(19.20)
                            .foregroundColor(showCustomInput ? Color(red: 0.42, green: 0.51, blue: 0.98) : Color(red: 0.52, green: 0.49, blue: 0.49))
                    }
                    .padding(12)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .inset(by: showCustomInput ? 1 : 0.5)
                            .stroke(
                                showCustomInput ? Color(red: 0.42, green: 0.51, blue: 0.98) : Color(red: 0.52, green: 0.49, blue: 0.49),
                                lineWidth: showCustomInput ? 1 : 0.5
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Custom input field
            if showCustomInput {
                TextField("Enter number", text: $customLimit)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: customLimit, perform: { newValue in
                        if let number = Int(newValue), number > 0 {
                            selectedLimit = number
                        } else if newValue.isEmpty {
                            selectedLimit = nil
                        }
                    })
                    .padding(.horizontal)
            }
        }
        .frame(width: 354)
    }
}

#Preview {
    @State var selectedLimit: Int? = nil
    return ParticipantLimitSelectionView(selectedLimit: $selectedLimit)
        .background(Color.black)
} 
