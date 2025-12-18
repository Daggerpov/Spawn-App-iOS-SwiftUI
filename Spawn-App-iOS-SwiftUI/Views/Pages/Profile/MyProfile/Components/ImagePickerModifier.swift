//
//  ImagePickerModifier.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Daniel Agapov on 11/9/24.
//
import SwiftUI

struct ImagePickerModifier: ViewModifier {
	@Binding var showImagePicker: Bool
	@Binding var selectedImage: UIImage?
	@Binding var isImageLoading: Bool

	func body(content: Content) -> some View {
		content
			.sheet(isPresented: $showImagePicker) {
				if selectedImage != nil {
					isImageLoading = true
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(0.3))
						isImageLoading = false
					}
				}
			} content: {
				SwiftUIImagePicker(selectedImage: $selectedImage)
					.ignoresSafeArea()
			}
			.onChange(of: selectedImage) { _, newImage in
				if newImage != nil {
					// Force UI update when image changes
					isImageLoading = true
					Task { @MainActor in
						try? await Task.sleep(for: .seconds(0.3))
						isImageLoading = false
					}
				}
			}
	}
}
