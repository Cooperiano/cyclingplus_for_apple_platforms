# Design Document

## Overview

This design document outlines the integration architecture for combining iGPSport authentication and synchronization into a cohesive system within CyclingPlus. The design focuses on creating a robust, user-friendly experience that handles edge cases gracefully, provides excellent feedback, and maintains data consistency across multiple sync sources.

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      User Interface Layer                    │
│  SettingsView │ ContentView │ ActivityListView │ SyncButton │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Coordination Layer                         │
│                    SyncCoordinator                           │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ • Manages multi-source sync                          │  │
│  │ • Coordinates auth and sync services                 │  │
│  │ • Handles conflict resolution                        │  │
│  │ • Tracks overall progress                            │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────┬──────────────────────────┬─────────────────────┘
             │                          │
    ┌────────▼────────┐        ┌───────▼──────────┐
    │  Strava Stack   │        │  iGPSport Stack  │
    │                 │        │                  │
    │ StravaAuth      │        │ IGPSportAuth     │
    │ StravaSync      │        │ IGPSportSync     │
    │ StravaAPI       │        │ IGPSportAPI      │
    └────────┬────────┘        └───────┬──────────┘
             │                          │
             └──────────┬───────────────┘
                        │
            ┌───────────▼────────────┐
            │   Data Layer           │
            │                        │
            │  DataRepository        │
            │  SwiftData Models      │
            │  FIT File Storage      │
            └────────────────────────┘
```

### Component Responsibilities

1. **SyncCoordinator**: Orchestrates all sync operations, manages state, handles conflicts
2. **IGPSportAuthManager**: Manages authentication, session validation, credential storage
3. **IGPSportSyncService**: Handles activity sync, FIT downloads, progress tracking
4. **IGPSportAPIService**: Low-level API communication, retry logic, error handling
5. **DataRepository**: Database operations, transaction management, data validation
6. **FITFileManager**: FIT file storage, parsing coordination, cleanup

## Components and Interfaces

### 1. SyncCoordinator (Enhanced)

**Purpose**: Central orchestration point for all synchronization operations.

**State Management**:
```swift
@Published var isSyncing: Bool = false
@Published var syncProgress: Double = 0.0
@Published var syncStatus: String = ""
@Published var syncError: Error?
@Published var lastSyncDate: Date?
@Published var syncStatistics: SyncStatistics = SyncStatistics()

private var activeSyncTasks: [String: Task<Void, Error>] = [:]
private var syncQueue: DispatchQueue = DispatchQueue(label: "com.cyclingplus.sync", qos: .userInitiated)
```

**Key Methods**:
```swift
// Multi-source sync
func syncAllServices() async throws
func syncStrava() async throws
func syncIGPSport() async throws

// Lifecycle management
func cancelAllSyncs()
func pauseSync()
func resumeSync()

// Background sync
func performBackgroundSync() async throws
func scheduleNextBackgroundSync()

// Conflict resolution
private func detectDuplicateActivities(_ activities: [Activity]) -> [ActivityConflict]
private func resolveDuplicates(_ conflicts: [ActivityConflict]) async throws
```

**Integration Points**:
- Monitors authentication state from both auth managers
- Coordinates sync timing to avoid conflicts
- Aggregates progress from multiple sync services
- Handles cross-source duplicate detection

### 2. IGPSportAuthManager (Integration Enhancements)

**New Properties**:
```swift
@Published var sessionStatus: SessionStatus = .unknown
@Published var lastSessionCheck: Date?

enum SessionStatus {
    case unknown
    case valid
    case expired
    case invalid
}
```

**Enhanced Methods**:
```swift
// Session management
func validateSession() async -> SessionStatus
func refreshSessionIfNeeded() async throws
func handleAuthenticationError(_ error: Error) async

// Integration with sync
func prepareForSync() async throws -> IGPSportCredentials
func notifySyncStarted()
func notifySyncCompleted(success: Bool)
```

**Behavior Changes**:
- Automatically validates session before sync starts
- Provides session status to SyncCoordinator
- Handles re-authentication during active sync
- Notifies observers of session state changes

### 3. IGPSportSyncService (Integration Enhancements)

**New Properties**:
```swift
@Published var currentActivity: String?
@Published var activitiesProcessed: Int = 0
@Published var activitiesTotal: Int = 0
@Published var fitFilesDownloaded: Int = 0
@Published var fitFilesFailed: Int = 0

private var syncSession: SyncSession?
private var pendingRetries: [RetryItem] = []
```

**Enhanced Methods**:
```swift
// Sync operations with better integration
func syncWithCoordinator(coordinator: SyncCoordinator) async throws
func resumeFromCheckpoint(_ checkpoint: SyncCheckpoint) async throws

