# Design Document

## Overview

This design addresses the iGPSport data synchronization and FIT file parsing issues by improving error handling, enhancing the FIT parser to extract more data, and providing better user feedback during sync operations.

## Architecture

### Component Interaction

```
User Interface (SettingsView/SyncButtons)
    ↓
SyncCoordinator
    ↓
IGPSportSyncService
    ↓ ↓
    ↓ IGPSportAPIService → iGPSport API
    ↓
FITParser → ActivityStreams
    ↓
DataRepository → SwiftData
```

## Components and Interfaces

### 1. IGPSportAPIService Enhancements

**Current Issues:**
- Limited error context in API responses
- No validation of response data structure
- Missing detailed logging for debugging

**Design Changes:**
- Add response validation before decoding
- Log raw JSON responses when decoding fails
- Provide detailed error messages with HTTP status codes
- Add request/response logging for debugging

**Interface:**
```swift
class IGPSportAPIService {
    func fetchActivities(page: Int, pageSize: Int) async throws -> [IGPSportActivity]
    func fetchActivityDetail(rideId: Int) async throws -> IGPSportActivityDetail
    func downloadFITFile(from urlString: String) async throws -> Data
    
    // New methods
    func validateFITFileURL(_ urlString: String?) -> String?
    private func logAPIError(_ error: Error, context: String)
}
```

### 2. FIT Parser Improvements

**Current Issues:**
- Only extracts session-level data
- Doesn't parse record messages (time-series data)
- Missing power data extraction
- No validation of parsed values

**Design Changes:**
- Parse record messages to extract time-series data
- Extract GPS coordinates, power, and temperature data
- Validate parsed values against reasonable ranges
- Create ActivityStreams from parsed records

**Interface:**
```swift
class FITParser {
    func parse(data: Data) throws -> FITData
    func parseToActivityStreams(data: Data) throws -> ActivityStreams
    
    // New methods
    private func parseRecordMessage(fields: [UInt8: Any]) -> FITRecord?
    private func validateFITData(_ data: FITData) -> Bool
    private func convertToActivityStreams(_ fitData: FITData) -> ActivityStreams
}
```

### 3. IGPSportSyncService Enhancements

**Current Issues:**
- FIT files are downloaded but not parsed
- No progress tracking for individual activities
- Limited error recovery
- No sync statistics

**Design Changes:**
- Parse FIT files immediately after download
- Store both raw FIT files and parsed ActivityStreams
- Track sync statistics (success/failure counts)
- Provide detailed progress updates
- Implement better error recovery

**Interface:**
```swift
class IGPSportSyncService {
    @Published var syncProgress: Double
    @Published var syncStatus: String
    @Published var syncStatistics: SyncStatistics
    
    func syncAllActivities(maxPages: Int) async throws
    func syncRecentActivities(days: Int) async throws
    
    // Enhanced methods
    private func syncSingleActivity(_ igpsActivity: IGPSportActivity) async throws
    private func downloadAndParseFIT(for activity: Activity, fitURL: String) async throws
    private func updateSyncStatistics(success: Bool, activityId: String)
}

struct SyncStatistics {
    var totalActivities: Int
    var successCount: Int
    var failureCount: Int
    var fitFilesDownloaded: Int
    var fitFilesParsed: Int
}
```

## Data Models

### Enhanced FITData Structure

```swift
struct FITData {
    // Session-level data
    var activityName: String?
    var startTime: Date?
    var totalDistance: Double
    var totalTime: TimeInterval
    var totalAscent: Double
    var totalDescent: Double?
    var averageSpeed: Double?
    var maxSpeed: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averageCadence: Double?
    var maxCadence: Double?
    var averagePower: Double?
    var maxPower: Double?
    var normalizedPower: Double?
    var calories: Int?
    
    // Time-series data
    var records: [FITRecord]
    
    // Validation
    func isValid() -> Bool
}

struct FITRecord {
    var timestamp: TimeInterval
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var speed: Double?
    var distance: Double?
    var heartRate: Int?
    var cadence: Int?
    var power: Int?
    var temperature: Double?
}
```

### ActivityStreams Integration

