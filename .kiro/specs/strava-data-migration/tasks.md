# Implementation Plan

- [x] 1. Set up project structure and core data models
  - Update existing SwiftData schema to support cycling activities
  - Create Activity, ActivityStreams, and analysis result models
  - Set up proper model relationships and constraints
  - _Requirements: 1.1, 2.1, 3.1, 8.1_

- [x] 2. Implement authentication and account management
  - [x] 2.1 Create Strava OAuth authentication flow
    - Implement StravaAuthManager with system browser authentication
    - Add secure token storage using macOS Keychain
    - Handle OAuth callback URL scheme registration
    - _Requirements: 1.1, 1.2, 1.3, 1.5_
  
  - [x] 2.2 Create iGPSport authentication system
    - Implement IGPSportAuthManager with username/password login
    - Add session management and token refresh capabilities
    - Store credentials securely in Keychain
    - _Requirements: 1.1, 1.2, 1.3_
  
  - [x] 2.3 Build unified account management UI
    - Create account settings view with multiple service support
    - Add logout and reconnection functionality
    - Implement account status indicators
    - _Requirements: 1.4_

- [x] 3. Create data synchronization services
  - [x] 3.1 Implement Strava API integration
    - Build StravaAPIService with activity fetching and pagination
    - Add stream data retrieval for power, heart rate, cadence, speed, elevation
    - Implement error handling and retry mechanisms
    - _Requirements: 2.1, 2.2, 2.4, 2.5_
  
  - [x] 3.2 Implement iGPSport API integration
    - Build IGPSportAPIService based on existing Python utilities
    - Add activity listing with pagination support
    - Implement FIT file download and parsing
    - _Requirements: 2.1, 2.2, 2.4, 2.5_
  
  - [x] 3.3 Create background synchronization system
    - Implement background sync using macOS background tasks
    - Add sync status tracking and conflict resolution
    - Create incremental sync to avoid duplicate downloads
    - _Requirements: 2.2, 2.5_

- [x] 4. Build file import system
  - [x] 4.1 Implement drag-and-drop file import
    - Create file drop zone UI component
    - Add support for GPX, TCX, and FIT file formats
    - Implement file validation and error reporting
    - _Requirements: 3.1, 3.3_
  
  - [x] 4.2 Create file parsing engines
    - Build GPX parser for activity data and GPS tracks
    - Implement TCX parser with heart rate and power support
    - Add FIT file parser using existing Swift FIT libraries
    - _Requirements: 3.2, 3.4_
  
  - [x] 4.3 Add batch import functionality
    - Support multiple file selection and processing
    - Implement import progress tracking
    - Add duplicate detection and handling
    - _Requirements: 3.5_

- [x] 5. Implement power analysis engine
  - [x] 5.1 Create core power metrics calculations
    - Implement eFTP estimation algorithms
    - Add Critical Power and W′ calculations
    - Build Normalized Power, Intensity Factor, and TSS calculations
    - _Requirements: 4.1, 4.2, 4.3_
  
  - [x] 5.2 Build advanced power analysis features
    - Implement Variability Index and Efficiency Factor
    - Create power zone distribution analysis
    - Add Mean Maximal Power curve generation
    - Calculate W′ balance throughout activities
    - _Requirements: 4.4, 4.5, 4.6_
  
  - [ ] 5.3 Write unit tests for power calculations
    - Test eFTP estimation with known datasets
    - Validate Critical Power calculations
    - Test MMP curve generation accuracy
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ] 6. Implement heart rate analysis engine
  - [ ] 6.1 Create heart rate zone analysis
    - Implement heart rate zone distribution calculations
    - Add custom zone configuration support
    - Build heart rate trend analysis
    - _Requirements: 5.1, 5.4, 5.5_
  
  - [ ] 6.2 Add advanced heart rate metrics
    - Implement hrTSS calculations
    - Create VO₂max estimation from HR and power data
    - Add recovery metrics and recommendations
    - _Requirements: 5.2, 5.3, 5.4_
  
  - [ ] 6.3 Write unit tests for heart rate analysis
    - Test zone distribution calculations
    - Validate hrTSS computation
    - Test VO₂max estimation accuracy
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 7. Build data visualization system
  - [x] 7.1 Create interactive activity charts
    - Implement power, heart rate, cadence, speed, and elevation stream charts
    - Add zoom, pan, and data point inspection capabilities
    - Create synchronized multi-stream chart views
    - _Requirements: 6.1, 6.4_
  
  - [ ] 7.2 Build analysis visualization components
    - Create power distribution histograms and zone charts
    - Implement Mean Maximal Power curve displays
    - Add training load trend charts
    - Build fitness progression visualizations
    - _Requirements: 6.2, 6.3, 6.4_
  
  - [ ] 7.3 Optimize chart performance
    - Implement data sampling for large datasets (>10k points)
    - Add chart caching for frequently viewed activities
    - Optimize rendering performance for smooth interactions
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ] 8. Implement AI analysis integration
  - [ ] 8.1 Create AI service integration
    - Build AIAnalysisService with configurable LLM providers
    - Implement activity data preprocessing for AI analysis
    - Add structured prompt generation for cycling-specific insights
    - _Requirements: 7.1, 7.2_
  
  - [ ] 8.2 Build training recommendation system
    - Generate personalized training recommendations
    - Implement performance trend analysis
    - Create recovery and training load suggestions
    - _Requirements: 7.3, 7.4_
  
  - [ ] 8.3 Add analysis result management
    - Cache AI analysis results to minimize API usage
    - Implement result formatting and display
    - Add analysis history and comparison features
    - _Requirements: 7.5_

