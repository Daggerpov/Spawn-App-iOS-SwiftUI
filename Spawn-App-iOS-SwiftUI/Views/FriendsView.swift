//
//  FriendsView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/24/24.
//

import SwiftUI

struct FriendsView: View {
    var body: some View {
        NavigationView {
            VStack {
                // Top navigation and search bar
                HStack {
                    // Left arrow button
                    Button(action: {
                        // Action for back navigation
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                    // Friends/Tags Toggle
                    Picker(selection: .constant(0), label: Text("")) {
                        Text("friends").tag(0)
                        Text("tags").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                    Spacer()
                }
                .padding()
                
                // Search bar
                HStack {
                    TextField("search or add friends", text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 10)
                        .frame(height: 40)
                    Spacer()
                }
                .padding([.leading, .trailing])
                
                Text("TAGS")
                    .font(.headline)
                    .padding(.top)
                
                // Add Tag Button
                Button(action: {
                    // Action to add a new tag
                }) {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .frame(height: 50)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.black)
                        )
                        .padding(.horizontal)
                }
                
                // Close Friends Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Close Friends")
                            .font(.headline)
                        Spacer()
                        Button(action: {
                            // Edit action
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.black)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Color Options
                    HStack {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index == 4 ? Color.gray.opacity(0.2) : randomColor(index))
                                .frame(width: 30, height: 30)
                                .overlay(index == 4 ? Image(systemName: "plus").foregroundColor(.black) : nil)
                        }
                    }
                    .padding(.horizontal)
                    
                    // List of Friends
                    VStack(spacing: 8) {
                        ForEach(["ethhansen", "gingy05", "username"], id: \.self) { friend in
                            HStack {
                                Circle()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray.opacity(0.2))
                                Text(friend)
                                    .font(.subheadline)
                                Spacer()
                                Button(action: {
                                    // Remove friend action
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.2)))
                .padding(.horizontal)
                
                Spacer()
                
                // Other Tags
                ScrollView {
                    ForEach(0..<3) { index in
                        HStack {
                            Text("Tag Name")
                                .font(.subheadline)
                            Spacer()
                            HStack(spacing: -10) {
                                ForEach(0..<2) { _ in
                                    Circle()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(.gray.opacity(0.2))
                                }
                                Button(action: {
                                    // Add action
                                }) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.black)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(randomColor(index)))
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func randomColor(_ index: Int) -> Color {
        let colors: [Color] = [.purple, .green, .red, .blue, .gray]
        return colors[index % colors.count]
    }
}

struct FriendsView_Previews: PreviewProvider {
    static var previews: some View {
        FriendsView()
    }
}
