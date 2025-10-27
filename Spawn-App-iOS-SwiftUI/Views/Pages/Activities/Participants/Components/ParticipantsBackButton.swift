import SwiftUI

/// Wrapper around UnifiedBackButton for backwards compatibility
/// Now uses the unified button system (DRY refactoring)
/// Note: This version uses white opacity color for participants view
struct ParticipantsBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticFeedbackService.shared.light()
            action()
        }) {
            Image(systemName: "chevron.left")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

