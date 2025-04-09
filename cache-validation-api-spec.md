# Cache Validation API Specification

This document outlines the API specifications for the cache validation controller that should be implemented on the backend to support mobile caching in the Spawn App.

## Endpoint: `/api/v1/cache/validate/:userId`

### Method: POST

### Description
Validates the timestamps of cached items on the mobile client and determines which items need to be refreshed.

### Request

#### URL Parameters
- `userId` (UUID, required): The ID of the user making the request

#### Headers
- `Content-Type: application/json`
- `Authorization: Bearer {token}` (if authentication is required)

#### Request Body
A JSON object with keys representing different cache collections and values representing the last time those collections were updated.

Example:
```json
{
  "friends": "2025-04-01T10:00:00Z",
  "events": "2025-04-01T10:10:00Z",
  "notifications": "2025-04-01T10:05:00Z"
}
```

### Response

#### Status Codes
- `200 OK`: Successfully processed the validation request
- `400 Bad Request`: Invalid request parameters
- `401 Unauthorized`: User is not authenticated
- `403 Forbidden`: User does not have permission to access this resource
- `500 Internal Server Error`: Server error

#### Response Body
A JSON object with the same keys as the request, but with values indicating whether the client should invalidate its cache for that collection, and optionally providing the updated data.

Example:
```json
{
  "friends": {
    "invalidate": true,
    "updatedItems": [...] // Optional array of friend objects
  },
  "notifications": {
    "invalidate": false
  },
  "events": {
    "invalidate": true
  }
}
```

## Backend Implementation Notes

The cache validation controller should:

1. Compare the timestamps in the request to the last modification times of each data collection in the database
2. For each collection, determine if the client's cache is stale
3. For smaller collections, optionally include the updated data in the response to avoid additional round trips
4. For larger collections, only indicate that the client should refresh the data with a separate API call

## Push Notification Support

In addition to the validation endpoint, the backend should send push notifications when data changes that would affect a user's cached data:

### Friend Request Accepted
When a user accepts a friend request, send a push notification to the requesting user:
```json
{
  "type": "friend-accepted",
  "message": "Friend request accepted",
  "userId": "{userId}"
}
```

### Event Updated
When an event is updated, send a push notification to all participants:
```json
{
  "type": "event-updated",
  "message": "Event updated",
  "eventId": "{eventId}"
}
```

### New Notification
When a new notification is created, send a push notification:
```json
{
  "type": "new-notification",
  "message": "You have a new notification",
  "notificationId": "{notificationId}"
}
``` 