# Implementation Plan

- [x] 1. Fix IGPSportAuthManager authentication headers and session management
  - Update the authenticate method to use exact headers from Python implementation
  - Fix the testSession method to properly validate sessions
  - Implement automatic session refresh on app startup
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4_

- [x] 2. Update IGPSportAPIService request headers and error handling
  - [x] 2.1 Fix headers for all API requests to match Python implementation
    - Update fetchActivities to include proper User-Agent and Accept headers
    - Update fetchActivityDetail to include proper headers
    - Update downloadFITFile to use correct headers (no auth for external URLs)
    - _Requirements: 3.1, 3.2, 4.1, 4.2_

  - [x] 2.2 Improve error handling for different HTTP status codes
    - Add specific handling for 403 Forbidden errors
    - Add specific handling for 429 Rate Limit errors
    - Parse API error messages from response body when code != 0
    - _Requirements: 3.3, 3.4, 5.2_

  - [x] 2.3 Implement FIT file URL detection logic
    - Check multiple field names in order (fitOssPath, fitUrl, fitPath, etc.)
    - Fetch activity detail if FIT URL not found in list response
    - Handle FIT files on external domains (OSS)
    - _Requirements: 4.3, 4.4, 4.5_

- [x] 3. Add retry logic with exponential backoff to IGPSportAPIService
  - Implement retry mechanism with maximum 3 attempts
  - Add exponential backoff delays (1.2s, 2.4s, 3.6s)
  - Only retry on network errors, not authentication errors
  - _Requirements: 5.3, 5.4_

- [ ] 4. Implement rate limiting in IGPSportSyncService
  - Add 600ms delay between activity fetch requests
  - Add 600ms delay between FIT file downloads
  - Use Task.sleep with nanoseconds for precise timing
  - _Requirements: 5.1, 5.5_

- [ ] 5. Improve date parsing and range filtering in IGPSportActivity model
  - Support multiple date formats (yyyy-MM-dd HH:mm:ss, ISO8601, etc.)
  - Add fallback to current date if parsing fails
  - Implement date range filtering in syncActivitiesInDateRange
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 6. Enhance sync progress tracking in IGPSportSyncService
  - Update syncProgress during activity fetching (0-30%)
  - Update syncProgress during activity processing (30-100%)
  - Set descriptive syncStatus messages throughout sync
  - Update lastSyncDate on successful completion
  - Set syncError on failure
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 7. Update IGPSportAuthView to display better error messages
  - Show specific error messages for 403 errors (header issues)
  - Show specific error messages for rate limiting
  - Display connection status during authentication
  - _Requirements: 1.3, 5.2_

- [ ]* 8. Add comprehensive error logging for debugging
  - Log all API requests with headers (excluding sensitive data)
  - Log all API responses with status codes
  - Log authentication flow steps
  - Log FIT file download attempts
  - _Requirements: All_
