//
//  FileParsingService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation

class FileParsingService {
    
    // MARK: - GPX Parsing
    
    func parseGPXFile(from url: URL) throws -> (Activity, ActivityStreams?) {
        let data = try Data(contentsOf: url)
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        
        // Basic GPX parsing (simplified - full implementation would use XMLParser)
        let activity = Activity(
            name: extractGPXName(from: xmlString) ?? url.deletingPathExtension().lastPathComponent,
            startDate: extractGPXStartDate(from: xmlString) ?? Date(),
            distance: 0, // Would be calculated from trackpoints
            duration: 0, // Would be calculated from timestamps
            elevationGain: 0, // Would be calculated from elevation data
            source: .gpx
        )
        
        // TODO: Implement full GPX parsing with XMLParser
        // Parse trackpoints, calculate distance, duration, elevation
        // Extract GPS coordinates, elevation, heart rate (if available)
        
        return (activity, nil)
    }
    
    private func extractGPXName(from xml: String) -> String? {
        // Simple regex to extract name from GPX
        if let range = xml.range(of: "<name>(.*?)</name>", options: .regularExpression) {
            let nameTag = String(xml[range])
            return nameTag.replacingOccurrences(of: "<name>", with: "")
                .replacingOccurrences(of: "</name>", with: "")
        }
        return nil
    }
    
    private func extractGPXStartDate(from xml: String) -> Date? {
        // Simple regex to extract first time from GPX
        if let range = xml.range(of: "<time>(.*?)</time>", options: .regularExpression) {
            let timeTag = String(xml[range])
            let timeString = timeTag.replacingOccurrences(of: "<time>", with: "")
                .replacingOccurrences(of: "</time>", with: "")
            return ISO8601DateFormatter().date(from: timeString)
        }
        return nil
    }
    
    // MARK: - TCX Parsing
    
    func parseTCXFile(from url: URL) throws -> (Activity, ActivityStreams?) {
        let data = try Data(contentsOf: url)
        let xmlString = String(data: data, encoding: .utf8) ?? ""
        
        // Basic TCX parsing (simplified - full implementation would use XMLParser)
        let activity = Activity(
            name: extractTCXName(from: xmlString) ?? url.deletingPathExtension().lastPathComponent,
            startDate: extractTCXStartDate(from: xmlString) ?? Date(),
            distance: extractTCXDistance(from: xmlString),
            duration: extractTCXDuration(from: xmlString),
            elevationGain: 0, // Would be calculated from trackpoints
            source: .tcx
        )
        
        // TODO: Implement full TCX parsing with XMLParser
        // Parse trackpoints with heart rate, cadence, power data
        // Extract all available metrics
        
        return (activity, nil)
    }
    
    private func extractTCXName(from xml: String) -> String? {
        if let range = xml.range(of: "<Notes>(.*?)</Notes>", options: .regularExpression) {
            let notesTag = String(xml[range])
            return notesTag.replacingOccurrences(of: "<Notes>", with: "")
                .replacingOccurrences(of: "</Notes>", with: "")
        }
        return nil
    }
    
    private func extractTCXStartDate(from xml: String) -> Date? {
        if let range = xml.range(of: "<Id>(.*?)</Id>", options: .regularExpression) {
            let idTag = String(xml[range])
            let dateString = idTag.replacingOccurrences(of: "<Id>", with: "")
                .replacingOccurrences(of: "</Id>", with: "")
            return ISO8601DateFormatter().date(from: dateString)
        }
        return nil
    }
    
    private func extractTCXDistance(from xml: String) -> Double {
        if let range = xml.range(of: "<DistanceMeters>(.*?)</DistanceMeters>", options: .regularExpression) {
            let distanceTag = String(xml[range])
            let distanceString = distanceTag.replacingOccurrences(of: "<DistanceMeters>", with: "")
                .replacingOccurrences(of: "</DistanceMeters>", with: "")
            return Double(distanceString) ?? 0
        }
        return 0
    }
    
    private func extractTCXDuration(from xml: String) -> TimeInterval {
        if let range = xml.range(of: "<TotalTimeSeconds>(.*?)</TotalTimeSeconds>", options: .regularExpression) {
            let durationTag = String(xml[range])
            let durationString = durationTag.replacingOccurrences(of: "<TotalTimeSeconds>", with: "")
                .replacingOccurrences(of: "</TotalTimeSeconds>", with: "")
            return Double(durationString) ?? 0
        }
        return 0
    }
    
    // MARK: - FIT Parsing
    
    func parseFITFile(from url: URL) throws -> (Activity, ActivityStreams?) {
        let data = try Data(contentsOf: url)
        
        // Parse FIT file
        let fitParser = FITParser()
        let fitData = try fitParser.parse(data: data)
        
        // Create activity from FIT data
        let activity = Activity(
            name: fitData.activityName ?? url.deletingPathExtension().lastPathComponent,
            startDate: fitData.startTime ?? Date(),
            distance: fitData.totalDistance,
            duration: fitData.totalTime,
            elevationGain: fitData.totalAscent,
            source: .fit
        )
        
        // Create activity streams if we have record data
        // Note: For now, we skip creating streams to avoid memory issues
        // TODO: Implement streaming/chunked processing for large FIT files
        var activityStreams: ActivityStreams? = nil
        if !fitData.records.isEmpty && fitData.records.count < 20000 {
            let baseTimestamp = fitData.records.first?.timestamp
                ?? fitData.startTime?.timeIntervalSince1970
                ?? fitData.records.first?.timestamp ?? 0
            
            var timeOffsets: [Double] = []
            var powerSamples: [Double?] = []
            var heartRateSamples: [Int?] = []
            var cadenceSamples: [Int?] = []
            var speedSamples: [Double?] = []
            var elevationSamples: [Double?] = []
            var latLngSamples: [LatLng] = []
            
            for record in fitData.records {
                let relativeTime = record.timestamp - baseTimestamp
                timeOffsets.append(relativeTime)
                
                powerSamples.append(record.power.map { Double($0) } ?? 0)
                heartRateSamples.append(record.heartRate ?? 0)
                cadenceSamples.append(record.cadence ?? 0)
                speedSamples.append(record.speed ?? 0)
                elevationSamples.append(record.altitude ?? 0)
                
                if let lat = record.latitude,
                   let lon = record.longitude {
                    latLngSamples.append(LatLng(latitude: lat, longitude: lon))
                }
            }
            
            func sanitizedStream<T>(_ samples: [T?]) -> [T?]? {
                samples.isEmpty ? nil : samples
            }
            
            activityStreams = ActivityStreams(
                activityId: activity.id,
                timeData: timeOffsets,
                powerData: sanitizedStream(powerSamples),
                heartRateData: sanitizedStream(heartRateSamples),
                cadenceData: sanitizedStream(cadenceSamples),
                speedData: sanitizedStream(speedSamples),
                elevationData: sanitizedStream(elevationSamples),
                latLngData: latLngSamples.isEmpty ? nil : latLngSamples
            )
        }
        
        return (activity, activityStreams)
    }
    
    // MARK: - Utility Methods
    
    func validateFileFormat(url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        return ["gpx", "tcx", "fit"].contains(fileExtension)
    }
    
    func detectFileFormat(url: URL) -> ActivitySource? {
        let fileExtension = url.pathExtension.lowercased()
        switch fileExtension {
        case "gpx": return .gpx
        case "tcx": return .tcx
        case "fit": return .fit
        default: return nil
        }
    }
}
