//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI

struct EventCreationView: View {
    @ObservedObject var viewModel: EventCreationViewModel =
    EventCreationViewModel.shared
    
    @State private var showFullDatePicker: Bool = false  // Toggles the pop-out calendar
    @State private var selectedCategory: EventCategory = .general
    
    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void
    
    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with close button
            Spacer()
            HStack {
                Text("Create a Spawn")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    closeCallback()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Icon & Event Title
                    HStack () {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Icon*")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Circle()
                                .fill(Color.yellow.opacity(0.2))
                                .frame(width: 45, height: 45)
                                .overlay(
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                )
                        }
                        
                        // Title Field
                        VStack(alignment: .leading) {
                            Text("Event Title*")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            TextField("Title", text: Binding(
                                get: { viewModel.event.title ?? "" },
                                set: { viewModel.event.title = $0 }
                            ))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    
                    
                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: { showFullDatePicker = true }) {
                            HStack {
                                Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Today" : viewModel.formatDate(viewModel.selectedDate))
                                    .foregroundColor(.black)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(.black)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            // Start time
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        viewModel.event.startTime ?? viewModel.combineDateAndTime(viewModel.selectedDate, time: Date())
                                    },
                                    set: { time in
                                        viewModel.event.startTime = viewModel.combineDateAndTime(viewModel.selectedDate, time: time)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                            
                            Text("-")
                                .font(.headline)
                                .padding(.horizontal, 4)
                            
                            // End time
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: {
                                        viewModel.event.endTime ?? viewModel.combineDateAndTime(viewModel.selectedDate, time: Date().addingTimeInterval(2 * 60 * 60))
                                    },
                                    set: { time in
                                        viewModel.event.endTime = viewModel.combineDateAndTime(viewModel.selectedDate, time: time)
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 8) {
                            ForEach(EventCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category.rawValue)
                                        .font(.subheadline)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .foregroundColor(selectedCategory == category ? .white : .black)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(selectedCategory == category ?
                                                      category.color : Color.gray.opacity(0.15))
                                        )
                                }
                            }
                        }
                    }
                    
                    // Who's Invited
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who's Invited?*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.white)
                                Text("20")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black)
                            .clipShape(Capsule())
                            
                            Button(action: {
                                // Show invite view
                            }) {
                                HStack {
                                    Text("Close Friends")
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.green)
                                .clipShape(Capsule())
                            }
                            
                            Button(action: {
                                // Navigate to invite view
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                        .font(.caption)
                                    Text("Add more!")
                                        .font(.subheadline)
                                }
                                .foregroundColor(.gray)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                )
                            }
                        }
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AMS Student Nest")
                                    .font(.subheadline)
                                Text("6133 University Blvd, Vancouver, BC V6T 1Z1")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            Text("12km")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Come join us for this fun event!", text: Binding(
                            get: { viewModel.event.note ?? "" },
                            set: { viewModel.event.note = $0 }
                        ))
                        .padding()
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    // Create Button
                    Button(action: {
                        Task {
                            await viewModel.validateEventForm()
                            await viewModel.createEvent()
                            closeCallback()
                        }
                    }) {
                        HStack {
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(.white)
                            Text("Create!")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(30)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showFullDatePicker) {
            fullDatePickerView
        }
    }
    
    var fullDatePickerView: some View {
        VStack {
            Text("Select a Date")
                .font(.headline)
                .padding()
            DatePicker(
                "Select Date",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .labelsHidden()
            .padding()
            
            Button("Done") {
                showFullDatePicker = false
            }
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(Color.blue)
            .cornerRadius(10)
            .padding()
        }
        .presentationDetents([.medium])
    }
}

enum EventCategory: String, CaseIterable {
    case general = "General"
    case foodAndDrink = "Food & Drink"
    case active = "Active"
    case study = "Study"
    
    var color: Color {
        switch self {
        case .general:
            return Color.red
        case .foodAndDrink:
            return Color.gray
        case .active:
            return Color.gray
        case .study:
            return Color.gray
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    EventCreationView(
        creatingUser: .danielAgapov,
        closeCallback: {
        }
    ).environmentObject(appCache)
}
