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

    var creatingUser: BaseUserDTO
    var closeCallback: () -> Void

    init(creatingUser: BaseUserDTO, closeCallback: @escaping () -> Void) {
        self.creatingUser = creatingUser
        self.closeCallback = closeCallback
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Make an event")
                    .fontWeight(.bold)
                    .font(.title)
                    .foregroundColor(universalAccentColor)
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        EventInputFieldLabel(text: "Name")

                        if !viewModel.isTitleValid {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                Text("Event name is required")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 5)
                                    .transition(.opacity)
                            }
                        }
                    }

                    EventInputField(
                        value: $viewModel.event.title,
                        isValid: viewModel.isTitleValid
                    )

                }
                .padding(.bottom, 8)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        EventInputFieldLabel(text: "Invite Friends")

                        if !viewModel.isInvitesValid {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 5)
                                    .transition(.opacity)
                            }
                        }
                    }

                    HStack {
                        selectedFriendsView
                        Spacer()
                        selectedTagsView
                    }
                }
                .padding(.bottom, 8)

                HStack(spacing: 16) {
//                    Spacer()
                    // Date field
                    datePickerView
                    Spacer()

                    // Time field
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Time")
                                .font(Font.custom("Poppins", size: 16))
                                .kerning(1)
                                .foregroundColor(universalAccentColor)
                                .bold()
                        }

                        ZStack{
                            HStack(spacing: 10) {
                                startTimeView
                                    .font(Font.custom("Poppins", size: 16))
                                    .kerning(1)
                                    .foregroundColor(universalAccentColor)
                                    .bold()
                                Spacer()
                                endTimeView
                            }
                            Text("—")
                                .font(Font.custom("Poppins", size: 16))
                                .kerning(1)
                                .foregroundColor(universalAccentColor)
                                .bold()
                                .padding(.trailing, 8)
                        }
                    }
                }
                .padding(.bottom, 12)

                EventInputFieldLabel(text: "Location")
                EventInputField(
                    iconName: "mappin.and.ellipse",
                    value: Binding(
                        get: { viewModel.event.location?.name ?? "" },
                        set: { newValue in
                            if let unwrappedNewValue = newValue {
                                if viewModel.event.location == nil {
                                    viewModel.event.location = Location(
                                        id: UUID(),
                                        name: unwrappedNewValue,
                                        latitude: 0,
                                        longitude: 0
                                    )
                                } else {
                                    viewModel.event.location?.name =
                                        unwrappedNewValue
                                }
                            }
                        }
                    ),
                    isValid: true
                )
                .padding(.bottom, 8)

                EventInputFieldLabel(text: "Caption")
                EventInputField(value: $viewModel.event.note, isValid: true)
                    .padding(.bottom, 16)

                // Error message display
                if !viewModel.creationMessage.isEmpty {
                    Text(viewModel.creationMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    viewModel.validateEventForm()
                    if viewModel.isFormValid {
                        Task {
                            await viewModel.createEvent()
                        }
                        closeCallback()
                    }
                }) {
                    EventSubmitButtonView(
                        backgroundColor: viewModel.isFormValid
                            ? universalSecondaryColor : Color.gray
                    )
                }
                .disabled(!viewModel.isFormValid)
                .onChange(of: viewModel.event.title) { _ in
                    viewModel.validateEventForm()
                }
                .onChange(of: viewModel.selectedFriends) { _ in
                    viewModel.validateEventForm()
                }
                .onChange(of: viewModel.selectedTags) { _ in
                    viewModel.validateEventForm()
                }
                .padding(.top, 24)  // Increased padding
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 24)  // Added vertical padding
            .background(universalBackgroundColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .scrollIndicators(.hidden)  // Hide scroll indicators
        .background(universalBackgroundColor)
        .onAppear {
            viewModel.validateEventForm()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct EventInputFieldLabel: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Font.custom("Poppins", size: 16))
            .kerning(1)
            .foregroundColor(universalAccentColor)
            .bold()
    }
}

struct EventInputField: View {
    var iconName: String?
    @Binding var value: String?
    var isValid: Bool = true

