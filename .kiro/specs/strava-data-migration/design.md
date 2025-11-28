# Design Document

## Overview

This design document outlines the architecture and implementation approach for migrating CyclingPlus from Android to macOS. The app will be built using SwiftUI for the user interface and SwiftData for local data persistence, following Apple's recommended patterns for macOS applications.

## Architecture

### High-Level Architecture

The application follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
├─────────────────────────────────────────┤
│            ViewModels (MVVM)            │
├─────────────────────────────────────────┤
│              Services Layer             │
│  ┌─────────┬─────────┬─────────┬──────┐ │
│  │ Strava  │ AI      │ Power   │ File │ │
│  │ Service │ Service │ Analysis│Import│ │
│  └─────────┴─────────┴─────────┴──────┘ │
├─────────────────────────────────────────┤
│           Data Layer (SwiftData)        │
├─────────────────────────────────────────┤
│        External APIs & File System     │
└─────────────────────────────────────────┘
```

### Core Components

1. **Presentation Layer**: SwiftUI views with MVVM pattern
2. **Business Logic Layer**: Service classes handling domain logic
3. **Data Layer**: SwiftData models and repositories
4. **External Integration**: API clients and file system access

## Components and Interfaces

### 1. Authentication & Strava Integration

#### StravaAuthManager
```swift
class StravaAuthManager: ObservableObject {
    func authenticate() async throws -> StravaCredentials
    func refreshToken() async throws -> StravaCredentials
    func logout()
    var isAuthenticated: Bool { get }
}
```

#### StravaAPIService
```swift
class StravaAPIService {
    func fetchActivities(page: Int, perPage: Int) async throws -> [StravaActivity]
    func fetchActivityStreams(activityId: Int) async throws -> ActivityStreams
    func fetchAthleteProfile() async throws -> StravaAthlete
}
```

#### IGPSportAPIService
```swift
class IGPSportAPIService {
    func authenticate(username: String, password: String) async throws -> IGPSportCredentials
    func fetchActivities(page: Int, pageSize: Int) async throws -> [IGPSportActivity]
    func fetchActivityDetail(rideId: Int) async throws -> IGPSportActivityDetail
    func downloadFITFile(from url: String) async throws -> Data
}
```

### 2. Data Models

#### Core Activity Model
```swift
@Model
class Activity {
    var id: String
    var name: String
    var startDate: Date
    var distance: Double
    var duration: TimeInterval
    var elevationGain: Double
    var source: ActivitySource // .strava, .igpsport, .gpx, .tcx, .fit
    var stravaId: Int?
    var igpsportRideId: Int?
    
    // Relationships
    var streams: ActivityStreams?
    var powerAnalysis: PowerAnalysis?
    var heartRateAnalysis: HeartRateAnalysis?
    var aiAnalysis: AIAnalysis?
}
```

#### Stream Data Models
```swift
@Model
class ActivityStreams {
    var activityId: String
    var timeData: [Double]
    var powerData: [Double]?
    var heartRateData: [Int]?
    var cadenceData: [Int]?
    var speedData: [Double]?
    var elevationData: [Double]?
    var latLngData: [(Double, Double)]?
}
```

#### Analysis Models
```swift
@Model
class PowerAnalysis {
    var activityId: String
    var eFTP: Double?
    var criticalPower: Double?
    var wPrime: Double?
    var normalizedPower: Double?
    var intensityFactor: Double?
    var trainingStressScore: Double?
    var variabilityIndex: Double?
    var efficiencyFactor: Double?
    var powerZones: [PowerZoneData]
    var meanMaximalPower: [MMPPoint]
    var wPrimeBalance: [Double]?
}