// Progress reporting
private func updateProgress(phase: SyncPhase, current: Int, total: Int)
private func reportActivityProcessed(activity: IGPSportActivity, success: Bool)

// Error recovery
func retryFailedItems() async throws
func getFailedActivities() -> [FailedActivityInfo]
```

**Integration Features**:
- Reports detailed progress to SyncCoordinator
- Supports pause/resume functionality
- Maintains sync checkpoints for recovery
- Provides retry queue for failed items

### 4. FITFileManager (New Component)

**Purpose**: Centralized management of FIT file storage, parsing, and lifecycle.

**Interface**:
```swift
class FITFileManager {
    // Storage
    func saveFITFile(_ data: Data, for activityId: String) throws -> URL
    func getFITFileURL(for activityId: String) -> URL?
    func deleteFITFile(for activityId: String) throws
    
    // Parsing
    func parseAndStore(_ data: Data, for activity: Activity) async throws -> ActivityStreams
    func reParseFITFile(for activityId: String) async throws -> ActivityStreams
    
    // Management
    func validateFITFile(at url: URL) -> Bool
    func cleanupOrphanedFiles() async throws
    func getTotalStorageUsed() -> Int64
    
    // Retry queue
    func addToRetryQueue(activityId: String, reason: String)
    func getRetryQueue() -> [FITRetryItem]
    func processRetryQueue() async throws
}
```

**Storage Structure**:
```
Application Support/
  └── FITFiles/
      ├── {activityId}.fit          (raw FIT file)
      ├── {activityId}.parsed       (marker file)
      └── {activityId}.error        (error info if parse failed)
```

### 5. DataRepository (Integration Enhancements)

**New Methods**:
```swift
// Duplicate detection
func findDuplicateActivities(startTime: Date, duration: TimeInterval, tolerance: TimeInterval) async throws -> [Activity]

// Batch operations
func saveActivitiesBatch(_ activities: [Activity]) async throws
func updateActivitiesBatch(_ updates: [(Activity, [String: Any])]) async throws

// Transaction support
func performTransaction<T>(_ operation: @escaping (ModelContext) throws -> T) async throws -> T

// Conflict resolution
func mergeActivities(_ primary: Activity, _ secondary: Activity) async throws -> Activity
```

## Data Models

### SyncStatistics

```swift
struct SyncStatistics: Codable {
    var totalActivities: Int = 0
    var successCount: Int = 0
    var failureCount: Int = 0
    var duplicatesFound: Int = 0
    var duplicatesResolved: Int = 0
    var fitFilesDownloaded: Int = 0
    var fitFilesParsed: Int = 0
    var fitFilesFailed: Int = 0
    var totalDataDownloaded: Int64 = 0
    var syncDuration: TimeInterval = 0
    var lastSyncDate: Date?
    
    mutating func reset() {
        self = SyncStatistics()
    }
}
```

### SyncSession

```swift
struct SyncSession: Codable {
    let id: UUID
    let source: SyncSource
    let startTime: Date
    var endTime: Date?
    var status: SyncSessionStatus
    var checkpoint: SyncCheckpoint?
    var statistics: SyncStatistics
    var errors: [SyncError]
    
    enum SyncSource: String, Codable {
        case strava
        case igpsport
        case all
    }
    
    enum SyncSessionStatus: String, Codable {
        case inProgress
        case completed
        case failed
        case cancelled
        case paused
    }
}
```

### SyncCheckpoint

```swift
struct SyncCheckpoint: Codable {
    let sessionId: UUID
    let timestamp: Date
    let lastProcessedActivityId: String?
    let currentPage: Int
    let activitiesProcessed: Int
    let phase: SyncPhase
    
    enum SyncPhase: String, Codable {
        case fetchingList
        case downloadingFIT
        case parsing
        case storing
    }
}
```

### ActivityConflict

```swift
struct ActivityConflict {
    let activity1: Activity
    let activity2: Activity
    let conflictType: ConflictType
    let resolution: ConflictResolution?
    
    enum ConflictType {
        case exactDuplicate        // Same start time, duration, distance
        case likelyDuplicate       // Within tolerance
        case possibleDuplicate     // Similar but uncertain
    }
    
    enum ConflictResolution {
        case keepFirst
        case keepSecond
        case merge
        case keepBoth
    }
}
```

### FITRetryItem

```swift
struct FITRetryItem: Codable {
    let activityId: String
    let fitURL: String
    let attemptCount: Int
    let lastAttempt: Date
    let error: String
    let maxRetries: Int = 3
    
