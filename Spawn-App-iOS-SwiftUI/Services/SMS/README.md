# Enhanced SMS Activity Sharing Implementation

## Overview

This implementation provides enhanced SMS sharing functionality for activity invites with custom message formatting and app install CTAs as requested.

## Features Implemented

### 1. Custom SMS Message Format
When sharing an activity via SMS, the message follows this format:
```
Daniel has invited you to Lunch @ Sahel's in 30 minutes

See this activity and its chats on Spawn to stay in the loop: https://apps.apple.com/ca/app/spawn/id6738635871?platform=iphone

It's never been easier to be spontaneous. Join your friends today!
```

### 2. App Install CTA
- Includes deep link to the specific activity
- Includes App Store link: `https://apps.apple.com/ca/app/spawn/id6738635871?platform=iphone`
- Encourages users to join the platform

### 3. Deep Link Behavior

#### For Users With App Installed:
- **Activity Links**: Opens app → navigates to Home tab → registers user as invited → shows activity popup
- **Profile Links**: Opens app → navigates to Friends tab → shows specific profile

#### For Users Without App:
- Links redirect to web app with activity/profile preview
- Includes install prompts and App Store links

## Implementation Details

### Core Components

1. **SMSShareService.swift**: Main service handling SMS composition and sharing
2. **Enhanced Deep Link Manager**: Updated to handle invitation registration
3. **Updated Share Drawers**: Integration with new SMS service
4. **ContentView Updates**: Activity invitation registration on deep link

### Key Methods

#### SMSShareService
- `shareActivity(_:to:from:)`: Main method for sharing activities via SMS
- `generateActivitySMSMessage(activity:shareURL:)`: Creates the custom message format
- Fallback to system SMS if MessageUI is unavailable

#### Deep Link Manager
- `handleActivityDeepLink(_:)`: Handles activity deep links with authentication check
- `handleProfileDeepLink(_:)`: Handles profile deep links with authentication check

#### ContentView
- `registerUserAsInvitedToActivity(_:)`: Registers user as invited when opening via deep link

## Usage

### Basic SMS Sharing
```swift
SMSShareService.shared.shareActivity(activity)
```

### SMS Sharing with Specific Recipients
```swift
SMSShareService.shared.shareActivity(activity, to: ["+1234567890"])
```

### Integration in Share Drawers
```swift
// In existing share components
private func shareViaSMS() {
    SMSShareService.shared.shareActivity(activity)
}
```

## Testing Checklist

- [ ] SMS message format matches requirements
- [ ] App Store link is correct
- [ ] Deep links work for both authenticated and unauthenticated users
- [ ] Activity invitation registration works
- [ ] Profile deep links navigate to Friends page
- [ ] Fallback to system SMS works when MessageUI unavailable
- [ ] Success/error notifications display correctly

## Notes

- Uses MessageUI framework for enhanced SMS control
- Includes proper error handling and fallbacks
- Maintains backward compatibility with existing sharing
- Follows iOS design patterns and user expectations
- Includes haptic feedback for better UX
