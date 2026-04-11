import SwiftUI

/// Wrapper around UnifiedBackButton for backwards compatibility
/// Now uses the unified button system (DRY refactoring)
/// Note: This version uses white opacity color for participants view
struct ParticipantsBackButton: View {
	let action: () -> Void

	var body: some View {
		UnifiedBackButton(foregroundColor: .white.opacity(0.6), action: action)
	}
}
