# Swivo API Documentation

This document provides details on the API endpoints and functions available for the Swivo iOS app.

## Authentication

### Anonymous Sign-In

Swivo uses anonymous authentication as specified in the requirements.

```swift
// Example using Supabase Swift SDK
try await supabase.auth.signInAnonymously()
```

## Database Tables

Here's a summary of the database tables:

| Table | Primary Key | Description |
|-------|-------------|-------------|
| `users` | `id` (UUID) | Stores user profiles with usernames and push notification tokens |
| `categories` | `id` (UUID) | Available categories for sessions (e.g., Restaurants, Movies) |
| `sessions` | `id` (UUID) | Swiping sessions with status and configuration |
| `session_participants` | `session_id`, `user_id` | Maps users to sessions they're participating in |
| `options` | `id` (UUID) | Options within each category that users swipe on |
| `session_options` | `session_id`, `option_id` | Maps options to sessions with ordering |
| `likes` | `id` (UUID) | Records when a user likes an option in a session |

## Database Functions

### `create_session`

Creates a new swiping session with a random invite code.

**Parameters:**
- `p_category_id` (UUID): The ID of the category for this session
- `p_quorum_n` (INTEGER, default: 2): The number of likes needed for a match

**Returns:** JSON with `session_id`, `invite_code`, and `created_at`

**Example:**
```swift
let response = try await supabase.rpc(
    fn: "create_session",
    params: ["p_category_id": categoryId, "p_quorum_n": 3]
).execute()
let result = try response.decoded(to: CreateSessionResponse.self)
```

### `join_session`

Joins an existing session using an invite code.

**Parameters:**
- `p_invite_code` (TEXT): The invite code for the session to join

**Returns:** JSON with `success`, `session_id` (if successful), or `message` (if error)

**Example:**
```swift
let response = try await supabase.rpc(
    fn: "join_session",
    params: ["p_invite_code": inviteCode]
).execute()
let result = try response.decoded(to: JoinSessionResponse.self)
```

### `like_option`

Records a user's like for an option and checks if a match is found.

**Parameters:**
- `p_session_id` (UUID): The session ID
- `p_option_id` (UUID): The option ID that was liked

**Returns:** JSON with `success`, `match_found` (boolean), and `matched_option_id` (if match found)

**Example:**
```swift
let response = try await supabase.rpc(
    fn: "like_option",
    params: ["p_session_id": sessionId, "p_option_id": optionId]
).execute()
let result = try response.decoded(to: LikeOptionResponse.self)
```

### `update_apns_token`

Updates the user's Apple Push Notification Service token.

**Parameters:**
- `p_token` (TEXT): The APNS token from the device (or NULL to disable notifications)

**Returns:** VOID (no return value)

**Example:**
```swift
try await supabase.rpc(
    fn: "update_apns_token",
    params: ["p_token": deviceToken]
).execute()
```

### `close_session`

Manually closes a session (can only be called by the session creator).

**Parameters:**
- `p_session_id` (UUID): The session ID to close

**Returns:** BOOLEAN indicating success or failure

**Example:**
```swift
let response = try await supabase.rpc(
    fn: "close_session",
    params: ["p_session_id": sessionId]
).execute()
let success = try response.decoded(to: Bool.self)
```

## Edge Functions

### `like_option`

Handles the process of liking an option and checks if a match is found.

**Endpoint:** `/functions/v1/like_option`

**Method:** POST

**Headers:**
- `Authorization: Bearer {JWT_TOKEN}`

**Request Body:**
```json
{
  "session_id": "UUID",
  "option_id": "UUID"
}
```

**Response:**
```json
{
  "success": true,
  "match_found": true,
  "matched_option_id": "UUID"
}
```

### `update_apns_token`

Updates the user's APNS token in the database.

**Endpoint:** `/functions/v1/update_apns_token`

**Method:** POST

**Headers:**
- `Authorization: Bearer {JWT_TOKEN}`

**Request Body:**
```json
{
  "token": "APNS_TOKEN"
}
```

**Response:**
```json
{
  "success": true
}
```

### `notify_match`

This function is triggered automatically when a match occurs and sends push notifications to session participants.

**Note:** This is an internal function and not called directly from the client app.

## Common Data Queries

### Get User's Open Sessions

```swift
let response = try await supabase
    .from("sessions")
    .select("""
        id, 
        invite_code, 
        quorum_n, 
        status, 
        matched_option_id, 
        created_at, 
        categories!inner(name, icon_url), 
        session_participants(user_id)
    """)
    .eq("status", "open")
    .execute()
```

### Get Session Options for Swiping

```swift
let response = try await supabase
    .from("session_options")
    .select("""
        options!inner(id, label, image_url),
        order_index
    """)
    .eq("session_id", sessionId)
    .order("order_index")
    .execute()
```

### Get Session Participants

```swift
let response = try await supabase
    .from("session_participants")
    .select("users!inner(id, username)")
    .eq("session_id", sessionId)
    .execute()
```

## Error Handling

Common error codes:

- **401**: Unauthorized - User is not authenticated
- **403**: Forbidden - User doesn't have permission to access the resource
- **404**: Not found - Resource doesn't exist
- **409**: Conflict - Operation conflicts with existing data (e.g., already joined session)
- **500**: Server error - Something went wrong on the server

## Best Practices

1. **Listen for Matches**: Use Supabase realtime subscriptions to get notified of matches:

```swift
let subscription = supabase.realtime
    .channel("match-channel")
    .on(.update, table: "sessions", filter: "id=eq.\(sessionId) AND status=eq.matched") { payload in
        // Handle match notification
    }
    .subscribe()
```

2. **Handle Offline Mode**: Queue likes locally when offline and sync when back online

3. **Refresh Sessions**: Implement pull-to-refresh to update session status
