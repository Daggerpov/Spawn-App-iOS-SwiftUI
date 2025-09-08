import Foundation

/// Data transfer object for managing user preferences and tutorial status
struct UserPreferencesDTO: Codable {
    /// Whether the user has completed the first-time tutorial
    let hasCompletedTutorial: Bool
    
    /// The user ID associated with these preferences
    let userId: UUID
    
    init(hasCompletedTutorial: Bool, userId: UUID) {
        self.hasCompletedTutorial = hasCompletedTutorial
        self.userId = userId
    }
}
