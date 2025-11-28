# Implementation Plan

- [x] 1. Enhance FIT Parser to extract time-series data
  - Add field definitions for record messages (timestamp, GPS, heart rate, power, etc.)
  - Implement parseRecordMessage method to extract individual data points
  - Store parsed records in FITData.records array
  - Add coordinate conversion from semicircles to degrees for GPS data
  - _Requirements: 3.1, 3.2, 3.3_

- [ ] 2. Add FIT data validation and error handling
  - Implement validateFITData method to check for reasonable value ranges
  - Add detailed error messages for parse failures
  - Handle corrupted or incomplete FIT files gracefully
  - Log parse errors with file context (size, header info)
  - _Requirements: 3.4, 4.2_

- [ ] 3. Implement ActivityStreams conversion from FIT data
  - Create convertToActivityStreams method in FITParser
  - Map FIT records to ActivityStreams time-series arrays
  - Convert GPS coordinates to LatLng objects for map display
  - Handle missing or sparse data points appropriately
  - _Requirements: 3.5_

- [ ] 4. Add comprehensive logging to IGPSportAPIService
  - Log API requests with URL and parameters
  - Log raw JSON responses when decoding fails
  - Add context to error messages (activity ID, request type)
  - Implement logAPIError helper method
  - _Requirements: 4.1, 4.4_

- [ ] 5. Enhance IGPSportSyncService with FIT parsing integration
  - Modify syncSingleActivity to parse FIT files after download
  - Create downloadAndParseFIT method
  - Store both raw FIT files and parsed ActivityStreams
  - Link ActivityStreams to Activity via relationship
  - _Requirements: 2.1, 2.2, 2.4, 3.5_

- [ ] 6. Implement sync statistics tracking
  - Create SyncStatistics struct with success/failure counters
  - Add @Published syncStatistics property to IGPSportSyncService
  - Update statistics after each activity sync attempt
  - Log summary statistics when sync completes
  - _Requirements: 4.3, 5.3_

- [ ] 7. Improve sync progress and status updates
  - Update syncStatus with descriptive messages for each sync phase
  - Show current activity being processed in status
  - Update progress based on activities processed and FIT files downloaded
  - Display final success message with statistics
  - _Requirements: 5.1, 5.2, 5.3, 5.5_

- [ ] 8. Add better error handling and user feedback
  - Create IGPSportSyncError enum with specific error cases
  - Display user-friendly error messages in UI
  - Provide actionable guidance for common errors
  - Continue sync after non-fatal errors (FIT parse failures)
  - _Requirements: 1.3, 4.1, 5.4_

- [ ] 9. Validate and improve FIT URL handling
  - Implement validateFITFileURL method to check all possible field names
  - Add priority order for checking FIT URL fields
  - Log which field was used when FIT URL is found
  - Handle cases where no FIT URL is available
  - _Requirements: 2.5_

- [ ]* 10. Add unit tests for FIT parser enhancements
  - Test parsing of record messages with various data combinations
  - Test coordinate conversion from semicircles to degrees
  - Test handling of corrupted FIT files
  - Test ActivityStreams conversion
  - _Requirements: 3.1, 3.2, 3.3, 3.4_

- [ ]* 11. Add integration tests for sync pipeline
  - Test end-to-end sync with mock API responses
  - Test FIT file download and parsing flow
  - Test error recovery and retry logic
  - Test sync statistics accuracy
  - _Requirements: 1.1, 1.4, 2.1, 2.3_