- [ ] 9. Create activity browser and management UI
  - [x] 9.1 Build main activity list view
    - Create searchable and filterable activity list
    - Implement sorting by date, distance, duration, and other metrics
    - Add activity selection for batch operations
    - _Requirements: 8.1, 8.2, 8.3_
  
  - [x] 9.2 Create detailed activity view
    - Build comprehensive activity detail screens
    - Display all calculated metrics and analysis results
    - Integrate chart visualizations and AI insights
    - _Requirements: 8.4_
  
  - [x] 9.3 Add activity management features
    - Implement activity source identification (Strava, iGPSport, local files)
    - Add activity editing and annotation capabilities
    - Create activity export and sharing options
    - _Requirements: 8.5, 9.8_

- [x] 10. Implement offline functionality and data management
  - [x] 10.1 Create robust local data storage
    - Implement comprehensive SwiftData persistence
    - Add data integrity checks and migration support
    - Create efficient data indexing for sea.rch and filtering
    - _Requirements: 9.1, 9.5_
  
  - [x] 10.2 Build offline analysis capabilities
    - Ensure all analysis engines work with cached data
    - Implement offline AI analysis result display
    - Add data freshness indicators and sync status
    - _Requirements: 9.2, 9.3_
  
  - [x] 10.3 Create data synchronization management
    - Implement automatic sync when connectivity is restored
    - Add manual sync triggers and progress indicators
    - Handle sync conflicts and error recovery
    - _Requirements: 9.4, 9.5_

- [ ] 11. Add user preferences and settings
  - [x] 11.1 Create user profile management
    - Build user profile setup with weight, FTP, heart rate zones
    - Add power zone configuration based on FTP
    - Implement custom analysis preferences
    - _Requirements: 4.1, 4.4, 5.1, 5.5_
  
  - [x] 11.2 Add application settings
    - Create sync preferences and scheduling options
    - Add data export and privacy controls
    - Implement theme and display preferences
    - _Requirements: 2.2, 9.4_

- [ ] 12. Polish UI and add final integrations
  - [x] 12.1 Implement macOS-specific UI enhancements
    - Add proper menu bar integration
    - Implement keyboard shortcuts and accessibility features
    - Create native macOS window management
    - _Requirements: All UI-related requirements_
  
  - [x] 12.2 Add error handling and user feedback
    - Implement comprehensive error handling throughout the app
    - Add user-friendly error messages and recovery options
    - Create loading states and progress indicators
    - _Requirements: 2.5, 3.3, 7.5, 9.5_
  
  - [x] 12.3 Create comprehensive integration tests
    - Test complete workflows from authentication to analysis
    - Validate data synchronization scenarios
    - Test offline/online transitions
    - _Requirements: All requirements_