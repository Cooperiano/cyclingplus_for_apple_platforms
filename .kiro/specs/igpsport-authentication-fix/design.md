# Design Document

## Overview

This design addresses the 403 authentication error in the iGPSport integration by aligning the Swift implementation with the proven Python implementation. The core issue is that the current Swift code is missing critical HTTP headers and proper error handling that the iGPSport API requires. The design focuses on fixing the authentication flow, improving API request headers, implementing proper session management, and ensuring robust error handling.

## Architecture

### Component Structure

```
IGPSportAuthView (UI)
    ↓
IGPSportAuthManager (Authentication & Session Management)
    ↓
IGPSportAPIService (API Communication)
    ↓
IGPSportSyncService (Sync Orchestration)
    ↓
DataRepository (Local Storage)
```

### Key Changes

1. **Header Alignment**: Update all HTTP requests to match the exact headers used in the working Python implementation
2. **Session Management**: Implement proper session probing and automatic token refresh
3. **Error Handling**: Add detailed error responses with proper status code handling
4. **Rate Limiting**: Implement delays between requests to respect API limits
5. **FIT File Handling**: Improve FIT file URL detection and download logic

## Components and Interfaces

### IGPSportAuthManager

**Purpose**: Manages authentication state, credentials storage, and session validation.

**Key Methods**:
- `authenticate(username:password:) async throws -> IGPSportCredentials`
- `refreshSession() async throws`
- `testSession(credentials:) async -> Bool`
- `logout()`
- `getValidCredentials() async throws -> IGPSportCredentials`

**Changes Required**:
1. Update login request headers to match Python implementation exactly:
   - `User-Agent: igps-cn-export/1.0 (+requests)`
   - `Accept: application/json, text/plain, */*`
   - `Content-Type: application/json`
   - `Origin: https://login.passport.igpsport.cn`
   - `Referer: https://login.passport.igpsport.cn/`

2. Improve session probe logic:
   - Use the exact endpoint: `/web-gateway/web-analyze/activity/queryMyActivity?pageNo=1&pageSize=1&reqType=0&sort=1`
   - Check both HTTP status code (200) and response code (0)
   - Return boolean instead of throwing errors

3. Add automatic session refresh on startup:
   - Check if credentials exist
   - Test if session is still valid
   - Re-authenticate if expired or invalid

### IGPSportAPIService

**Purpose**: Handles all API communication with iGPSport endpoints.

**Key Methods**:
- `fetchActivities(page:pageSize:) async throws -> [IGPSportActivity]`
- `fetchActivityDetail(rideId:) async throws -> IGPSportActivityDetail`
- `downloadFITFile(from:) async throws -> Data`
- `syncActivitiesInDateRange(from:to:maxPages:) async throws -> [IGPSportActivity]`

**Changes Required**:
1. Update all request headers to include:
   - `Authorization: Bearer {token}`
   - `User-Agent: igps-cn-export/1.0 (+requests)`
   - `Accept: application/json, text/plain, */*`

2. Improve FIT file URL detection:
   - Check fields in order: fitOssPath, fitUrl, fitPath, fitDownloadUrl, fitOssUrl, fit
   - If not found in list response, fetch activity detail
   - Handle FIT files on different domains (OSS)

3. Add retry logic with exponential backoff:
   - Maximum 3 attempts per request
   - Delays: 1.2s, 2.4s, 3.6s
   - Only retry on network errors, not auth errors

4. Improve error handling:
   - 200 + code 0: Success
   - 200 + code != 0: API error with message
   - 401: Authentication failed
   - 403: Forbidden (likely header issue)
   - 429: Rate limit exceeded
   - 500+: Server error

### IGPSportSyncService

**Purpose**: Orchestrates the synchronization process with progress tracking.

**Key Methods**:
- `syncAllActivities(maxPages:) async throws`
- `syncRecentActivities(days:) async throws`
- `syncActivityWithFITFile(rideId:) async throws -> (Activity, Data?)`
- `cancelSync()`

**Changes Required**:
1. Add rate limiting between requests:
   - 600ms delay between activity fetches
   - 600ms delay between FIT file downloads
   - Use `Task.sleep(nanoseconds: 600_000_000)`

2. Improve progress tracking:
   - 0-30%: Fetching activity list
   - 30-100%: Processing activities and downloading FIT files
   - Update syncStatus with descriptive messages

