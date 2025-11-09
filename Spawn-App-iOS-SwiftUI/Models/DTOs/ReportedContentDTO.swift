import Foundation

struct ReportedContentDTO: Codable {
	let id: UUID?
	let reporter: UserDTO?
	let contentId: UUID
	let contentType: EntityType
	let timeReported: Date?
	let resolution: ResolutionStatus?
	let reportType: ReportType
	let description: String
	let reportedUser: UserDTO?

	// Convenience initializer for creating reports
	init(
		contentId: UUID,
		contentType: EntityType,
		reportType: ReportType,
		description: String,
		reporter: UserDTO? = nil,
		reportedUser: UserDTO? = nil
	) {
		self.id = nil
		self.reporter = reporter
		self.contentId = contentId
		self.contentType = contentType
		self.timeReported = nil
		self.resolution = nil
		self.reportType = reportType
		self.description = description
		self.reportedUser = reportedUser
	}
}

// Enums to match backend
enum EntityType: String, Codable, CaseIterable {
	case chatMessage = "ChatMessage"
	case activity = "Activity"
	case activityType = "ActivityType"
	case user = "User"
	case friendRequest = "FriendRequest"
	case betaAccessSignUp = "BetaAccessSignUp"
	case location = "Location"
	case chatMessageLike = "ChatMessageLike"
	case activityUser = "ActivityUser"
	case externalIdMap = "ExternalIdMap"
	case reportedContent = "ReportedContent"
	case feedbackSubmission = "FeedbackSubmission"

	var description: String {
		switch self {
		case .chatMessage:
			return "Chat Message"
		case .activity:
			return "Activity"
		case .activityType:
			return "Activity Type"
		case .user:
			return "User"
		case .friendRequest:
			return "Friend Request"
		case .betaAccessSignUp:
			return "Beta Access Sign Up"
		case .location:
			return "Location"
		case .chatMessageLike:
			return "Chat Message Like"
		case .activityUser:
			return "Activity User"
		case .externalIdMap:
			return "External ID Map"
		case .reportedContent:
			return "Reported Content"
		case .feedbackSubmission:
			return "Feedback Submission"
		}
	}
}

enum ReportType: String, Codable, CaseIterable {
	case harassment = "HARASSMENT"
	case violence = "VIOLENCE"
	case nudity = "NUDITY"
	case bullying = "BULLYING"

	var displayName: String {
		switch self {
		case .harassment:
			return "Harassment"
		case .violence:
			return "Violence, hate or exploitation"
		case .nudity:
			return "Nudity or sexual content"
		case .bullying:
			return "Bullying"
		}
	}
}

enum ResolutionStatus: String, Codable, CaseIterable {
	case pending = "PENDING"
	case resolved = "RESOLVED"
	case dismissed = "DISMISSED"
}
