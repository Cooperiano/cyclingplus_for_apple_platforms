# Implementation Plan

- [ ] 1. Enhance SyncCoordinator for multi-source coordination
  - Create enhanced SyncCoordinator with state management for multi-source sync
  - Add properties for tracking sync progress, status, and statistics
  - Implement activeSyncTasks dictionary for managing concurrent operations
  - _Requirements: 2.1, 2.3, 2.4_

- [ ] 1.1 Write property test for multi-source sync isolation
  - **Property 2: Multi-source sync isolation**
  - **Validates: Requirements 2.1**

- [ ] 1.2 Implement syncAllServices method with sequential source processing
  - Add logic to sync Strava and iGPSport sequentially
  - Implement error collection without stopping other sources
  - Update progress based on completed sources
  - _Requirements: 2.1, 2.3_

- [ ] 1.3 Add pause, resume, and cancel functionality
  - Implement pauseSync() to suspend active operations
  - Implement resumeSync() to continue from checkpoint
  - Implement cancelAllSyncs() with cleanup
  - _Requirements: 2.5_

- [ ] 1.4 Write property test for sync cancellation cleanup
  - **Property 9: Sync cancellation cleanup**
  - **Validates: Requirements 2.5, 10.4**

- [ ] 2. Implement duplicate detection and conflict resolution
  - Create ActivityConflict model with conflict types
  - Implement detectDuplicateActivities algorithm
  - Add time-based grouping and comparison logic
  - _Requirements: 2.2, 5.1, 5.3_

- [ ] 2.1 Write property test for duplicate detection consistency
  - **Property 3: Duplicate detection consistency**
  - **Validates: Requirements 2.2, 5.1**

- [ ] 2.2 Implement conflict resolution strategies
  - Add resolveDuplicates method with merge logic
  - Implement automatic resolution for exact duplicates
  - Add logging for uncertain conflicts
  - _Requirements: 5.1, 5.3_

- [ ] 2.3 Integrate duplicate detection into sync flow
  - Call detectAndResolveDuplicates after each source sync
  - Update sync statistics with duplicate counts
  - Preserve user modifications during merge
  - _Requirements: 2.2, 5.2_

- [ ] 3. Enhance IGPSportAuthManager for sync integration
  - Add SessionStatus enum and published property
  - Implement validateSession method
  - Add refreshSessionIfNeeded for automatic refresh
  - _Requirements: 1.2, 1.5_

- [ ] 3.1 Write property test for authentication precedes sync
  - **Property 1: Authentication precedes sync**
  - **Validates: Requirements 1.1, 1.2**

- [ ] 3.2 Implement prepareForSync method
  - Validate session before returning credentials
  - Automatically refresh if expired
  - Throw clear error if authentication fails
  - _Requirements: 1.1, 1.2_

- [ ] 3.3 Add sync lifecycle notifications
  - Implement notifySyncStarted and notifySyncCompleted
  - Track sync sessions for session management
  - Update session check timestamp
  - _Requirements: 1.2_

- [ ] 4. Enhance IGPSportSyncService with progress tracking
  - Add detailed progress properties (currentActivity, activitiesProcessed, etc.)
  - Create SyncSession model for tracking sync state
  - Implement SyncCheckpoint for resume capability
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 4.1 Write property test for progress monotonicity
  - **Property 5: Progress monotonicity**
  - **Validates: Requirements 4.1, 4.2**

- [ ] 4.2 Implement updateProgress method
  - Calculate progress based on phase and items processed
  - Update syncProgress and syncStatus properties
  - Emit progress updates to SyncCoordinator
  - _Requirements: 4.1, 4.2_

- [ ] 4.3 Add checkpoint creation and restoration
  - Create checkpoint after each batch of activities
  - Store checkpoint with session ID and current state
  - Implement resumeFromCheckpoint method
  - _Requirements: 3.4_

- [ ] 4.4 Implement retry queue for failed items
  - Add pendingRetries array to track failed operations
  - Create retryFailedItems method
  - Implement exponential backoff for retries
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] 4.5 Write property test for retry exhaustion
  - **Property 4: Retry exhaustion**
  - **Validates: Requirements 3.3, 3.5**

- [ ] 5. Create FITFileManager component
  - Create new FITFileManager class
  - Implement file storage methods (save, get, delete)
  - Set up FITFiles directory structure
  - _Requirements: 7.1, 7.2, 7.4_

- [ ] 5.1 Write property test for FIT file and activity consistency
  - **Property 7: FIT file and activity consistency**
  - **Validates: Requirements 7.1, 7.2, 7.4**

- [ ] 5.2 Implement FIT file parsing coordination
  - Add parseAndStore method that calls FITParser
  - Create ActivityStreams and link to Activity
  - Handle parse errors gracefully
  - _Requirements: 7.2, 7.3_

- [ ] 5.3 Add FIT file validation and retry queue
  - Implement validateFITFile for header checking
  - Create retry queue for failed parses
  - Add processRetryQueue method
  - _Requirements: 7.3, 7.5_

- [ ] 5.4 Implement cleanup and storage management
  - Add cleanupOrphanedFiles method
  - Implement getTotalStorageUsed
  - Add automatic cleanup of old files
  - _Requirements: 7.4_