```swift
extension FITParser {
    func convertToActivityStreams(_ fitData: FITData, activityId: String) -> ActivityStreams {
        let streams = ActivityStreams(activityId: activityId)
        
        // Convert FITRecords to stream arrays
        streams.time = fitData.records.map { $0.timestamp }
        streams.distance = fitData.records.compactMap { $0.distance }
        streams.altitude = fitData.records.compactMap { $0.altitude }
        streams.velocity_smooth = fitData.records.compactMap { $0.speed }
        streams.heartrate = fitData.records.compactMap { $0.heartRate }.map { Double($0) }
        streams.cadence = fitData.records.compactMap { $0.cadence }.map { Double($0) }
        streams.watts = fitData.records.compactMap { $0.power }.map { Double($0) }
        streams.temp = fitData.records.compactMap { $0.temperature }
        
        // Create LatLng array for map display
        streams.latlng = fitData.records.compactMap { record in
            guard let lat = record.latitude, let lng = record.longitude else { return nil }
            return LatLng(latitude: lat, longitude: lng)
        }
        
        return streams
    }
}
```

## Error Handling

### Error Types

```swift
enum IGPSportSyncError: LocalizedError {
    case authenticationFailed(String)
    case networkError(String)
    case apiError(statusCode: Int, message: String)
    case invalidResponse(String)
    case fitFileDownloadFailed(activityId: String, reason: String)
    case fitParseError(activityId: String, reason: String)
    case dataStorageError(String)
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let msg):
            return "Authentication failed: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .apiError(let code, let msg):
            return "API error (\(code)): \(msg)"
        case .invalidResponse(let msg):
            return "Invalid response: \(msg)"
        case .fitFileDownloadFailed(let id, let reason):
            return "Failed to download FIT file for activity \(id): \(reason)"
        case .fitParseError(let id, let reason):
            return "Failed to parse FIT file for activity \(id): \(reason)"
        case .dataStorageError(let msg):
            return "Data storage error: \(msg)"
        }
    }
}
```

### Error Recovery Strategy

1. **Network Errors**: Retry up to 3 times with exponential backoff
2. **API Errors**: 
   - 401: Re-authenticate and retry once
   - 429: Wait and retry with longer delay
   - 5xx: Retry with backoff
   - 4xx (except 401, 429): Log and skip
3. **FIT Parse Errors**: Log error, save raw file, continue with next activity
4. **Storage Errors**: Log error, attempt to free space, retry once

## Testing Strategy

### Unit Tests

1. **FIT Parser Tests**
   - Test parsing valid FIT files with various data combinations
   - Test handling of corrupted FIT files
   - Test extraction of all metric types
   - Test conversion to ActivityStreams

2. **API Service Tests**
   - Test response validation
   - Test error handling for various HTTP status codes
   - Test retry logic
   - Test FIT URL validation

3. **Sync Service Tests**
   - Test sync statistics tracking
   - Test progress updates
   - Test error recovery
   - Test partial sync completion

### Integration Tests

1. Test end-to-end sync with mock iGPSport API
2. Test FIT file download and parsing pipeline
3. Test data persistence after sync
4. Test sync cancellation

### Manual Testing

1. Sync activities from real iGPSport account
2. Verify all metrics are correctly displayed
3. Test sync with poor network conditions
4. Verify error messages are user-friendly
5. Test sync progress indicators

## Implementation Notes

### FIT File Format Details

The FIT file format uses a binary structure with:
- 14-byte header with ".FIT" signature
- Definition messages that describe data structure
- Data messages containing actual values
- 2-byte CRC at the end

Key message types:
- Message 0: File ID
- Message 18: Session (summary data)
- Message 19: Lap
- Message 20: Record (time-series data points)

### Field Definitions for Record Messages

```swift
// Record message field numbers
private let recordTimestampField: UInt8 = 253
private let recordPositionLatField: UInt8 = 0
private let recordPositionLongField: UInt8 = 1
private let recordAltitudeField: UInt8 = 2
private let recordHeartRateField: UInt8 = 3
private let recordCadenceField: UInt8 = 4
private let recordDistanceField: UInt8 = 5
private let recordSpeedField: UInt8 = 6
private let recordPowerField: UInt8 = 7
private let recordTemperatureField: UInt8 = 13
```

### Coordinate Conversion

FIT files store GPS coordinates as semicircles (2^31 semicircles = 180 degrees):
```swift
func semicirclesToDegrees(_ semicircles: Int32) -> Double {
    return Double(semicircles) * (180.0 / pow(2.0, 31))
}
```

## Performance Considerations

1. **Memory Management**: Parse FIT files in streaming fashion for large files
2. **Batch Processing**: Process activities in batches to avoid memory spikes
3. **Background Processing**: Perform sync operations on background thread
4. **Rate Limiting**: Respect iGPSport API rate limits (600ms between requests)
5. **Caching**: Cache parsed FIT data to avoid re-parsing

## Security Considerations

1. Validate all data from iGPSport API before processing
2. Sanitize file paths when storing FIT files
3. Limit FIT file size to prevent DoS (max 50MB)
4. Validate FIT file headers before parsing
5. Use secure HTTPS for all API requests
