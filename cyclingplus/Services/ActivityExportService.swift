//
//  ActivityExportService.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import Foundation
import UniformTypeIdentifiers

/// Service for exporting activities to various file formats
class ActivityExportService {
    
    enum ExportFormat: String, CaseIterable {
        case gpx = "GPX"
        case tcx = "TCX"
        case json = "JSON"
        case csv = "CSV"
        
        var fileExtension: String {
            switch self {
            case .gpx: return "gpx"
            case .tcx: return "tcx"
            case .json: return "json"
            case .csv: return "csv"
            }
        }
        
        var utType: UTType {
            switch self {
            case .gpx: return UTType(filenameExtension: "gpx") ?? .xml
            case .tcx: return UTType(filenameExtension: "tcx") ?? .xml
            case .json: return .json
            case .csv: return .commaSeparatedText
            }
        }
    }
    
    // MARK: - Export Methods
    
    /// Export activity to GPX format
    func exportToGPX(activity: Activity) throws -> Data {
        guard let streams = activity.streams,
              let latLngData = streams.latLngData,
              !latLngData.isEmpty else {
            throw ExportError.noGPSData
        }
        
        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="CyclingPlus"
             xmlns="http://www.topografix.com/GPX/1/1"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
          <metadata>
            <name>\(activity.name.xmlEscaped)</name>
            <time>\(ISO8601DateFormatter().string(from: activity.startDate))</time>
          </metadata>
          <trk>
            <name>\(activity.name.xmlEscaped)</name>
            <trkseg>
        
        """
        
        for (index, latLng) in latLngData.enumerated() {
            let time = activity.startDate.addingTimeInterval(streams.timeData[index])
            let elevation = sampleValue(at: index, from: streams.elevationData) ?? 0
            
            gpx += """
                  <trkpt lat="\(latLng.latitude)" lon="\(latLng.longitude)">
                    <ele>\(elevation)</ele>
                    <time>\(ISO8601DateFormatter().string(from: time))</time>
                  </trkpt>
            
            """
        }
        
        gpx += """
            </trkseg>
          </trk>
        </gpx>
        """
        
        guard let data = gpx.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Export activity to TCX format
    func exportToTCX(activity: Activity) throws -> Data {
        guard let streams = activity.streams else {
            throw ExportError.noStreamData
        }
        
        var tcx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2">
          <Activities>
            <Activity Sport="Biking">
              <Id>\(ISO8601DateFormatter().string(from: activity.startDate))</Id>
              <Lap StartTime="\(ISO8601DateFormatter().string(from: activity.startDate))">
                <TotalTimeSeconds>\(activity.duration)</TotalTimeSeconds>
                <DistanceMeters>\(activity.distance)</DistanceMeters>
        
        """
        
        if let avgHR = activity.heartRateAnalysis?.averageHR {
            tcx += "        <AverageHeartRateBpm><Value>\(avgHR)</Value></AverageHeartRateBpm>\n"
        }
        
        if let maxHR = activity.heartRateAnalysis?.maxHR {
            tcx += "        <MaximumHeartRateBpm><Value>\(maxHR)</Value></MaximumHeartRateBpm>\n"
        }
        
        tcx += "        <Track>\n"
        
        for index in 0..<streams.timeData.count {
            let time = activity.startDate.addingTimeInterval(streams.timeData[index])
            
            tcx += """
                  <Trackpoint>
                    <Time>\(ISO8601DateFormatter().string(from: time))</Time>
            
            """
            
            if let latLngData = streams.latLngData, index < latLngData.count {
                let latLng = latLngData[index]
                tcx += """
                        <Position>
                          <LatitudeDegrees>\(latLng.latitude)</LatitudeDegrees>
                          <LongitudeDegrees>\(latLng.longitude)</LongitudeDegrees>
                        </Position>
                
                """
            }
            
            if let elevation = sampleValue(at: index, from: streams.elevationData) {
                tcx += "            <AltitudeMeters>\(elevation)</AltitudeMeters>\n"
            }
            
            if let hr = sampleValue(at: index, from: streams.heartRateData) {
                tcx += "            <HeartRateBpm><Value>\(hr)</Value></HeartRateBpm>\n"
            }
            
            if let cadence = sampleValue(at: index, from: streams.cadenceData) {
                tcx += "            <Cadence>\(cadence)</Cadence>\n"
            }
            
            if let power = sampleValue(at: index, from: streams.powerData) {
                tcx += "            <Extensions><TPX xmlns=\"http://www.garmin.com/xmlschemas/ActivityExtension/v2\"><Watts>\(Int(power))</Watts></TPX></Extensions>\n"
            }
            
            tcx += "          </Trackpoint>\n"
        }
        
        tcx += """
                </Track>
              </Lap>
            </Activity>
          </Activities>
        </TrainingCenterDatabase>
        """
        
        guard let data = tcx.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Export activity to JSON format
    func exportToJSON(activity: Activity) throws -> Data {
        var exportDict: [String: Any] = [
            "id": activity.id,
            "name": activity.name,
            "startDate": ISO8601DateFormatter().string(from: activity.startDate),
            "distance": activity.distance,
            "duration": activity.duration,
            "elevationGain": activity.elevationGain,
            "source": activity.source.rawValue
        ]
        
        if let streams = activity.streams {
            var streamsDict: [String: Any] = [
                "timeData": streams.timeData
            ]
            
            if let powerData = exportableStreamArray(streams.powerData) {
                streamsDict["powerData"] = powerData
            }
            if let hrData = exportableStreamArray(streams.heartRateData) {
                streamsDict["heartRateData"] = hrData
            }
            if let cadenceData = exportableStreamArray(streams.cadenceData) {
                streamsDict["cadenceData"] = cadenceData
            }
            if let speedData = exportableStreamArray(streams.speedData) {
                streamsDict["speedData"] = speedData
            }
            if let elevationData = exportableStreamArray(streams.elevationData) {
                streamsDict["elevationData"] = elevationData
            }
            if let latLngData = streams.latLngData {
                streamsDict["latLngData"] = latLngData.map { ["lat": $0.latitude, "lng": $0.longitude] }
            }
            
            exportDict["streams"] = streamsDict
        }
        
        if let powerAnalysis = activity.powerAnalysis {
            var paDict: [String: Any] = [:]
            if let eftp = powerAnalysis.eFTP { paDict["eFTP"] = eftp }
            if let np = powerAnalysis.normalizedPower { paDict["normalizedPower"] = np }
            if let intensity = powerAnalysis.intensityFactor { paDict["intensityFactor"] = intensity }
            if let tss = powerAnalysis.trainingStressScore { paDict["trainingStressScore"] = tss }
            if let avgPower = powerAnalysis.averagePower { paDict["averagePower"] = avgPower }
            if let maxPower = powerAnalysis.maxPower { paDict["maxPower"] = maxPower }
            
            exportDict["powerAnalysis"] = paDict
        }
        
        if let hrAnalysis = activity.heartRateAnalysis {
            var hrDict: [String: Any] = [:]
            if let avgHR = hrAnalysis.averageHR { hrDict["averageHR"] = avgHR }
            if let maxHR = hrAnalysis.maxHR { hrDict["maxHR"] = maxHR }
            if let hrTSS = hrAnalysis.hrTSS { hrDict["hrTSS"] = hrTSS }
            if let vo2max = hrAnalysis.estimatedVO2Max { hrDict["estimatedVO2Max"] = vo2max }
            
            exportDict["heartRateAnalysis"] = hrDict
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted, .sortedKeys])
        return jsonData
    }
    
