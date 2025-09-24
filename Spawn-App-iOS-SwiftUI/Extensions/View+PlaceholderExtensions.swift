import SwiftUI

// MARK: - Placeholder Extension
extension View {
    /// Extension to support placeholders with custom styling
    /// - Parameters:
    ///   - shouldShow: Boolean indicating when to show the placeholder
    ///   - alignment: Alignment for the placeholder within the ZStack
    ///   - placeholder: ViewBuilder closure that returns the placeholder view
    /// - Returns: A view with the placeholder overlay
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    /// Conditionally applies a modifier to a view
    /// - Parameters:
    ///   - condition: Boolean condition to check
    ///   - transform: Transformation to apply if condition is true
    /// - Returns: Modified view if condition is true, otherwise original view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 