# Requirements Document

## Introduction

The iGPSport authentication integration in the CyclingPlus macOS app is currently failing with a 403 error. The existing Swift implementation needs to be fixed to match the working Python implementation that successfully authenticates with the iGPSport China API (prod.zh.igpsport.com). The system must authenticate users, maintain sessions, fetch activities, and download FIT files from iGPSport.

## Glossary

- **IGPSportAuthManager**: The Swift service responsible for authenticating users with iGPSport and managing credentials
- **IGPSportAPIService**: The Swift service that makes API calls to iGPSport endpoints
- **Bearer Token**: The access token returned by iGPSport after successful authentication
- **FIT File**: A binary file format containing detailed cycling activity data
- **Session Probe**: An API call to verify that an authentication token is still valid
- **Rate Limiting**: Intentional delays between API requests to avoid overwhelming the server

## Requirements

### Requirement 1

**User Story:** As a cyclist, I want to authenticate with my iGPSport account, so that I can sync my cycling activities from iGPSport devices.

#### Acceptance Criteria

1. WHEN the user enters valid iGPSport credentials and submits the login form, THE IGPSportAuthManager SHALL send a POST request to the iGPSport login endpoint with correct headers matching the working Python implementation
2. WHEN the iGPSport API returns a successful authentication response with code 0, THE IGPSportAuthManager SHALL extract the access token and store it securely in the macOS Keychain
3. WHEN the iGPSport API returns an error response, THE IGPSportAuthManager SHALL display the error message to the user
4. WHEN authentication succeeds, THE IGPSportAuthManager SHALL update the isAuthenticated state to true
5. WHEN the user has stored credentials, THE IGPSportAuthManager SHALL verify the session is still valid on app launch by performing a session probe

### Requirement 2

**User Story:** As a cyclist, I want the app to maintain my iGPSport session automatically, so that I don't have to re-authenticate frequently.

#### Acceptance Criteria

1. WHEN the stored access token is older than 24 hours, THE IGPSportAuthManager SHALL automatically re-authenticate using the stored credentials
2. WHEN a session probe request returns a 200 status code with response code 0, THE IGPSportAuthManager SHALL consider the session valid
3. WHEN a session probe fails, THE IGPSportAuthManager SHALL attempt to refresh the session by re-authenticating
4. WHEN session refresh fails, THE IGPSportAuthManager SHALL clear stored credentials and set isAuthenticated to false
5. THE IGPSportAuthManager SHALL store the login timestamp to track session age

### Requirement 3

**User Story:** As a cyclist, I want to fetch my activity list from iGPSport, so that I can see all my rides in the app.

#### Acceptance Criteria

1. WHEN the user requests to sync activities, THE IGPSportAPIService SHALL send a GET request to the activity list endpoint with valid authorization header
2. WHEN the API returns activity data with code 0, THE IGPSportAPIService SHALL parse the response and return an array of IGPSportActivity objects
3. WHEN the API returns a 401 status code, THE IGPSportAPIService SHALL throw an authentication failed error
4. WHEN the API returns a 429 status code, THE IGPSportAPIService SHALL throw a rate limit exceeded error
5. THE IGPSportAPIService SHALL support pagination with configurable page number and page size parameters

### Requirement 4

**User Story:** As a cyclist, I want to download FIT files for my iGPSport activities, so that I can analyze detailed ride data.

#### Acceptance Criteria

1. WHEN an activity has a FIT file URL available, THE IGPSportAPIService SHALL download the FIT file data from the provided URL
2. WHEN the FIT file download succeeds, THE IGPSportAPIService SHALL return the binary data
3. WHEN the FIT file download fails, THE IGPSportAPIService SHALL throw an appropriate error without failing the entire sync
4. THE IGPSportAPIService SHALL check multiple possible field names for the FIT file URL (fitOssPath, fitUrl, fitPath, fitDownloadUrl, fitOssUrl, fit)
5. WHEN the activity list does not contain a FIT URL, THE IGPSportAPIService SHALL fetch the activity detail to retrieve the FIT URL

### Requirement 5

**User Story:** As a cyclist, I want the app to respect iGPSport's API rate limits, so that my account doesn't get blocked.

#### Acceptance Criteria

1. WHEN making multiple API requests in sequence, THE IGPSportSyncService SHALL wait at least 600 milliseconds between requests
2. WHEN a rate limit error occurs, THE IGPSportSyncService SHALL display an appropriate error message to the user
3. THE IGPSportSyncService SHALL implement a maximum retry count of 3 attempts for failed requests
4. WHEN retrying a failed request, THE IGPSportSyncService SHALL increase the delay exponentially (1.2 seconds, 2.4 seconds, 3.6 seconds)
5. THE IGPSportAPIService SHALL configure URLSession with appropriate timeout values (10 seconds for connection, 60 seconds for resource)

### Requirement 6

**User Story:** As a cyclist, I want to sync activities within a specific date range, so that I can control which activities are imported.

#### Acceptance Criteria

1. WHEN the user specifies a start date and end date, THE IGPSportSyncService SHALL fetch only activities within that date range
2. WHEN processing paginated results, THE IGPSportSyncService SHALL stop fetching additional pages when activities fall before the start date
3. THE IGPSportSyncService SHALL parse activity dates from multiple possible formats (yyyy-MM-dd HH:mm:ss, yyyy-MM-dd'T'HH:mm:ss, yyyy.MM.dd HH:mm:ss)
4. WHEN an activity date cannot be parsed, THE IGPSportSyncService SHALL use the current date as a fallback
5. THE IGPSportSyncService SHALL support a maximum page limit to prevent infinite loops

### Requirement 7

**User Story:** As a cyclist, I want to see sync progress and status, so that I know what the app is doing during synchronization.

#### Acceptance Criteria

1. WHEN a sync operation starts, THE IGPSportSyncService SHALL set isSyncing to true and syncProgress to 0.0
2. WHEN activities are being fetched, THE IGPSportSyncService SHALL update syncStatus with descriptive messages
3. WHEN processing activities, THE IGPSportSyncService SHALL update syncProgress as a percentage from 0.0 to 1.0
4. WHEN sync completes successfully, THE IGPSportSyncService SHALL update lastSyncDate to the current time
5. WHEN sync fails, THE IGPSportSyncService SHALL set syncError with the error details and set isSyncing to false
