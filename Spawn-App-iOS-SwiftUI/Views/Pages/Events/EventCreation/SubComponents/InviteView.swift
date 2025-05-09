//
//  InviteView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 2025-02-02.
//

import SwiftUI

struct InviteView: View {
	let user: BaseUserDTO
	@Environment(\.dismiss) private var dismiss
	@ObservedObject var eventCreationViewModel = EventCreationViewModel.shared
	@State private var searchText = ""

	init(user: BaseUserDTO) {
		self.user = user
	}

	var body: some View {
		NavigationStack {
			VStack(spacing: 0) {
				// Header
				Text("Invite tags and friends!")
					.font(.headline)
					.padding(.top, 30)
				
				// Tags section
				ScrollView {
					VStack(spacing: 20) {
						// Floating tags - these should be dynamically rendered tags
						tagsCloudView
						
						// Invited section
						if !eventCreationViewModel.selectedFriends.isEmpty {
							invitedFriendsSection
						}
						
						// Suggested friends section
						suggestedFriendsSection
					}
					.padding(.horizontal)
				}
				
				// Search bar at bottom
				VStack {
					// Search bar
					HStack {
						Image(systemName: "magnifyingglass")
							.foregroundColor(.gray)
						TextField("Search", text: $searchText)
					}
					.padding()
					.background(Color(.systemGray6))
					.cornerRadius(10)
					.padding(.horizontal)
					.padding(.top)
					
					// Done button
					Button(action: {
						dismiss()
					}) {
						Text("Done Inviting (\(eventCreationViewModel.selectedFriends.count) friends, \(eventCreationViewModel.selectedTags.count) tags)")
							.font(.headline)
							.foregroundColor(.white)
							.frame(maxWidth: .infinity)
							.padding()
							.background(Color.blue)
							.cornerRadius(25)
							.padding(.horizontal)
							.padding(.bottom, 15)
					}
				}
				.background(Color(.systemBackground))
			}
			.background(universalBackgroundColor)
			.navigationBarBackButtonHidden(true)
			.navigationBarItems(leading: Button(action: {
				dismiss()
			}) {
				Image(systemName: "chevron.left")
					.foregroundColor(.black)
			})
		}
	}
	
	// Tag cloud with floating arrangement
	var tagsCloudView: some View {
		VStack(alignment: .leading) {
			Text("Party People")
				.font(.headline)
				.foregroundColor(.pink)
				.padding(.vertical, 8)
				.padding(.horizontal, 15)
				.background(
					Capsule()
						.stroke(Color.pink, style: StrokeStyle(lineWidth: 1, dash: [5]))
				)
				.padding(.horizontal, 10)
				.onTapGesture {
					// Toggle selection of this tag
				}
			
			HStack {
				Spacer()
				
				Text("Basketball")
					.foregroundColor(.orange)
					.padding(.vertical, 8)
					.padding(.horizontal, 15)
					.background(
						Capsule()
							.stroke(Color.orange, style: StrokeStyle(lineWidth: 1, dash: [5]))
					)
					.onTapGesture {
						// Toggle selection of this tag
					}
				
				Spacer()
				
				Text("Run Club")
					.foregroundColor(.blue)
					.padding(.vertical, 8)
					.padding(.horizontal, 15)
					.background(
						Capsule()
							.stroke(Color.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))
					)
					.onTapGesture {
						// Toggle selection of this tag
					}
				
				Spacer()
			}
			
			HStack {
				Spacer()
				
				Text("Close Friends")
					.foregroundColor(.white)
					.padding(.vertical, 8)
					.padding(.horizontal, 15)
					.background(
						Capsule()
							.fill(Color.green)
					)
					.overlay(
						HStack {
							Spacer()
							Image(systemName: "xmark")
								.font(.caption)
								.foregroundColor(.white)
						}
						.padding(.trailing, 5)
					)
					.onTapGesture {
						// Deselect this tag
					}
				
				Spacer()
				
				Text("Big Nerds")
					.foregroundColor(.green)
					.padding(.vertical, 8)
					.padding(.horizontal, 15)
					.background(
						Capsule()
							.stroke(Color.green, style: StrokeStyle(lineWidth: 1, dash: [5]))
					)
					.onTapGesture {
						// Toggle selection of this tag
					}
				
				Spacer()
			}
		}
		.padding()
	}
	
	// Invited friends section
	var invitedFriendsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Invited")
				.font(.headline)
				.foregroundColor(.primary)
				.padding(.leading, 10)
			
			ScrollView(.horizontal, showsIndicators: false) {
				HStack(spacing: 15) {
					ForEach(eventCreationViewModel.selectedFriends) { friend in
						VStack {
							if let profilePicUrl = friend.profilePicture {
								AsyncImage(url: URL(string: profilePicUrl)) { image in
									image
										.resizable()
										.scaledToFill()
										.frame(width: 60, height: 60)
										.clipShape(Circle())
								} placeholder: {
									Circle()
										.fill(Color.gray)
										.frame(width: 60, height: 60)
								}
							} else {
								Circle()
									.fill(Color.gray)
									.frame(width: 60, height: 60)
							}
							
							Text("First Last")
								.font(.caption)
								.lineLimit(1)
						}
					}
				}
				.padding(.horizontal, 10)
			}
		}
	}
	
	// Suggested friends section
	var suggestedFriendsSection: some View {
		VStack(alignment: .leading, spacing: 10) {
			Text("Suggested")
				.font(.headline)
				.foregroundColor(.primary)
				.padding(.leading, 10)
			
			VStack(spacing: 15) {
				// Mock suggested friends, these should come from a model
				suggestedFriendRow
				suggestedFriendRow
				suggestedFriendRow
			}
		}
	}
	
	// Mock suggested friend row
	var suggestedFriendRow: some View {
		HStack {
			Image(systemName: "person.circle.fill")
				.resizable()
				.frame(width: 50, height: 50)
				.foregroundColor(.gray)
			
			VStack(alignment: .leading) {
				Text("First Last")
					.font(.headline)
				Text("@example_user")
					.font(.subheadline)
					.foregroundColor(.gray)
			}
			
			Spacer()
			
			Button(action: {
				// Add this friend to selected
			}) {
				Image(systemName: "plus.circle.fill")
					.resizable()
					.frame(width: 30, height: 30)
					.foregroundColor(.green)
			}
		}
		.padding(.horizontal)
	}
}

@available(iOS 17.0, *)
#Preview {
	@Previewable @StateObject var appCache = AppCache.shared
	InviteView(user: .danielAgapov).environmentObject(appCache)
}
