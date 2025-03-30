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
                ImageCropperView(
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

// Custom crop view for circular profile picture
struct ImageCropperView: View {
    let image: UIImage
    let onCrop: (UIImage?) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var position: CGPoint = .zero
    @State private var lastPosition: CGPoint = .zero
    @State private var imageSize: CGSize = .zero
    
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
                        // The image stays fixed
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .background(
                                GeometryReader { imageGeometry in
                                    Color.clear
                                        .onAppear {
                                            imageSize = imageGeometry.size
                                            // Center the position initially
                                            position = CGPoint(
                                                x: imageGeometry.size.width / 2,
                                                y: imageGeometry.size.height / 2
                                            )
                                            lastPosition = position
                                        }
                                }
                            )
                        
                        // Draggable crop area
                        ZStack {
                            // Dark overlay with circle cut out
                            CropMaskView(geometry: geometry)
                            
                            // Circle outline
                            let circleSize = min(geometry.size.width, geometry.size.height) * 0.6
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: circleSize)
                        }
                        .position(x: position.x, y: position.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    updatePosition(value: value, geometry: geometry)
                                }
                                .onEnded { _ in
                                    lastPosition = position
                                }
                        )
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height * 0.7)
                    .clipped()
                    
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
                            performCropping(geometry: geometry)
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func CropMaskView(geometry: GeometryProxy) -> some View {
        let circleSize = min(geometry.size.width, geometry.size.height) * 0.6
        
        return Rectangle()
            .fill(Color.black.opacity(0.5))
            .mask(
                ZStack {
                    Rectangle()
                    Circle()
                        .frame(width: circleSize)
                        .blendMode(.destinationOut)
                }
            )
    }
    
    // MARK: - Helper Methods
    private func updatePosition(value: DragGesture.Value, geometry: GeometryProxy) {
        let newX = lastPosition.x + value.translation.width
        let newY = lastPosition.y + value.translation.height
        
        // Keep the circle within the image bounds
        let circleRadius = min(geometry.size.width, geometry.size.height) * 0.3
        let minX = circleRadius
        let maxX = imageSize.width - circleRadius
        let minY = circleRadius
        let maxY = imageSize.height - circleRadius
        
        position = CGPoint(
            x: min(max(newX, minX), maxX),
            y: min(max(newY, minY), maxY)
        )
    }
    
    private func performCropping(geometry: GeometryProxy) {
        // Calculate dimensions
        let circleRadius = min(geometry.size.width, geometry.size.height) * 0.3
        let cropSize = circleRadius * 2
        
        // Skip if we don't have a valid image
        guard let cgImage = image.cgImage else {
            onCrop(nil)
            return
        }
        
        // Calculate crop parameters
        let cropX = (position.x - circleRadius) * CGFloat(cgImage.width) / imageSize.width
        let cropY = (position.y - circleRadius) * CGFloat(cgImage.height) / imageSize.height
        let cropWidth = cropSize * CGFloat(cgImage.width) / imageSize.width
        let cropHeight = cropSize * CGFloat(cgImage.height) / imageSize.height
        
        // Create crop rectangle
        let cropRect = CGRect(
            x: cropX,
            y: cropY,
            width: cropWidth,
            height: cropHeight
        )
        
        // Attempt to crop the image
        guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
            onCrop(nil)
            return
        }
        
        // Convert back to UIImage
        let croppedImage = UIImage(cgImage: croppedCGImage)
        
        // Create circular mask
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cropSize, height: cropSize))
        let circularImage = createCircularImage(croppedImage: croppedImage, cropSize: cropSize, renderer: renderer)
        
        onCrop(circularImage)
    }
    
    private func createCircularImage(croppedImage: UIImage, cropSize: CGFloat, renderer: UIGraphicsImageRenderer) -> UIImage {
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: cropSize, height: cropSize))
            ctx.cgContext.addEllipse(in: rect)
            ctx.cgContext.clip()
            croppedImage.draw(in: rect)
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
