//
//  ActivityPopupDrawer.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/15/25.
//
import SwiftUI

struct ActivityPopupDrawer: View {
    let activity: FullFeedActivityDTO
    let activityColor: Color
    @Binding var isPresented: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded: Bool = false
    @State private var isDragging: Bool = false
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var halfScreenOffset: CGFloat {
        screenHeight * 0.20
    }
    
    private var currentOffset: CGFloat {
        if isExpanded {
            return dragOffset
        } else {
            return halfScreenOffset + dragOffset
        }
    }
    
    var body: some View {
        ZStack {
            // Background overlay
//            Color.clear
//                .background(
//                    Rectangle()
//                        .fill(Color.white.opacity(0.2)) // Very subtle overlay
//                        .blur(radius: 50) // Gentle blur
//                )
//                .ignoresSafeArea()
//                .onTapGesture {
//                    dismissPopup()
//                }
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent multiple dismissals
                        guard isPresented else { return }
                        dismissPopup()
                    }
            // Popup content
            VStack(spacing: 0) {
                ActivityCardPopupView(activity: activity, activityColor: activityColor)
            }
            .background(activityColor.opacity(0.08))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .offset(y: currentOffset)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true
                        // Allow dragging in both directions for smoother interaction
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        isDragging = false
                        handleDragEnd(value: value)
                    }
            )
        }
        .transition(.move(edge: .bottom))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                // Popup slides up from bottom on appear
            }
        }
        .allowsHitTesting(isPresented)
        .background(Color.clear.blur(radius: 8))
        .ignoresSafeArea(.container, edges: .bottom) // Extend into safe area at bottom
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
            let velocity = value.predictedEndTranslation.height - value.translation.height
            let dragDistance = value.translation.height
            
            // More sensitive thresholds for better UX
            let distanceThreshold: CGFloat = 80
            let velocityThreshold: CGFloat = 400
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                if dragDistance > distanceThreshold || velocity > velocityThreshold {
                    // Dragging down
                    dismissPopup()
                    return
                } else if dragDistance < -distanceThreshold || velocity < -velocityThreshold {
                    // Dragging up - expand to fullscreen
                    isExpanded = true
                } else {
                    // Small drag - stay in current state
                    // Animation will reset dragOffset to 0
                }
                
                dragOffset = 0
            }
    }
    private func dismissPopup() {
            dragOffset = 0
            isExpanded = false
            isDragging = false
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0)) {
                isPresented = false
            }
    }
}

// UIKit Visual Effect View wrapper for proper background blur
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}