@Model
class HeartRateAnalysis {
    var activityId: String
    var heartRateZones: [HRZoneData]
    var hrTSS: Double?
    var estimatedVO2Max: Double?
    var averageHR: Int?
    var maxHR: Int?
}
```

### 3. Analysis Services

#### PowerAnalysisService
```swift
class PowerAnalysisService {
    func calculatePowerMetrics(from streams: ActivityStreams) -> PowerAnalysis
    func estimateFTP(from activities: [Activity]) -> Double?
    func calculateCriticalPower(powerData: [Double], timeData: [Double]) -> (cp: Double, wPrime: Double)?
    func calculateMeanMaximalPower(powerData: [Double]) -> [MMPPoint]
    func calculateWPrimeBalance(powerData: [Double], cp: Double, wPrime: Double) -> [Double]
}
```

#### HeartRateAnalysisService
```swift
class HeartRateAnalysisService {
    func analyzeHeartRate(from streams: ActivityStreams, userProfile: UserProfile) -> HeartRateAnalysis
    func calculateHRTSS(hrData: [Int], duration: TimeInterval, lthr: Int) -> Double
    func estimateVO2Max(hrData: [Int], powerData: [Double]?, userProfile: UserProfile) -> Double?
}
```

### 4. File Import System

#### FileImportManager
```swift
class FileImportManager {
    func importGPXFile(url: URL) async throws -> Activity
    func importTCXFile(url: URL) async throws -> Activity
    func importFITFile(url: URL) async throws -> Activity
    func parseActivityStreams(from fileData: Data, format: FileFormat) throws -> ActivityStreams
    func validateFileFormat(url: URL) -> FileFormat?
}

enum FileFormat {
    case gpx, tcx, fit
}
```

### 5. AI Analysis Integration

#### AIAnalysisService
```swift
class AIAnalysisService {
    func analyzeActivity(_ activity: Activity) async throws -> AIAnalysis
    func generateTrainingRecommendations(activities: [Activity]) async throws -> TrainingRecommendations
    func analyzePerformanceTrends(activities: [Activity]) async throws -> PerformanceTrends
}
```

## Data Models

### SwiftData Schema

The application uses SwiftData for local persistence with the following model relationships:

```
Activity (1) ←→ (1) ActivityStreams
Activity (1) ←→ (0..1) PowerAnalysis  
Activity (1) ←→ (0..1) HeartRateAnalysis
Activity (1) ←→ (0..1) AIAnalysis
User (1) ←→ (*) Activity
User (1) ←→ (1) UserProfile
```

### User Profile Model
```swift
@Model
class UserProfile {
    var stravaId: Int?
    var name: String
    var weight: Double?
    var ftp: Double?
    var maxHeartRate: Int?
    var restingHeartRate: Int?
    var heartRateZones: [Int] // Zone boundaries
    var powerZones: [Double] // Zone boundaries based on FTP
    var preferences: UserPreferences
}
```

## Error Handling

### Error Types
```swift
enum CyclingPlusError: LocalizedError {
    case authenticationFailed
    case networkUnavailable
    case stravaAPIError(String)
    case fileImportError(String)
    case analysisError(String)
    case dataCorruption
    
    var errorDescription: String? {
        // Localized error messages
    }
}
```

### Error Handling Strategy
- Network errors: Retry with exponential backoff
- Authentication errors: Prompt for re-authentication
- File import errors: Show detailed validation messages
- Analysis errors: Allow retry with fallback to cached results

## Testing Strategy

### Unit Testing
- **Service Layer**: Mock external dependencies (Strava API, AI service)
- **Analysis Engines**: Test calculations with known datasets
- **Data Models**: Validate SwiftData relationships and constraints
- **File Import**: Test with sample GPX/TCX files

### Integration Testing
- **Strava Integration**: Test OAuth flow and API calls
- **File Import Pipeline**: End-to-end file processing
- **Data Synchronization**: Test offline/online scenarios

### UI Testing
- **Authentication Flow**: Test login/logout scenarios
- **Activity Browser**: Test filtering, sorting, and selection
- **Chart Interactions**: Test zoom, pan, and data inspection
- **File Import UI**: Test drag-and-drop functionality

## Performance Considerations

### Data Management
- **Lazy Loading**: Load activity streams only when needed
- **Pagination**: Implement efficient activity list pagination
- **Background Sync**: Use background tasks for Strava synchronization
- **Memory Management**: Dispose of large datasets when not in use

### Chart Rendering
- **Data Sampling**: Reduce data points for large activities (>10k points)
- **Virtualization**: Use efficient chart libraries with viewport culling
- **Caching**: Cache rendered chart images for frequently viewed activities

### Analysis Performance
- **Incremental Analysis**: Only recalculate when data changes
- **Background Processing**: Perform heavy calculations off main thread
- **Result Caching**: Store analysis results to avoid recomputation

## Security Considerations

### Authentication
- Store OAuth tokens in macOS Keychain
- Implement secure token refresh mechanism
- Support token revocation and cleanup

### Data Protection
- Encrypt sensitive user data at rest
- Implement secure file import validation
- Sanitize data before AI analysis submission

### Privacy
- Minimize data sent to external AI services
- Provide clear privacy controls and data export options
- Implement secure data deletion when user logs out