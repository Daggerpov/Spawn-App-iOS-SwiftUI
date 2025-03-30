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
            } else {
                // Show crop view directly
                CropView(
                    image: originalImage!,
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

// Simple wrapper view to implement our own crop view
// This makes it easier to replace with another library later
struct CropView: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ImageCropperView(
            image: image,
            onCrop: onCrop,
            onCancel: onCancel
        )
    }
}

// Custom crop view for circular profile picture
struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void
    let onCancel: () -> Void
    
    // View state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var isZooming: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                VStack {
                    // Title and instructions
                    Text("Move and Scale")
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.top)
                    
                    Text("Drag to position • Pinch to zoom")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.caption)
                        .padding(.bottom, 8)
                    
                    // Image cropper area
                    ZStack {
                        // Crop mask - fixed in center
                        CropMaskView(geometry: geometry)
                        
                        // The image with scaling and positioning
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(scale)
                            .offset(offset)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                        lastOffset = offset
                                    }
                            )
                            .simultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        isZooming = true
                                        scale = min(max(lastScale * value, 0.5), 4.0)
                                    }
                                    .onEnded { _ in
                                        isZooming = false
                                        lastScale = scale
                                    }
                            )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                    .clipped()
                    
                    Spacer()
                    
                    // Zoom slider
                    VStack {
                        HStack {
                            Image(systemName: "minus")
                                .foregroundColor(.white)
                            
                            Slider(value: $scale, in: 0.5...4.0)
                                .onChange(of: scale) { newValue in
                                    lastScale = newValue
                                }
                                .accentColor(.white)
                            
                            Image(systemName: "plus")
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 10)
                    
                    // Buttons
                    HStack {
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        .padding()
                        
                        Spacer()
                        
                        Button("Choose") {
                            performCropping(geometry: geometry)
                        }
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                        .padding()
                    }
                    .padding(.horizontal)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Helper Views
    private func CropMaskView(geometry: GeometryProxy) -> some View {
        let circleSize = min(geometry.size.width, geometry.size.height) * 0.7
        
        return ZStack {
            // Dark overlay with circle cut out
            Rectangle()
                .fill(Color.black.opacity(0.5))
                .mask(
                    ZStack {
                        Rectangle()
                        Circle()
                            .frame(width: circleSize)
                            .blendMode(.destinationOut)
                    }
                )
            
            // Circle outline
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: circleSize)
            
            // Center indicator (small cross)
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 1, height: 10)
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 10, height: 1)
            }
            .opacity(isDragging || isZooming ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: isDragging || isZooming)
        }
    }
    
    // MARK: - Helper Methods
    private func performCropping(geometry: GeometryProxy) {
        let viewSize = min(geometry.size.width, geometry.size.height)
        let circleSize = viewSize * 0.7
        let circleRadius = circleSize / 2
        
        // Get the center of our screen
        let centerX = geometry.size.width / 2
        let centerY = geometry.size.height * 0.35 // Position of the crop circle
        
        // Calculate scaled image size
        let imageView = Image(uiImage: image)
            .resizable()
            .scaledToFit()
        
        // Calculate image frame in the container
        let scaledImageWidth: CGFloat
        let scaledImageHeight: CGFloat
        
        if image.size.width > image.size.height {
            // Landscape image
            scaledImageWidth = geometry.size.width
            scaledImageHeight = geometry.size.width * (image.size.height / image.size.width)
        } else {
            // Portrait image
            scaledImageHeight = geometry.size.height * 0.7
            scaledImageWidth = scaledImageHeight * (image.size.width / image.size.height)
        }
        
        // Calculate visibleRect (the part of the image that should be cropped)
        let imageScale = CGFloat(image.cgImage?.width ?? Int(image.size.width)) / image.size.width
        
        // Calculate the position of the crop area in the image
        let scaledWidth = scaledImageWidth * scale
        let scaledHeight = scaledImageHeight * scale
        
        // Calculate crop rectangle in normalized coordinates (0.0 - 1.0)
        let normalizedX = ((centerX - offset.width) - circleRadius) / scaledWidth
        let normalizedY = ((centerY - offset.height) - circleRadius) / scaledHeight
        let normalizedWidth = circleSize / scaledWidth
        let normalizedHeight = circleSize / scaledHeight
        
        // Convert to pixel coordinates
        let cropX = max(0, min(normalizedX, 1)) * image.size.width
        let cropY = max(0, min(normalizedY, 1)) * image.size.height
        let cropWidth = min(normalizedWidth, 1.0 - normalizedX) * image.size.width
        let cropHeight = min(normalizedHeight, 1.0 - normalizedY) * image.size.height
        
        // Create crop rectangle
        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: min(cropWidth, image.size.width - cropX),
            height: min(cropHeight, image.size.height - cropY)
        )
        
        // Ensure the crop rect is valid
        guard cropRect.width > 0, cropRect.height > 0,
              let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: CGRect(
                x: cropRect.origin.x * imageScale,
                y: cropRect.origin.y * imageScale,
                width: cropRect.width * imageScale,
                height: cropRect.height * imageScale
              )) else {
            print("Invalid crop rect")
            onCrop(nil)
            return
        }
        
        // Create the cropped image
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        // Create circular mask
        let finalSize = min(cropRect.width, cropRect.height)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: finalSize, height: finalSize))
        let circularImage = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: finalSize, height: finalSize))
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            
            // Center the image in the circular mask
            let offsetX = (finalSize - cropRect.width) / 2
            let offsetY = (finalSize - cropRect.height) / 2
            croppedImage.draw(in: CGRect(
                x: offsetX,
                y: offsetY,
                width: cropRect.width,
                height: cropRect.height
            ))
        }
        
        onCrop(circularImage)
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
