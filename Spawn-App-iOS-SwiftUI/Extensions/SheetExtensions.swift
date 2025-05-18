import SwiftUI

// Extension to provide backward compatibility for presentation features
extension View {
    @ViewBuilder
    func compatiblePresentationDragIndicator(_ visibility: Visibility) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationDragIndicator(visibility)
        } else {
            // For iOS versions before 16.4, just return the view as is
            self
        }
    }
    
    @ViewBuilder
    func compatiblePresentationDetents(_ detents: Set<PresentationDetent>) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationDetents(detents)
        } else {
            // For iOS versions before 16.4, just return the view as is
            self
        }
    }
    
    @ViewBuilder
    func compatiblePresentationDetent(_ detent: PresentationDetent) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationDetents([detent])
        } else {
            // For iOS versions before 16.4, just return the view as is
            self
        }
    }
    
    @ViewBuilder
    func compatiblePresentationDetents(_ detents: [PresentationDetent]) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationDetents(Set(detents))
        } else {
            // For iOS versions before 16.4, just return the view as is
            self
        }
    }
} 