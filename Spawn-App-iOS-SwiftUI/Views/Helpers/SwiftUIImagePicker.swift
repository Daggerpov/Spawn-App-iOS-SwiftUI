//
//  SwiftUIImagePicker.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by AI Assistant on 2024-05-08.
//

import SwiftUI
import PhotosUI

struct SwiftUIImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var isCropping: Bool = false
    @State private var isPresentingPhotoPicker: Bool = true
    
    var body: some View {
        ZStack {
            // Background color when no image is selected
            if originalImage == nil {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
            }
            
            if let originalImage {
                if isCropping {
                    // Cropping interface
                    ImageCropperView(
                        image: originalImage,
                        onCrop: { croppedImage in
                            if let croppedImage = croppedImage {
                                let finalImage = resizeImageIfNeeded(croppedImage)
                                selectedImage = finalImage
                            }
                            dismiss()
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                } else {
                    // Preview of selected image before cropping
                    VStack {
                        Spacer()
                        
                        Image(uiImage: originalImage)
                            .resizable()
                            .scaledToFit()
                            .padding()
                        
                        Spacer()
                        
                        HStack(spacing: 20) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .padding()
                            .frame(minWidth: 100)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(10)
                            
                            Button("Crop") {
                                isCropping = true
                            }
                            .padding()
                            .frame(minWidth: 100)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .padding(.bottom, 20)
                    }
                    .background(Color.black.opacity(0.8))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .photosPicker(isPresented: $isPresentingPhotoPicker, selection: $photosPickerItem, matching: .images)
        .onChange(of: photosPickerItem) { newItem in
            if newItem != nil {
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            self.originalImage = image
                            self.isPresentingPhotoPicker = false
                        }
                    } else {
                        // If loading fails, dismiss the picker
                        await MainActor.run {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // Helper method to resize large images
    private func resizeImageIfNeeded(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1000.0 // Set a reasonable max size
        
        // Check if image needs resizing
        if image.size.width > maxDimension || image.size.height > maxDimension {
            print("🔍 Resizing image from \(image.size) to max dimension \(maxDimension)")
            let scale = maxDimension / max(image.size.width, image.size.height)
            let newWidth = image.size.width * scale
            let newHeight = image.size.height * scale
            let newSize = CGSize(width: newWidth, height: newHeight)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            
            print("🔍 Resized image to \(resizedImage.size)")
            return resizedImage
        }
        
        return image
    }
}

// Custom crop view for circular profile picture
struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack {
                    // Title
                    Text("Move and Scale")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top)
                    
                    // Image cropper area
                    ZStack {
                        // The image to crop
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                    }
                            )
                        
                        // Circular mask overlay
                        CircleMaskView(size: min(geometry.size.width, geometry.size.height) * 0.8)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                    
                    Spacer()
                    
                    // Buttons
                    HStack {
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        Button("Choose") {
                            let cropSize = min(geometry.size.width, geometry.size.height) * 0.8
                            let renderer = ImageRenderer(content: 
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(scale)
                                    .offset(offset)
                                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                                    .clipShape(Circle())
                                    .frame(width: cropSize, height: cropSize)
                            )
                            
                            if let uiImage = renderer.uiImage {
                                onCrop(uiImage)
                            } else {
                                onCrop(nil)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct CircleMaskView: View {
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .mask(
                    ZStack {
                        Rectangle()
                        Circle()
                            .frame(width: size, height: size)
                            .blendMode(.destinationOut)
                    }
                )
            
            // Circle outline
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: size, height: size)
        }
    }
}

@available(iOS 17, *)
#Preview {
    @Previewable @State var image: UIImage? = nil
    return SwiftUIImagePicker(selectedImage: $image)
} 
