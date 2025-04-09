# Spawn App Mobile Caching Implementation Guide

This document explains the mobile caching implementation in the Spawn App iOS codebase.

## Overview

The Spawn App iOS client implements a sophisticated caching mechanism to reduce API calls, speed up the app's responsiveness, and provide a better user experience. This is achieved through:

1. **Client-side caching:** Storing frequently accessed data locally
2. **Cache invalidation:** Checking with the backend to determine if cached data is stale
3. **Push notifications:** Receiving real-time updates when relevant data changes

## Components

### AppCache Singleton

The `AppCache` class is a singleton that manages the client-side cache:

- Stores cached data in memory using `@Published` properties for reactive SwiftUI updates
- Persists cached data to disk using `UserDefaults`
- Validates cache with backend on app launch
- Provides methods to refresh different data collections

Example of using the AppCache:

```swift
// Access cached friends in a view
struct FriendsListView: View {
    @EnvironmentObject var appCache: AppCache
    
    var body: some View {
        List(appCache.friends) { friend in
            FriendRow(friend: friend)
        }
    }
}
```

### Cache Validation API

The app makes a request to `/api/v1/cache/validate/:userId` on startup, sending a list of cached items and their timestamps:

```json
{
  "friends": "2025-04-01T10:00:00Z",
  "events": "2025-04-01T10:10:00Z",
  "notifications": "2025-04-01T10:05:00Z"
}
```

The backend responds with which items need to be refreshed:

```json
{
  "friends": {
    "invalidate": true,
    "updatedItems": [...] // Optional
  },
  "notifications": {
    "invalidate": false
  },
  "events": {
    "invalidate": true
  }
}
```

### Push Notification Handling

The app listens for push notifications with specific types that indicate data changes:

- `friend-accepted`: When a friend request is accepted
- `event-updated`: When an event is updated
- `new-notification`: When a new notification is created

When these notifications are received, the app refreshes the relevant cached data.

## How It Works

1. On app launch, `AppCache` loads cached data from disk
2. The app sends a request to validate the cache with the backend
3. For invalidated cache items:
   - If the backend provides updated data, it's used directly
   - Otherwise, the app fetches the data with a separate API call
4. As the user uses the app, they see data from the cache immediately
5. In the background, the app may update cache items based on push notifications

## Implementation Details

### Data Flow

1. App loads cached data → UI renders immediately
2. App checks if cache is valid → Updates UI if needed
3. User interacts with fresh data → Great experience!

### Benefits

- **Speed:** UI renders instantly from cache
- **Bandwidth:** Reduced API calls
- **Battery:** Less network activity
- **Offline Use:** Basic functionality without network

## Testing the Cache

To verify the cache is working:

1. Launch the app and navigate to a screen that displays cached data (e.g., friends list)
2. Put the device in airplane mode
3. Close and reopen the app
4. The data should still be displayed, loaded from the cache

## Cache Limitations

The current implementation has some limitations:

1. Cache is stored in `UserDefaults`, which has size limitations
2. No encryption for cached data
3. No automatic pruning of old cached data
4. Limited offline editing capabilities

These could be addressed in future updates.

## Backend Implementation Requirements

The backend needs to implement the cache validation endpoint as described in `cache-validation-api-spec.md`.

Additionally, the backend should send appropriate push notifications when data changes that would affect a user's cache. 