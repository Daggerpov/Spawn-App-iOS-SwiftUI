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
                                    if viewModel.selectedFriends.isEmpty {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.gray)
                                                    .font(.system(size: 16))
                                            )
                                    } else {
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
                                                .fill(Color.blue)
                                                .frame(width: 30, height: 30)
                                                .overlay(
                                                    Text("+\(viewModel.selectedFriends.count - 2)")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                        }
                                    }
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
        .sheet(isPresented: $showEmojiPicker) {
            EmojiPickerView { emoji in
                selectedEmoji = emoji
                viewModel.event.icon = emoji
            }
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
            
            Button("Done") {
                showFullDatePicker = false
            }
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(.white)
            .background(universalSecondaryColor)
            .cornerRadius(10)
            .padding()
        }
        .presentationDetents([.medium])
    }
}

// Emoji picker view 
struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onEmojiSelected: (String) -> Void
    
    // Common emoji categories
    let categories = [
        ("Smileys", ["😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇", "🥰", "😍", "🤩", "😘"]),
        ("Animals", ["🐶", "🐱", "🐭", "🐹", "🐰", "🦊", "🐻", "🐼", "🐨", "🐯", "🦁", "🐮", "🐷", "🐸", "🐵"]),
        ("Sports", ["⚽️", "🏀", "🏈", "⚾️", "🥎", "🎾", "🏐", "🏉", "🥏", "🎱", "🏓", "🏸", "🏒", "🏑", "🥍", "🏏", "⛳️", "🥊"]),
        ("Food", ["🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🥑"]),
        ("Places", ["🏠", "🏡", "🏢", "🏣", "🏤", "🏥", "🏦", "🏨", "🏩", "🏪", "🏫", "🏬", "🏭", "🏯", "🏰", "💒", "🗼", "🗽"]),
        ("Objects", ["⌚️", "📱", "💻", "⌨️", "🖥", "🖨", "🖱", "🖲", "🕹", "💽", "💾", "💿", "📀", "📼", "📷", "📸", "📹", "🎥"]),
        ("Symbols", ["❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "💔", "❣️", "💕", "💞", "💓", "💗", "💖", "💘", "💝", "💟"])
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(categories, id: \.0) { category in
                        VStack(alignment: .leading) {
                            Text(category.0)
                                .font(.headline)
                                .padding(.leading)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                                ForEach(category.1, id: \.self) { emoji in
                                    Button(action: {
                                        onEmojiSelected(emoji)
                                        dismiss()
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 30))
                                            .padding(5)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        Divider()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Select Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// This needs to be outside the struct
@available(iOS 17, *)
#Preview {
    @Previewable @StateObject var appCache = AppCache.shared
    EventCreationView(
        creatingUser: .danielAgapov,
        closeCallback: {
        }
    ).environmentObject(appCache)
}