    /// Export activity to CSV format
    func exportToCSV(activity: Activity) throws -> Data {
        guard let streams = activity.streams else {
            throw ExportError.noStreamData
        }
        
        var csv = "Time,Power,HeartRate,Cadence,Speed,Elevation,Latitude,Longitude\n"
        
        for index in 0..<streams.timeData.count {
            let time = streams.timeData[index]
            let power = sampleValue(at: index, from: streams.powerData) ?? 0
            let hr = sampleValue(at: index, from: streams.heartRateData) ?? 0
            let cadence = sampleValue(at: index, from: streams.cadenceData) ?? 0
            let speed = sampleValue(at: index, from: streams.speedData) ?? 0
            let elevation = sampleValue(at: index, from: streams.elevationData) ?? 0
            let lat = (streams.latLngData?[safe: index])?.latitude ?? 0
            let lng = (streams.latLngData?[safe: index])?.longitude ?? 0
            
            csv += "\(time),\(power),\(hr),\(cadence),\(speed),\(elevation),\(lat),\(lng)\n"
        }
        
        guard let data = csv.data(using: .utf8) else {
            throw ExportError.encodingFailed
        }
        
        return data
    }
    
    /// Export activity based on format
    func exportActivity(_ activity: Activity, format: ExportFormat) throws -> Data {
        switch format {
        case .gpx:
            return try exportToGPX(activity: activity)
        case .tcx:
            return try exportToTCX(activity: activity)
        case .json:
            return try exportToJSON(activity: activity)
        case .csv:
            return try exportToCSV(activity: activity)
        }
    }
    
    /// Get suggested filename for export
    func suggestedFilename(for activity: Activity, format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: activity.startDate)
        
        let sanitizedName = activity.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        
        return "\(dateString)_\(sanitizedName).\(format.fileExtension)"
    }
    
    // MARK: - Stream Helpers
    
    private func sampleValue<T>(at index: Int, from stream: [T?]?) -> T? {
        guard let stream, index < stream.count else { return nil }
        return stream[index]
    }
    
    private func exportableStreamArray<T>(_ stream: [T?]?) -> [Any]? {
        guard let stream, stream.contains(where: { $0 != nil }) else { return nil }
        return stream.map { sample -> Any in
            if let sample {
                return sample
            } else {
                return NSNull()
            }
        }
    }
}

// MARK: - Supporting Types

enum ExportError: LocalizedError {
    case noGPSData
    case noStreamData
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .noGPSData:
            return "This activity does not contain GPS data required for GPX export."
        case .noStreamData:
            return "This activity does not contain stream data."
        case .encodingFailed:
            return "Failed to encode activity data."
        }
    }
}

// MARK: - String Extension

extension String {
    var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