- [ ] 6. Enhance DataRepository with transaction support
  - Add performTransaction method with ModelContext
  - Implement batch save and update methods
  - Add rollback on error
  - _Requirements: 5.4, 5.5_

- [ ] 6.1 Write property test for transaction atomicity
  - **Property 6: Transaction atomicity**
  - **Validates: Requirements 5.4**

- [ ] 6.2 Implement duplicate detection queries
  - Add findDuplicateActivities method
  - Create indexes on startDate and duration
  - Optimize query performance
  - _Requirements: 2.2, 5.1_

- [ ] 6.3 Add activity merge functionality
  - Implement mergeActivities method
  - Preserve most complete data from both activities
  - Update relationships (ActivityStreams, analyses)
  - _Requirements: 5.3_

- [ ] 7. Implement background sync functionality
  - Add performBackgroundSync method to SyncCoordinator
  - Implement resource limits for background operations
  - Add scheduleNextBackgroundSync with timer
  - _Requirements: 6.1, 6.2, 6.3_

- [ ] 7.1 Write property test for background sync resource limits
  - **Property 8: Background sync resource limits**
  - **Validates: Requirements 6.3, 10.1**

- [ ] 7.2 Add app lifecycle management
  - Implement pause on background transition
  - Implement resume on foreground transition
  - Handle app termination during sync
  - _Requirements: 6.2_

- [ ] 7.3 Implement background sync notifications
  - Post notification when new activities found
  - Include activity count in notification
  - Respect user notification preferences
  - _Requirements: 6.5_

- [ ] 8. Add settings and configuration management
  - Create SyncPreferences model
  - Implement configuration change observers
  - Add immediate application of setting changes
  - _Requirements: 8.1, 8.2, 8.3_

- [ ] 8.1 Write property test for configuration change propagation
  - **Property 10: Configuration change propagation**
  - **Validates: Requirements 8.1, 8.2**

- [ ] 8.2 Implement date range filtering
  - Add date range parameters to sync methods
  - Filter activities based on start date
  - Stop pagination when outside range
  - _Requirements: 8.3_

- [ ] 8.3 Add data clearing functionality
  - Implement clearSyncData method
  - Remove activities and FIT files
  - Preserve authentication credentials
  - _Requirements: 8.4_

- [ ] 8.4 Implement full reset functionality
  - Add resetApp method
  - Clear all data including credentials
  - Reset all preferences to defaults
  - _Requirements: 8.5_

- [ ] 9. Implement comprehensive logging and diagnostics
  - Create SyncLogger utility class
  - Add structured logging for all operations
  - Implement log levels (debug, info, warning, error)
  - _Requirements: 9.1, 9.2, 9.3, 9.4_

- [ ] 9.1 Add operation logging
  - Log sync session start, end, and duration
  - Log each activity processed with result
  - Log summary statistics at completion
  - _Requirements: 9.1, 9.4_

- [ ] 9.2 Add error logging with context
  - Log API errors with status codes and responses
  - Log FIT parse errors with file details
  - Include request details for debugging
  - _Requirements: 9.2, 9.3_

- [ ] 9.3 Implement debug mode
  - Add debug flag to enable verbose logging
  - Log full request/response bodies in debug mode
  - Add performance timing logs
  - _Requirements: 9.5_

- [ ] 10. Implement performance optimizations
  - Add batch processing with configurable batch size
  - Implement concurrent download limiting
  - Add memory pressure monitoring
  - _Requirements: 10.1, 10.2, 10.5_

- [ ] 10.1 Add resource management
  - Implement autoreleasepool for batch operations
  - Release temporary data after processing
  - Monitor and respond to memory warnings
  - _Requirements: 10.4, 10.5_

- [ ] 10.2 Implement network efficiency
  - Add metered connection detection
  - Warn user before large downloads on metered connection
  - Implement connection pooling
  - _Requirements: 10.3_

- [ ] 11. Update UI for integration features
  - Update SettingsView with new sync options
  - Add progress indicators for multi-source sync
  - Display sync statistics and history
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 11.1 Add sync status display
  - Show current operation and progress
  - Display activities processed count
  - Show FIT file download progress
  - _Requirements: 4.2, 4.5_

- [ ] 11.2 Implement error display and recovery
  - Show user-friendly error messages
  - Provide actionable recovery suggestions
  - Add retry button for failed operations
  - _Requirements: 4.4_

- [ ] 11.3 Add sync history view
  - Display past sync sessions
  - Show statistics for each session
  - Allow viewing errors from past syncs
  - _Requirements: 4.3_

- [ ] 12. Integration testing and validation
  - Test complete auth-to-sync flow
  - Test multi-source sync coordination
  - Test duplicate detection and resolution
  - _Requirements: All_

- [ ] 12.1 Write integration tests for end-to-end flow
  - Test authentication → sync → parse → store
  - Test with both Strava and iGPSport
  - Test error recovery scenarios

- [ ] 12.2 Write integration tests for duplicate handling
  - Sync same activity from two sources
  - Verify duplicate detection works
  - Verify merge preserves all data

- [ ] 13. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
