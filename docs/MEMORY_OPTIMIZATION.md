# Memory Optimization Summary

**Context:** ~800 MB usage on iPhone 11 (4 GB RAM) is very high. Target: 80–150 MB for a well-optimized social app. iOS may terminate apps above ~1.5 GB.

Use this doc as a checklist when implementing fixes on a separate branch.

---

## 1. Profile Picture Cache — No Memory Limit (P0)

**Location:** `Spawn-App-iOS-SwiftUI/Services/Cache/ProfilePictureCache.swift`

**Issue:** `memoryCache` is a plain `[UUID: UIImage]` dictionary. Every downloaded profile picture is kept in memory forever. Loading from disk also populates memory (line 255). No eviction. Preloading in `ActivityCacheService` and `FriendshipCacheService` downloads/caches pictures for every user in activities and friends.

**Impact:** 100–300+ MB (decoded UIImages are large; many users × many images).

**Fix:**
- Replace `private var memoryCache: [UUID: UIImage] = [:]` with `NSCache<NSUUID, UIImage>`.
- Set `countLimit` (e.g. 50) and `totalCostLimit` (e.g. ~50 MB).
- On insert, use `setObject(_:forKey:cost:)` with cost = approximate byte size (e.g. image data length or width×height×4).
- Keep disk cache as-is; memory cache becomes a bounded working set.

---

## 2. UserDefaults for Large Data (P0)

**Location:** `BaseCacheService.saveToDefaults` / `loadFromDefaults`; all cache services persist full DTOs to UserDefaults.

**Issue:** Activities, friends, profiles, etc. are stored in memory as Swift objects, encoded to JSON, and written to UserDefaults. UserDefaults keeps its plist in memory — so data exists in three forms and triples memory for large datasets.

**Impact:** 50–200 MB.

**Fix:**
- Stop using UserDefaults for large collections (activities, friends, profiles, calendar, etc.).
- Persist to files in Caches directory (e.g. `Caches/ActivityCache/activities.json`) and read on demand or on app launch.
- Keep only small preferences (e.g. last sync timestamps) in UserDefaults if needed.

---

## 3. FullFeedActivityDTO and Chat Messages (P1)

**Location:** `Models/DTOs/Activity/FullFeedActivityDTO.swift`; `ActivityCacheService`, `FeedViewModel`.

**Issue:** `FullFeedActivityDTO` is a **class** and includes `participantUsers`, `invitedUsers`, and full `chatMessages` (each with sender user objects). Same heavy objects live in multiple places: `ActivityCacheService.activities`, `upcomingActivities`, `FeedViewModel.activities`, and possibly calendar caches.

**Impact:** 20–100 MB.

**Fix:**
- Do not embed full chat messages in feed/activity DTOs. Load chat when user opens the chatroom (lazy).
- Consider a lighter feed DTO (e.g. struct, or omit `chatMessages`/`invitedUsers` for list views).
- Avoid holding the same activity graph in multiple collections; prefer a single source of truth and derived views.

---

## 4. Aggressive Profile Picture Preloading (P1)

**Location:**  
- `ActivityCacheService.preloadProfilePicturesForActivities` (creators, participants, invited, chat senders).  
- `FriendshipCacheService`: preload for friends, minimal friends, recommended, friend requests, sent requests, recently spawned with.

**Issue:** Every cache update triggers preloading for every user in the dataset. Combined with unbounded memory cache (see §1), this grows memory quickly.

**Impact:** 50–150 MB.

**Fix:**
- Rely on `CachedAsyncImage` (on-appear loading) instead of eager preload for all users.
- If keeping preload, limit to a small set (e.g. first 20 items or only visible-section users).
- After switching to NSCache (§1), preloading is less dangerous but still unnecessary at full scale.

---

## 5. Memory Warning Handling (P1)

**Issue:** Many singletons (AppCache, ActivityCacheService, FriendshipCacheService, ProfileCacheService, ProfilePictureCache, ProfileViewModelCache, etc.) hold data for the app’s entire lifetime. Nothing is released on memory pressure.

**Fix:**
- Observe `UIApplication.didReceiveMemoryWarningNotification`.
- On notification: clear in-memory profile picture cache (if using NSCache, it may auto-evict; otherwise add an explicit “clear memory only” API), clear or trim ProfileViewModelCache, and optionally clear non-essential in-memory caches (e.g. otherProfiles, recommended friends) while keeping current user’s core data.
- Document which caches are “essential” vs “recreatable” so future changes stay consistent.

---

## 6. Cache Structure — Storing All Users (P2)