    var shouldRetry: Bool {
        attemptCount < maxRetries && Date().timeIntervalSince(lastAttempt) > 300
    }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Authentication precedes sync

*For any* sync operation, authentication must be valid before the sync begins, and if authentication fails during sync, the sync must pause until re-authentication succeeds.
**Validates: Requirements 1.1, 1.2**

### Property 2: Multi-source sync isolation

*For any* concurrent sync operations from different sources (Strava, iGPSport), the operations must not interfere with each other's progress or state.
**Validates: Requirements 2.1**

### Property 3: Duplicate detection consistency

*For any* set of activities synced from multiple sources, activities with matching start times (within tolerance) and durations must be identified as duplicates.
**Validates: Requirements 2.2, 5.1**

### Property 4: Retry exhaustion

*For any* failed operation, after the maximum retry attempts are exhausted, the operation must be marked as failed and not retried automatically.
**Validates: Requirements 3.3, 3.5**

### Property 5: Progress monotonicity

*For any* sync operation, the progress percentage must never decrease (must be monotonically increasing from 0.0 to 1.0).
**Validates: Requirements 4.1, 4.2**

### Property 6: Transaction atomicity

*For any* database operation during sync, either all changes for an activity are saved or none are saved (no partial updates).
**Validates: Requirements 5.4**

### Property 7: FIT file and activity consistency

*For any* activity with a FIT file, if the activity exists in the database, the corresponding FIT file must exist in storage, and vice versa.
**Validates: Requirements 7.1, 7.2, 7.4**

### Property 8: Background sync resource limits

*For any* background sync operation, the number of activities processed must not exceed the configured limit for background operations.
**Validates: Requirements 6.3, 10.1**

### Property 9: Sync cancellation cleanup

*For any* cancelled sync operation, all temporary resources must be released and no partial data must remain in an inconsistent state.
**Validates: Requirements 2.5, 10.4**

### Property 10: Configuration change propagation

*For any* configuration change (auto-sync interval, date range), the change must be applied to all future sync operations without requiring app restart.
**Validates: Requirements 8.1, 8.2**

## Error Handling

### Error Hierarchy

```swift
enum IntegrationError: LocalizedError {
    // Authentication integration errors
    case authenticationRequired
    case sessionExpiredDuringSync
    case authenticationFailedAfterRetry
    
    // Coordination errors
    case syncAlreadyInProgress
    case conflictingOperations
    case coordinatorNotInitialized
    
    // Data consistency errors
    case duplicateDetectionFailed
    case conflictResolutionFailed
    case transactionFailed(underlying: Error)
    
    // Resource errors
    case insufficientStorage
    case memoryPressure
    case networkUnavailable
    
    var errorDescription: String? {
        // Detailed user-friendly messages
    }
    
    var recoverySuggestion: String? {
        // Actionable guidance for users
    }
}
```

### Error Recovery Strategies

1. **Authentication Errors**:
   ```
   Session Expired → Attempt Auto-Refresh → Success? → Resume Sync
                                          → Failure? → Prompt User → Retry
   ```

2. **Network Errors**:
   ```
   Network Failure → Retry (3x with backoff) → Success? → Continue
                                              → Failure? → Save Checkpoint → Notify User
   ```

3. **Data Conflicts**:
   ```
   Duplicate Found → Analyze Completeness → Auto-Resolve? → Merge
                                          → Uncertain? → Log for Review
   ```

4. **Resource Constraints**:
   ```
   Low Memory → Pause Sync → Release Resources → Wait → Resume
   Low Storage → Warn User → Cleanup Old Files → Continue if space available
   ```

## Testing Strategy

### Unit Tests

1. **SyncCoordinator Tests**:
   - Test multi-source sync coordination
   - Test duplicate detection logic
   - Test conflict resolution strategies
   - Test pause/resume functionality
   - Test cancellation cleanup

2. **Integration Flow Tests**:
   - Test auth-to-sync handoff
   - Test session expiration during sync
   - Test automatic re-authentication
   - Test sync checkpoint creation and restoration

3. **FITFileManager Tests**:
   - Test file storage and retrieval
   - Test orphaned file cleanup
   - Test retry queue management
   - Test storage limit enforcement

### Integration Tests

1. **End-to-End Sync Flow**:
   - Authenticate → Sync → Parse FIT → Store → Verify
   - Test with both Strava and iGPSport
   - Test with network interruptions
   - Test with authentication expiration

2. **Duplicate Handling**:
   - Sync same activity from two sources
   - Verify duplicate detection
   - Verify merge logic
   - Verify no data loss

3. **Error Recovery**:
   - Simulate various error conditions
   - Verify checkpoint creation
   - Verify resume from checkpoint
   - Verify retry queue processing

### Property-Based Tests

The property-based testing framework will be **swift-check** (Swift port of QuickCheck).

Each correctness property will be tested with at least 100 random test cases to ensure the properties hold across various inputs and scenarios.

## Implementation Notes

### Sync Coordination Algorithm

```swift
func syncAllServices() async throws {
    // 1. Validate prerequisites
    guard !isSyncing else { throw IntegrationError.syncAlreadyInProgress }
    
    // 2. Initialize sync session
    let session = SyncSession(source: .all)
    self.currentSession = session
    isSyncing = true
    syncProgress = 0.0
    
    // 3. Sync each source sequentially
    let sources: [(String, () async throws -> Void)] = [
        ("Strava", syncStrava),
        ("iGPSport", syncIGPSport)
    ]
    
    for (index, (name, syncFunc)) in sources.enumerated() {
        syncStatus = "Syncing \(name)..."
        
        do {
            try await syncFunc()
            syncProgress = Double(index + 1) / Double(sources.count)
        } catch {
            // Log error but continue with other sources
            session.errors.append(SyncError(source: name, error: error))
        }
    }
    
    // 4. Post-sync processing
    try await detectAndResolveDuplicates()
    try await cleanupOrphanedFiles()
    
    // 5. Finalize
    session.endTime = Date()
    session.status = session.errors.isEmpty ? .completed : .failed
    lastSyncDate = Date()
    isSyncing = false
}
```

### Duplicate Detection Algorithm

```swift
func detectDuplicateActivities(_ activities: [Activity]) -> [ActivityConflict] {
    var conflicts: [ActivityConflict] = []
    let tolerance: TimeInterval = 60 // 1 minute
    
    // Group activities by approximate start time
    let grouped = Dictionary(grouping: activities) { activity in
        Int(activity.startDate.timeIntervalSince1970 / 300) // 5-minute buckets
    }
    
    // Check each group for duplicates
    for (_, group) in grouped where group.count > 1 {
        for i in 0..<group.count {
            for j in (i+1)..<group.count {
                let a1 = group[i]
                let a2 = group[j]
                
                let timeDiff = abs(a1.startDate.timeIntervalSince(a2.startDate))
                let durationDiff = abs(a1.movingTime - a2.movingTime)
                
                if timeDiff < tolerance && durationDiff < tolerance {
                    let type: ActivityConflict.ConflictType
                    if timeDiff < 5 && durationDiff < 5 {
                        type = .exactDuplicate
                    } else if timeDiff < 30 && durationDiff < 30 {
                        type = .likelyDuplicate
                    } else {
                        type = .possibleDuplicate
                    }
                    
                    conflicts.append(ActivityConflict(
                        activity1: a1,
                        activity2: a2,
                        conflictType: type,
                        resolution: nil
                    ))
                }
            }
        }
    }
    
    return conflicts
}
```

### Background Sync Strategy

```swift
func performBackgroundSync() async throws {
    // Limit background sync to recent activities only
    let recentDays = 7
    let startDate = Calendar.current.date(byAdding: .day, value: -recentDays, to: Date())!
    
    // Use lower resource limits
    let maxActivities = 50
    let maxConcurrentDownloads = 1
    
    // Perform sync with limits
    try await igpsportSyncService.syncRecentActivities(
        days: recentDays,
        maxActivities: maxActivities,
        maxConcurrentDownloads: maxConcurrentDownloads
    )
}
```

## Performance Considerations

1. **Memory Management**:
   - Process activities in batches of 20
   - Release parsed FIT data after storing
   - Use autoreleasepool for batch operations

2. **Network Efficiency**:
   - Limit concurrent downloads to 3
   - Use HTTP/2 connection pooling
   - Compress request/response bodies

3. **Database Optimization**:
   - Use batch inserts for multiple activities
   - Create indexes on frequently queried fields
   - Use transactions for atomic updates

4. **Storage Management**:
   - Implement LRU cache for FIT files
   - Compress old FIT files
   - Auto-cleanup files older than 90 days

## Security Considerations

1. **Credential Protection**:
   - Store tokens in Keychain with appropriate access controls
   - Never log credentials or tokens
   - Clear credentials on logout

2. **Data Validation**:
   - Validate all API responses before processing
   - Sanitize file paths
   - Limit file sizes

3. **Network Security**:
   - Use HTTPS for all API requests
   - Validate SSL certificates
   - Implement certificate pinning for production

