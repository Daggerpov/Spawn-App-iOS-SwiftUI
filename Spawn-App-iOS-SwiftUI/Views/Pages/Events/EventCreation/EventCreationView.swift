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
    @State private var showInviteView: Bool = false
    
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
                    .foregroundColor(universalAccentColor)
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
                        
                        ScrollView(.horizontal, showsIndicators: false) {
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
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Who's Invited
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who's Invited?*")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            showInviteView = true
                        }) {
                            HStack {
                                // Profile pictures and count
                                HStack(spacing: -10) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Circle().fill(Color.black))
                                    Text("20")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.leading, 5)
                                        .padding(.trailing, 10)
                                        .padding(.vertical, 5)
                                        .background(Capsule().fill(Color.black))
                                }
                                
                                Button(action: {
                                    showInviteView = true
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
                                
                                Spacer()
                                
                                Button(action: {
                                    showInviteView = true
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
                    }
                    
                    // Location
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Location*")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            if !viewModel.isLocationValid {
                                HStack {
                                    Image(
                                        systemName:
                                            "exclamationmark.circle.fill"
                                    )
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                    Text("Location is required")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.horizontal, 5)
                                        .transition(.opacity)
                                }
                            }
                        }

                        HStack {
                            TextField("Select a location", text: Binding(
                                get: {
                                    viewModel.event.location?.name ?? ""
                                },
                                set: { newValue in
                                    if viewModel.event.location == nil {
                                        viewModel.event.location =
                                            Location(
                                                id: UUID(),
                                                name: newValue,
                                                latitude: 0,
                                                longitude: 0
                                            )
                                    } else {
                                        viewModel.event.location?.name = newValue
                                    }
                                }
                            ))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )

                            NavigationLink(destination: {
                                LocationSelectionView()
                                    .environmentObject(viewModel)
                            }) {
                                Image(systemName: "map")
                                    .foregroundColor(universalSecondaryColor)
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(Color.black, lineWidth: 1.5)
                                    )
                            }
                        }
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
        .sheet(isPresented: $showInviteView) {
            InviteView(user: creatingUser)
        }
        .background(universalBackgroundColor)
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

@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    EventCreationView(
        creatingUser: .danielAgapov,
        closeCallback: {
        }
    ).environmentObject(appCache)
}