    var body: some View {
        HStack {
            if let icon = iconName {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
            TextField(
                "",
                text: Binding(
                    get: { value ?? "" },
                    set: { newValue in
                        // Safely update the value outside of the view update
                        DispatchQueue.main.async {
                            value = newValue.isEmpty ? nil : newValue
                        }
                    }
                )
            )
        }
        .foregroundColor(universalAccentColor)
        .padding()
        .background(
            Rectangle()
                .foregroundColor(.clear)
                .frame(maxWidth: .infinity, minHeight: 46, maxHeight: 46)
                .cornerRadius(15)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .inset(by: 0.75)
                        .stroke(isValid ? .black : .red, lineWidth: 1.5)
                )
        )
    }
}

extension EventCreationView {
    var startTimeView: some View {
        // Start time
        DatePicker(
            "",
            selection: Binding(
                get: {
                    viewModel.event.startTime
                    ?? viewModel.combineDateAndTime(
                        viewModel.selectedDate,
                        time: Date()
                    )
                },
                set: { time in
                    viewModel.event.startTime =
                    viewModel.combineDateAndTime(
                        viewModel.selectedDate,
                        time: time
                    )
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.black, lineWidth: 1.5)
            )
        .labelsHidden()
    }
    
    var endTimeView: some View {
        // End time
        DatePicker(
            "",
            selection: Binding(
                get: {
                    viewModel.event.endTime
                        ?? viewModel.combineDateAndTime(
                            viewModel.selectedDate,
                            time: Date().addingTimeInterval(
                                2 * 60 * 60
                            )
                        )
                },
                set: { time in
                    viewModel.event.endTime =
                        viewModel.combineDateAndTime(
                            viewModel.selectedDate,
                            time: time
                        )
                }
            ),
            displayedComponents: .hourAndMinute
        )
        .frame(height: 42)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .labelsHidden()
    }
    var datePickerView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Date")
                    .font(Font.custom("Poppins", size: 16))
                    .kerning(1)
                    .foregroundColor(universalAccentColor)
                    .bold()
            }

            Button(action: { showFullDatePicker = true }) {
                HStack {
                    Text(
                        Calendar.current.isDateInToday(
                            viewModel.selectedDate
                        )
                            ? "Today"
                            : viewModel.formatDate(
                                viewModel.selectedDate
                            )
                    )
                    .foregroundColor(universalAccentColor)
                    Image(systemName: "calendar")
                        .foregroundColor(universalAccentColor)
                }
                .padding()
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black, lineWidth: 1.5)
                )
            }
            .sheet(isPresented: $showFullDatePicker) {
                fullDatePickerView
            }
        }
    }
    var selectedFriendsView: some View {
        HStack {
            ForEach(viewModel.selectedFriends) { friend in
                if let pfpUrl = friend.profilePicture {
                    AsyncImage(url: URL(string: pfpUrl)) {
                        image in
                        image
                            .ProfileImageModifier(imageType: .eventParticipants)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 25, height: 25)
                    }
                } else {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 25, height: 25)
                }
            }
            NavigationLink(destination: {
                InviteView(user: creatingUser)
                    .environmentObject(viewModel)
            }) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                    Circle()
                        .stroke(
                            .secondary,
                            style: StrokeStyle(
                                lineWidth: 2,
                                dash: [5, 3]  // Length of dash and gap
                            )
                        )
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .frame(width: 30, height: 30)
            }
            .padding(.leading, 12)
        }
    }

    var selectedTagsView: some View {
        HStack {
            let displayedTags = viewModel.selectedTags
                .prefix(2)
            let remainingCount =
                viewModel.selectedTags.count
                - displayedTags.count

            ForEach(displayedTags) { tag in
                Text(tag.displayName)
                    .font(
                        .system(size: 14, weight: .medium)
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Color(hex: tag.colorHexCode)
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            if remainingCount > 0 {
                Text("+\(remainingCount) more")
                    .font(
                        .system(size: 14, weight: .medium)
                    )
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(universalAccentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
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
            .foregroundColor(Color(.systemGray6))
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