3. Handle FIT file download failures gracefully:
   - Log error but continue sync
   - Don't fail entire sync if one FIT file fails
   - Store error information for user review

4. Implement proper date range filtering:
   - Parse dates from multiple formats
   - Stop pagination when past date range
   - Handle timezone considerations

## Data Models

### IGPSportCredentials

```swift
struct IGPSportCredentials: Codable {
    let username: String
    let password: String
    let accessToken: String?
    let loginTime: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(loginTime) > 24 * 3600
    }
}
```

**Changes**: None required, model is correct.

### IGPSportActivity

**Changes Required**:
1. Add computed property for FIT URL with fallback logic:
```swift
var fitFileURL: String? {
    fitOssPath ?? fitUrl ?? fitPath ?? fitDownloadUrl ?? fitOssUrl ?? fit
}
```

2. Improve date parsing with multiple format support:
```swift
private func parseStartDate() -> Date {
    let formatters = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ss.SSS",
        "yyyy.MM.dd HH:mm:ss"
    ]
    // Try each format
}
```

### Response Models

All response models follow the pattern:
```swift
struct IGPSportResponse: Codable {
    let code: Int        // 0 = success
    let message: String? // Error message if code != 0
    let data: T?         // Response data
}
```

## Error Handling

### Error Types

1. **Authentication Errors** (401, 403):
   - Clear stored credentials
   - Show login screen
   - Display specific error message

2. **Rate Limit Errors** (429):
   - Pause sync operation
   - Show user-friendly message
   - Suggest trying again later

3. **Network Errors**:
   - Retry with exponential backoff
   - Show connection error message
   - Allow manual retry

4. **API Errors** (code != 0):
   - Parse error message from response
   - Display to user
   - Log for debugging

### Error Recovery

```
Request Failed
    ↓
Is Auth Error? → Yes → Clear credentials → Show login
    ↓ No
Is Rate Limit? → Yes → Pause sync → Show message
    ↓ No
Is Network Error? → Yes → Retry (max 3) → Exponential backoff
    ↓ No
Show error message → Allow manual retry
```

## Testing Strategy

### Unit Tests

1. **IGPSportAuthManager Tests**:
   - Test successful authentication
   - Test authentication with invalid credentials
   - Test session expiration detection
   - Test session probe logic
   - Test credential storage and retrieval

2. **IGPSportAPIService Tests**:
   - Test activity list fetching
   - Test activity detail fetching
   - Test FIT file download
   - Test error handling for different status codes
   - Test retry logic

3. **IGPSportSyncService Tests**:
   - Test full sync flow
   - Test date range filtering
   - Test progress tracking
   - Test rate limiting delays
   - Test error recovery

### Integration Tests

1. **End-to-End Authentication Flow**:
   - Login with real credentials
   - Verify session persistence
   - Test automatic session refresh

2. **Activity Sync Flow**:
   - Fetch activities from API
   - Download FIT files
   - Save to local database
   - Verify data integrity

### Manual Testing

1. **Authentication**:
   - Test with valid credentials
   - Test with invalid credentials
   - Test session persistence across app restarts
   - Test logout functionality

2. **Sync Operations**:
   - Test full sync with many activities
   - Test recent sync (7 days)
   - Test date range sync
   - Test sync cancellation
   - Test sync with network interruption

3. **Error Scenarios**:
   - Test with expired session
   - Test with rate limiting
   - Test with network disconnection
   - Test with invalid FIT URLs

## Implementation Notes

### Critical Header Configuration

The Python implementation uses these exact headers for login:
```python
"user-agent": "igps-cn-export/1.0 (+requests)",
"accept": "application/json, text/plain, */*",
"content-type": "application/json",
"origin": "https://login.passport.igpsport.cn",
"referer": "https://login.passport.igpsport.cn/"
```

The Swift implementation must match these exactly. The 403 error is likely caused by missing or incorrect headers that trigger the API's bot detection.

### Session Management

The Python implementation checks for existing Bearer tokens and validates them before attempting password login. This pattern should be replicated in Swift:

1. Check for stored credentials
2. If token exists, test it with a probe request
3. If probe succeeds, use existing token
4. If probe fails or no token, perform password login
5. Store new token and timestamp

### Rate Limiting

The Python implementation uses a 0.6-second delay between requests. This should be strictly enforced in Swift to avoid rate limiting issues.

### FIT File URLs

FIT files may be hosted on different domains (OSS storage). The download request should not include the Authorization header for these external URLs, only the User-Agent header.
