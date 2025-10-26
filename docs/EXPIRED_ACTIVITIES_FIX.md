# Expired Activities Fix

## Problem Summary

Activities that were expired continued to appear in the activity feed (both list and map view) even after refreshing. This occurred despite the backend setting an `isExpired` field on activities.

## Root Cause Analysis

The issue was caused by **backend caching with stale expiration status**:

1. **Backend Cache**: The `getFeedActivities` endpoint uses `@Cacheable(value = "feedActivities")` annotation
2. **Expiration Computation**: The `isExpired` field is computed when activities are fetched and cached
3. **No Time-Based Invalidation**: The cache is only evicted when activities are modified (`@CacheEvict`), not when they naturally expire over time
4. **Stale Data**: Once cached, activities with `isExpired: false` remain in cache even after their actual expiration time passes

### Code Evidence

From `ActivityService.java`:
```java
@Cacheable(value = "feedActivities", key = "#requestingUserId")
public List<FullFeedActivityDTO> getFeedActivities(UUID requestingUserId) {
    // ... fetches and caches activities with computed isExpired field
}
```

The cache eviction only happens on activity modifications:
```java
@CacheEvict(value = "feedActivities", allEntries = true)
public FullFeedActivityDTO replaceActivity(ActivityDTO newActivity, UUID id) {
    // ... activity modifications clear cache
}
```

## Solution Implemented

Added **client-side expiration validation as a fallback** to complement the server-side `isExpired` field.

### Changes Made

#### 1. FeedViewModel.swift

**Enhanced Filtering Logic** (`filterExpiredActivities`):
- **Primary Check**: Use server-side `isExpired` field when set to `true`
- **Fallback Check**: Perform client-side validation to catch stale cache data:
  - For activities with `endTime`: Check if `endTime < current time`
  - For activities without `endTime`: Check if current time is past midnight (12 AM) of the following day from `createdAt`
  - Respects `clientTimezone` field for accurate timezone-aware expiration

**Added Periodic Cleanup Timer**:
- Runs every 30 seconds to locally filter expired activities
- Removes expired activities from view without requiring network calls
- Triggers cache cleanup when expired activities are detected

```swift
private func startPeriodicCleanup() {
    cleanupTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
        // Filter and remove expired activities locally
        let filteredActivities = self.filterExpiredActivities(self.activities)
        if filteredActivities.count < self.activities.count {
            self.activities = filteredActivities
            self.appCache.cleanupExpiredActivities()
        }
    }
}
```

#### 2. AppCache.swift

**Centralized Filtering Method** (`filterExpiredActivitiesWithFallback`):
- Implements the same dual-check logic (server-side + client-side)
- Used consistently across all cache operations

**Updated Methods**:
- `getCurrentUserActivities()`: Now uses fallback filtering
- `updateActivitiesForUser()`: Filters activities before caching
- `cleanupExpiredActivities()`: Uses fallback filtering for all users
- `validateCache()`: Filters activities from backend cache validation responses

## Expiration Rules

The client-side expiration logic mirrors the backend's `ActivityExpirationService`:

### Activities with Explicit End Time
- **Rule**: Expired if `endTime < current time` (UTC)
- **Example**: Activity ends at 2:00 PM, it expires at 2:01 PM

### Activities without End Time
- **Rule**: Expire at midnight (12 AM) of the following day in the activity's timezone
- **Timezone**: Uses `clientTimezone` field if available, otherwise falls back to device timezone
- **Example**: Activity created on Monday at 3:00 PM → expires Tuesday at 12:00 AM

### Activities without Creation Time
- **Rule**: Never expire (edge case, should not normally occur)

## Benefits of This Approach

1. **Defense in Depth**: Multiple layers of protection against expired activities
2. **Graceful Degradation**: Works even if backend cache has stale data
3. **Reduced Network Load**: Periodic cleanup removes expired activities locally without API calls
4. **Timezone Awareness**: Respects activity creator's timezone for accurate expiration
5. **Backwards Compatible**: Still uses server-side `isExpired` as primary source of truth

## Testing Recommendations

1. **Overnight Test**: Create activities that expire at midnight, check they're removed the next day
2. **Cache Staleness Test**: Backend cache activities, wait for expiration, verify they're filtered on iOS
3. **Timezone Test**: Create activities in different timezones, verify correct expiration timing
4. **Periodic Cleanup Test**: Observe 30-second cleanup timer removing expired activities
5. **Refresh Test**: Pull-to-refresh should not bring back expired activities

## Future Improvements

### Backend Side (Recommended)
Consider implementing time-based cache eviction:
```java
@Cacheable(value = "feedActivities", key = "#requestingUserId")
@CacheEvict(value = "feedActivities", allEntries = true, condition = "#result != null")
public List<FullFeedActivityDTO> getFeedActivities(UUID requestingUserId) {
    // Add TTL (Time To Live) to cache entries
    // Or schedule periodic cache cleanup based on soonest activity expiration
}
```

### iOS Side (Optional)
- Consider using `Combine` timer instead of `Timer` for better testability
- Add debug logging for expiration filtering (can be toggled)
- Monitor performance impact of 30-second cleanup timer

## Files Modified

1. `/Spawn-App-iOS-SwiftUI/ViewModels/FeedViewModel.swift`
   - Enhanced `filterExpiredActivities()` method
   - Added `cleanupTimer` and periodic cleanup logic
   
2. `/Spawn-App-iOS-SwiftUI/Services/AppCache.swift`
   - Added `filterExpiredActivitiesWithFallback()` helper method
   - Updated all activity filtering to use fallback logic

## Related Documentation

- Backend expiration logic: `ActivityExpirationService.java`
- Activity DTOs: `FullFeedActivityDTO.swift`, `AbstractActivityDTO.java`
- Cache validation: `CacheService.java`

---

**Date**: 2025-10-15  
**Issue**: Expired activities not being removed from feed  
**Status**: ✅ Fixed