**Location:** `ActivityCacheService`, `FriendshipCacheService`, `ProfileCacheService` — dictionaries keyed by `[UUID: [...]]`.

**Issue:** Caches are keyed by user ID and never pruned for non-current users. Only the current user’s data is used in practice, but data for other keys remains in memory and on disk.

**Impact:** 10–50 MB.

**Fix:**
- Where only “current user” data is needed, store a single array (or single key) instead of `[UUID: [Item]]`.
- On logout (or when switching user), clear all caches for the previous user.
- Optionally evict other users’ data when current user is set and memory is tight.

---

## 7. ProfileViewModelCache Size (P2)

**Location:** `ViewModels/Profile/ProfileViewModelCache.swift`

**Issue:** `maxCachedProfiles = 20` — each ProfileViewModel can hold a lot of state (activities, stats, etc.). 20 is still a large working set.

**Impact:** 10–30 MB.

**Fix:**
- Reduce to a smaller cap (e.g. 5–10) or make it configurable.
- Ensure eviction keeps the current user’s VM (already done).
- Consider releasing heavy data (e.g. activity lists) when the profile is evicted.

---

## 8. Retain Cycles / Leaks (P3)

**Locations:**
- `ActivityCreationLocationView.swift` — Timer closure captures `self` strongly (debounce timer).
- `UnifiedMapView.swift` — `DispatchQueue.main.async { context.coordinator.parent = self }`.
- `ActivityCreationLocationView.swift` — multiple `DispatchQueue.main.async` and geocoder completion handlers without `[weak self]`.
- `LocationPickerView.swift` — several `DispatchQueue.main.async` blocks with strong `self`.
- `ActivityCalendarView.swift` — `DispatchQueue.main.asyncAfter` without weak capture.

**Fix:**
- Use `[weak self]` in all Timer and DispatchQueue closures that reference `self`.
- In SwiftUI View structs, ensure any stored closures (e.g. in Coordinator) use weak references where the closure is long-lived.

---

## 9. Map Annotations (P3)

**Location:** `Views/Shared/Map/UnifiedMapView.swift`

**Issue:** On update, all annotations are removed and re-added instead of computing a diff and updating only changed annotations. Creates churn and allocation pressure.

**Fix:**
- Compute `newAnnotationIDs` and `oldAnnotationIDs`; remove only annotations whose IDs are no longer present; add only new IDs. Avoid full remove-all + add-all when the set is large.

---

## Quick Reference — Priority Order

| Priority | Item | Est. savings |
|----------|------|--------------|
| P0 | ProfilePictureCache → NSCache + limit | 100–300 MB |
| P0 | Move large data off UserDefaults to file cache | 50–200 MB |
| P1 | Lazy chat messages / lighter feed DTO | 20–100 MB |
| P1 | Reduce or remove eager profile preloading | 50–150 MB |
| P1 | Memory warning handler | Variable |
| P2 | Cache only current user where possible | 10–50 MB |
| P2 | Smaller ProfileViewModelCache cap | 10–30 MB |
| P3 | Fix Timer/Dispatch retain cycles | Prevents leaks |
| P3 | Incremental map annotation updates | Lower churn |

---

## Files to Touch (Checklist)

- [ ] `Services/Cache/ProfilePictureCache.swift` — NSCache, cost limits
- [ ] `Services/Cache/BaseCacheService.swift` — persistence strategy (file vs UserDefaults)
- [ ] `Services/Cache/ActivityCacheService.swift` — persistence, preload limits
- [ ] `Services/Cache/FriendshipCacheService.swift` — persistence, preload limits
- [ ] `Services/Cache/ProfileCacheService.swift` — persistence
- [ ] `Models/DTOs/Activity/FullFeedActivityDTO.swift` — consider lighter feed representation / lazy chat
- [ ] `ViewModels/Profile/ProfileViewModelCache.swift` — lower cap
- [ ] App lifecycle (e.g. `CustomAppDelegate` or scene delegate) — memory warning observer
- [ ] `Views/Pages/Activities/ActivityCreation/Steps/LocationSelection/ActivityCreationLocationView.swift` — weak self in Timer
- [ ] `Views/Shared/Map/UnifiedMapView.swift` — weak self; incremental annotations
- [ ] `Views/Pages/Activities/ActivityCreation/Steps/LocationSelection/LocationPickerView.swift` — weak self in async blocks
- [ ] `Views/Pages/Profile/Shared/Calendar/ActivityCalendarView.swift` — weak self in asyncAfter

---

*Generated from memory audit. Implement on a separate branch and validate with Instruments (Allocations / Leaks) and Xcode Memory Report.*
