//
//  EventCreationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-01-02.
//

import SwiftUI
import MCEmojiPicker

struct EventCreationView: View {
    @ObservedObject var viewModel: EventCreationViewModel =
    EventCreationViewModel.shared
    
    @State private var showFullDatePicker: Bool = false  // Toggles the pop-out calendar
    @State private var showInviteView: Bool = false
    @State private var showLocationSelection: Bool = false // Add state for location selection
    @State private var showEmojiPicker: Bool = false // For emoji picker
    @State private var showValidationAlert: Bool = false // For validation alert
    @State private var selectedEmoji: String = "⭐️" // Track selected emoji locally
    
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
                        .foregroundColor(universalAccentColor)
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
                            Button(action: {
                                showEmojiPicker = true
                            }) {
                                Circle()
                                    .fill(Color.yellow.opacity(0.2))
                                    .frame(width: 45, height: 45)
                                    .overlay(
                                        Text(selectedEmoji)
                                            .font(.system(size: 24))
                                    )
                            }
                            .emojiPicker(
                                isPresented: $showEmojiPicker,
                                selectedEmoji: $selectedEmoji,
                                arrowDirection: .up,
                                isDismissAfterChoosing: true,
                                selectedEmojiCategoryTintColor: UIColor(universalAccentColor)
                            )
                            .onChange(of: selectedEmoji) { newEmoji in
                                viewModel.event.icon = newEmoji
                            }
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
                            .foregroundColor(universalAccentColor)
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
                                    .foregroundColor(universalAccentColor)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(universalAccentColor)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        }
                    }
                    
                    timeSelectionView
                    
                    categorySelectionView
                    
                    invitedView
                    
                    locationSelectionView
                    
                    // Caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Come join us for this fun event!", text: Binding(
                            get: { viewModel.event.note ?? "" },
                            set: { viewModel.event.note = $0 }
                        ))
                        .foregroundColor(universalAccentColor)
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
                            if viewModel.isFormValid {
                                await viewModel.createEvent()
                                EventCreationViewModel.reInitialize()
                                closeCallback()
                            } else {
                                showValidationAlert = true
                            }
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
                        .background(universalSecondaryColor)
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
        .sheet(isPresented: $showLocationSelection) {
            LocationSelectionView().environmentObject(viewModel)
        }
        .alert(isPresented: $showValidationAlert) {
            Alert(
                title: Text("Incomplete Form"),
                message: Text("Please fill in all required fields marked with *"),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(universalBackgroundColor)
        .onAppear {
            // Initialize selectedEmoji from viewModel if available
            if let icon = viewModel.event.icon {
                selectedEmoji = icon
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
            .onChange(of: viewModel.selectedDate) { _ in
                showFullDatePicker = false
            }
        }
        .presentationDetents([.medium])
    }
}

extension EventCreationView {
    var categorySelectionView: some View {
        // Category
        VStack(alignment: .leading, spacing: 8) {
            Text("Category*")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Reordering categories to put General last
                    let sortedCategories = EventCategory.allCases.sorted { cat1, cat2 in
                        if cat1 == .general { return false }
                        if cat2 == .general { return true }
                        return cat1.rawValue < cat2.rawValue
                    }
                    
                    ForEach(sortedCategories, id: \.self) { category in
                        Button(action: {
                            if viewModel.selectedCategory == category {
                                // Allow deselecting by clicking on the same category
                                if category != .general {
                                    viewModel.selectedCategory = .general
                                }
                            } else {
                                viewModel.selectedCategory = category
                            }
                        }) {
                            Text(category.rawValue)
                                .font(.subheadline)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .foregroundColor(viewModel.selectedCategory == category ? .white : .black)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(viewModel.selectedCategory == category ?
                                              category.color : Color.gray.opacity(0.15))
                                )
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
    }
    var locationSelectionView: some View {
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
                Button(action: {
                    showLocationSelection = true
                }) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            .frame(height: 44)
                        
                        HStack {
                            Text(viewModel.event.location?.name.isEmpty ?? true
                                 ? "Select location"
                                 : viewModel.event.location?.name ?? "")
                            .foregroundColor(
                                viewModel.event.location?.name.isEmpty ?? true
                                ? .gray
                                : universalAccentColor
                            )
                            .padding(.leading, 10)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .padding(.trailing, 10)
                        }
                    }
                }
                
                Button(action: {
                    showLocationSelection = true
                }) {
                    Image(systemName: "map")
                        .foregroundColor(universalSecondaryColor)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(universalAccentColor, lineWidth: 1.5)
                        )
                }
            }
        }
    }
    var invitedView: some View {
        // Who's Invited
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                Text("Who's Invited?*")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                // Profile pictures and count
                if !viewModel.selectedFriends.isEmpty {
                    HStack(spacing: -10) {
                        // Show first two profile pictures
                        ForEach(0..<min(2, viewModel.selectedFriends.count), id: \.self) { index in
                            let friend = viewModel.selectedFriends[index]
                            if let pfpUrl = friend.profilePicture, let url = URL(string: pfpUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 30, height: 30)
                                        .clipShape(Circle())
                                        .onTapGesture {
                                            viewModel.selectedFriends.remove(at: index)
                                        }
                                } placeholder: {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 30, height: 30)
                                }
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 30, height: 30)
                            }
                        }
                        
                        // Show +X if there are more than 2 friends
                        if viewModel.selectedFriends.count > 2 {
                            Circle()
                                .fill(universalSecondaryColor)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("+\(viewModel.selectedFriends.count - 2)")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        )
                }
            }
            
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags) { tag in
                            Button(action: {
                                showInviteView = true
                            }) {
                                HStack {
                                    Text(tag.displayName)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                    Image(systemName: "xmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(hex: tag.colorHexCode))
                                .clipShape(Capsule())
                            }
                        }
                        
                        if viewModel.selectedTags.isEmpty {
                            // No tags selected yet
                            EmptyView()
                        }
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showInviteView = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add \(viewModel.selectedTags.count > 0 ? "more " : "")tags!")
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
    var timeSelectionView: some View {
        // Time
        VStack(alignment: .leading, spacing: 8) {
            Text("Time*")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            HStack {
                // Start time
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(height: 44)
                    
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
                    .colorScheme(.light)
                    .accentColor(universalAccentColor)
                    .padding(.horizontal, 10)
                }
                
                Text("-")
                    .font(.headline)
                    .padding(.horizontal, 4)
                
                // End time
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(height: 44)
                    
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
                    .colorScheme(.light)
                    .accentColor(universalAccentColor)
                    .padding(.horizontal, 10)
                }
            }
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
