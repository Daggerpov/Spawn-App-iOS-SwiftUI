//
//  ActivityPopupDrawer.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 6/15/25.
//
import SwiftUI

struct ActivityPopupDrawer: View {
    @ObservedObject var activity: FullFeedActivityDTO
    let activityColor: Color
    @Binding var isPresented: Bool
    
    // Optional binding to control tab selection for current user navigation
    @Binding var selectedTab: TabType?
    
    // Flag to determine if opened from map view
    let fromMapView: Bool
    
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded: Bool = false
    @State private var isDragging: Bool = false
    @State private var animationOffset: CGFloat = 0
    
    init(
        activity: FullFeedActivityDTO,
        activityColor: Color,
        isPresented: Binding<Bool>,
        selectedTab: Binding<TabType?> = .constant(nil),
        fromMapView: Bool = false
    ) {
        self.activity = activity
        self.activityColor = activityColor
        self._isPresented = isPresented
        self._selectedTab = selectedTab
        self.fromMapView = fromMapView
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var halfScreenOffset: CGFloat {
        // When opened from map view, show a smaller minimized card since there's no map preview
        fromMapView ? screenHeight * 0.42 : screenHeight * 0.30
    }
    
    private var currentOffset: CGFloat {
        if isExpanded {
            return dragOffset
        } else {
            return halfScreenOffset + dragOffset + animationOffset
        }
    }
    
    var body: some View {
        ZStack {
            VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
                    .ignoresSafeArea(.all, edges: .all) // Cover everything including tab bar
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure full coverage
                    .onTapGesture {
                        // Prevent multiple dismissals
                        guard isPresented else { return }
                        dismissPopup()
                    }
                    .opacity(0.65)
                    .zIndex(isExpanded ? 999 : 0) // Ensure blur covers tab bar when expanded
            // Popup content
            VStack(spacing: 0) {
                ActivityCardPopupView(
                    activity: activity, 
                    activityColor: activityColor, 
                    isExpanded: $isExpanded, 
                    selectedTab: $selectedTab,
                    fromMapView: fromMapView,
                    onDismiss: dismissPopup,
                    onMinimize: minimizePopup
                )
            }
            .background(activityColor.opacity(0.08))
            .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : nil)
            .cornerRadius(isExpanded ? 0 : 20, corners: [.topLeft, .topRight])
            .offset(y: currentOffset)
            .gesture(
                DragGesture(minimumDistance: 50) // Increased significantly to prevent interference with buttons
                    .onChanged { value in
                        // Only start dragging if user is clearly performing a drag gesture
                        guard abs(value.translation.height) > abs(value.translation.width) else { return }
                        isDragging = true
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        isDragging = false
                        handleDragEnd(value: value)
                    }
            )
            .allowsHitTesting(true) // Ensure buttons inside can still be tapped
            .ignoresSafeArea(isExpanded ? .all : .container, edges: isExpanded ? .all : .bottom)
            .zIndex(isExpanded ? 1000 : 1) // Ensure expanded popup appears above tab bar
        }
        .transition(.move(edge: .bottom))
        .onAppear {
            // Start with popup off-screen
            animationOffset = screenHeight
            // Animate to final position
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
                animationOffset = 0
            }
        }
        .allowsHitTesting(isPresented)
    }
    
    private func handleDragEnd(value: DragGesture.Value) {
            let velocity = value.predictedEndTranslation.height - value.translation.height
            let dragDistance = value.translation.height
            
            // More sensitive thresholds for better UX
            let distanceThreshold: CGFloat = 80
            let velocityThreshold: CGFloat = 400
            
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
                if dragDistance > distanceThreshold || velocity > velocityThreshold {
                    // Dragging down
                    if isExpanded {
                        // If expanded, first collapse to half screen
                        isExpanded = false
                    } else {
                        // If already collapsed, dismiss
                        dismissPopup()
                        return
                    }
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
    
    private func minimizePopup() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
            isExpanded = false
            dragOffset = 0
        }
    }
    
    private func dismissPopup() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0)) {
            animationOffset = screenHeight
        }
        dragOffset = 0
        isExpanded = false
        isDragging = false
        
        // Delay the actual dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            dragOffset = 0
            isExpanded = false
            isDragging = false
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


