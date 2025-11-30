//
//  FITParser.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/8.
//

import Foundation

/// Parser for FIT (Flexible and Interoperable Data Transfer) files
/// This is a basic implementation that extracts key metrics from FIT files
class FITParser {
    
    // MARK: - FIT File Structure Constants
    
    private let fitHeaderSize = 14
    private let fitFileHeaderSignature: [UInt8] = [0x2E, 0x46, 0x49, 0x54] // ".FIT"
    private let fitTimeOffset: TimeInterval = 631065600 // Seconds between Unix epoch and FIT epoch (1989-12-31)
    
    // Message types
    private let fileIdMessage: UInt16 = 0
    private let sessionMessage: UInt16 = 18
    private let lapMessage: UInt16 = 19
    private let recordMessage: UInt16 = 20
    
    // Field definitions for session message
    private let sessionTimestampField: UInt8 = 253
    private let sessionStartTimeField: UInt8 = 2
    private let sessionTotalDistanceField: UInt8 = 9
    private let sessionTotalTimerTimeField: UInt8 = 7
    private let sessionTotalAscentField: UInt8 = 22
    private let sessionAvgSpeedField: UInt8 = 14
    private let sessionMaxSpeedField: UInt8 = 15
    private let sessionAvgHeartRateField: UInt8 = 16
    private let sessionMaxHeartRateField: UInt8 = 17
    private let sessionAvgCadenceField: UInt8 = 18
    private let sessionMaxCadenceField: UInt8 = 19
    private let sessionAvgPowerField: UInt8 = 20
    private let sessionMaxPowerField: UInt8 = 21
    
    // Field definitions for record message (time-series data)
    // Based on FIT SDK Profile - Message 20 (Record)
    private let recordTimestampField: UInt8 = 253
    private let recordPositionLatField: UInt8 = 0
    private let recordPositionLongField: UInt8 = 1
    private let recordAltitudeField: UInt8 = 2
    private let recordHeartRateField: UInt8 = 3
    private let recordCadenceField: UInt8 = 4  // Combined cadence (or use field 5 for cadence)
    private let recordDistanceField: UInt8 = 5
    private let recordSpeedField: UInt8 = 6
    private let recordPowerField: UInt8 = 7
    private let recordTemperatureField: UInt8 = 13
    
    // MARK: - Parsing
    
    func parse(data: Data) throws -> FITData {
        guard data.count >= fitHeaderSize else {
            throw FITParseError.invalidFileFormat("File too small")
        }
        
        // Verify FIT file header
        let headerSize = data[0]
        
        // Check signature
        let signatureStart = min(8, Int(headerSize) - 4)
        guard signatureStart + 4 <= data.count else {
            throw FITParseError.invalidFileFormat("Invalid header")
        }
        
        let signature = Array(data[signatureStart..<(signatureStart + 4)])
        guard signature == fitFileHeaderSignature else {
            throw FITParseError.invalidFileFormat("Invalid FIT signature")
        }
        
        var fitData = FITData()
        var offset = Int(headerSize)
        
        var messageDefinitions: [UInt8: MessageDefinition] = [:]
        
        // Parse messages
        while offset < data.count - 2 { // -2 for CRC
            guard offset < data.count else { break }
            
            let recordHeader = data[offset]
            offset += 1
            
            let isDefinitionMessage = (recordHeader & 0x40) != 0
            let localMessageType = recordHeader & 0x0F
            
            if isDefinitionMessage {
                // Parse definition message
                if let (definition, bytesRead) = try? parseDefinitionMessage(data: data, offset: offset) {
                    messageDefinitions[localMessageType] = definition
                    offset += bytesRead
                } else {
                    offset += 1
                }
            } else {
                // Parse data message
                if let definition = messageDefinitions[localMessageType] {
                    if let (fields, bytesRead) = try? parseDataMessage(data: data, offset: offset, definition: definition) {
                        processDataMessage(globalMessageNumber: definition.globalMessageNumber, fields: fields, into: &fitData)
                        offset += bytesRead
                    } else {
                        offset += 1
                    }
                } else {
                    offset += 1
                }
            }
        }
        
        return fitData
    }
    
    private func parseDefinitionMessage(data: Data, offset: Int) throws -> (MessageDefinition, Int) {
        var currentOffset = offset
        
        guard currentOffset + 5 <= data.count else {
            throw FITParseError.unexpectedEndOfFile
        }
        
        let architecture = data[currentOffset + 1]
        let isLittleEndian = architecture == 0
        
        let globalMessageNumber: UInt16
        if isLittleEndian {
            globalMessageNumber = UInt16(data[currentOffset + 2]) | (UInt16(data[currentOffset + 3]) << 8)
        } else {
            globalMessageNumber = (UInt16(data[currentOffset + 2]) << 8) | UInt16(data[currentOffset + 3])
        }
        
        let numberOfFields = data[currentOffset + 4]
        currentOffset += 5
        
        var fieldDefinitions: [FieldDefinition] = []
        
        for _ in 0..<numberOfFields {
            guard currentOffset + 3 <= data.count else {
                throw FITParseError.unexpectedEndOfFile
            }
            
            let fieldDefNumber = data[currentOffset]
            let size = data[currentOffset + 1]
            let baseType = data[currentOffset + 2]
            
            fieldDefinitions.append(FieldDefinition(fieldDefNumber: fieldDefNumber, size: size, baseType: baseType))
            currentOffset += 3
        }
        
        let definition = MessageDefinition(
            globalMessageNumber: globalMessageNumber,
            isLittleEndian: isLittleEndian,
            fieldDefinitions: fieldDefinitions
        )
        
        return (definition, currentOffset - offset)
    }
    
    private func parseDataMessage(data: Data, offset: Int, definition: MessageDefinition) throws -> ([UInt8: Any], Int) {
        var currentOffset = offset
        var fields: [UInt8: Any] = [:]
        
        for fieldDef in definition.fieldDefinitions {
            guard currentOffset + Int(fieldDef.size) <= data.count else {
                throw FITParseError.unexpectedEndOfFile
            }
            
            let fieldData = data[currentOffset..<(currentOffset + Int(fieldDef.size))]
            let value = parseFieldValue(fieldData: fieldData, baseType: fieldDef.baseType, isLittleEndian: definition.isLittleEndian)
            
            fields[fieldDef.fieldDefNumber] = value
            currentOffset += Int(fieldDef.size)
        }
        
        return (fields, currentOffset - offset)
    }
    
    private func parseFieldValue(fieldData: Data, baseType: UInt8, isLittleEndian: Bool) -> Any? {
        // Guard against empty data
        guard !fieldData.isEmpty else { return nil }
        
        let baseTypeEnum = baseType & 0x1F
        
        switch baseTypeEnum {
        case 0x00: // enum (uint8)
            guard fieldData.count >= 1 else { return nil }
            let value = fieldData[fieldData.startIndex]
            // Check for invalid value (0xFF is typically invalid for UInt8)
            return value == 0xFF ? nil : value
        case 0x01: // sint8
            guard fieldData.count >= 1 else { return nil }
            let value = Int8(bitPattern: fieldData[fieldData.startIndex])
            // Check for invalid value (0x7F is typically invalid for Int8)
            return value == 0x7F ? nil : value
        case 0x02: // uint8
            guard fieldData.count >= 1 else { return nil }
            let value = fieldData[fieldData.startIndex]
            // Check for invalid value (0xFF is typically invalid for UInt8)
            return value == 0xFF ? nil : value
        case 0x03: // sint16
            guard fieldData.count >= 2 else { return nil }
            let bytes = Array(fieldData.prefix(2))
            let value = isLittleEndian ?
                Int16(bitPattern: UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)) :
                Int16(bitPattern: (UInt16(bytes[0]) << 8) | UInt16(bytes[1]))
            // Check for invalid value (0x7FFF is typically invalid for Int16)
            return value == 0x7FFF ? nil : value
        case 0x04: // uint16
            guard fieldData.count >= 2 else { return nil }
            let bytes = Array(fieldData.prefix(2))
            let value = isLittleEndian ?
                UInt16(bytes[0]) | (UInt16(bytes[1]) << 8) :
                (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
            // Check for invalid value (0xFFFF is typically invalid for UInt16)
            return value == 0xFFFF ? nil : value
        case 0x05: // sint32
            guard fieldData.count >= 4 else { return nil }
            let bytes = Array(fieldData.prefix(4))
            let value = isLittleEndian ?
                Int32(bitPattern: UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24)) :
                Int32(bitPattern: (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3]))
            // Check for invalid value (0x7FFFFFFF is typically invalid for Int32)
            return value == 0x7FFFFFFF ? nil : value
        case 0x06: // uint32
            guard fieldData.count >= 4 else { return nil }
            let bytes = Array(fieldData.prefix(4))
            let value = isLittleEndian ?
                UInt32(bytes[0]) | (UInt32(bytes[1]) << 8) | (UInt32(bytes[2]) << 16) | (UInt32(bytes[3]) << 24) :
                (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
            // Check for invalid value (0xFFFFFFFF is typically invalid for UInt32)
            return value == 0xFFFFFFFF ? nil : value
        case 0x07: // string
            // Remove null terminators
            let cleanData = fieldData.prefix(while: { $0 != 0 })
            return String(data: Data(cleanData), encoding: .utf8)
        case 0x0D: // byte array
            return fieldData
        default:
            return nil
        }
    }
    
    private func processDataMessage(globalMessageNumber: UInt16, fields: [UInt8: Any], into fitData: inout FITData) {
        if globalMessageNumber == sessionMessage {
            // Process session message
            if let timestamp = fields[sessionTimestampField] as? UInt32 {
                fitData.startTime = Date(timeIntervalSince1970: TimeInterval(timestamp) + fitTimeOffset)
            }
            
            if let distance = fields[sessionTotalDistanceField] as? UInt32 {
                fitData.totalDistance = Double(distance) / 100.0 // Convert from cm to m
            }
            
            if let time = fields[sessionTotalTimerTimeField] as? UInt32 {
                fitData.totalTime = Double(time) / 1000.0 // Convert from ms to s
            }
            
            if let ascent = fields[sessionTotalAscentField] as? UInt16 {
                fitData.totalAscent = Double(ascent)
            }
            
            if let avgSpeed = fields[sessionAvgSpeedField] as? UInt16 {
                fitData.averageSpeed = Double(avgSpeed) / 1000.0 // Convert from mm/s to m/s
            }
            
            if let maxSpeed = fields[sessionMaxSpeedField] as? UInt16 {
                fitData.maxSpeed = Double(maxSpeed) / 1000.0
            }
            
            if let avgHR = fields[sessionAvgHeartRateField] as? UInt8 {
                fitData.averageHeartRate = Double(avgHR)
            }
            
            if let maxHR = fields[sessionMaxHeartRateField] as? UInt8 {
                fitData.maxHeartRate = Double(maxHR)
            }
            
            // Try multiple types for cadence
            if let avgCadence = fields[sessionAvgCadenceField] as? UInt8 {
                fitData.averageCadence = Double(avgCadence)
            } else if let avgCadence = fields[sessionAvgCadenceField] as? UInt16 {
                fitData.averageCadence = Double(avgCadence)
            }
            
            if let maxCadence = fields[sessionMaxCadenceField] as? UInt8 {
                fitData.maxCadence = Double(maxCadence)
            } else if let maxCadence = fields[sessionMaxCadenceField] as? UInt16 {
                fitData.maxCadence = Double(maxCadence)
            }
            
            // Try multiple types for power
            if let avgPower = fields[sessionAvgPowerField] as? UInt16 {
                fitData.averagePower = Double(avgPower)
            } else if let avgPower = fields[sessionAvgPowerField] as? UInt32 {
                fitData.averagePower = Double(avgPower)
            }
            
            if let maxPower = fields[sessionMaxPowerField] as? UInt16 {
                fitData.maxPower = Double(maxPower)
            } else if let maxPower = fields[sessionMaxPowerField] as? UInt32 {
                fitData.maxPower = Double(maxPower)
            }
        } else if globalMessageNumber == recordMessage {
            // Process record message (time-series data)
            // Limit records to prevent memory issues (sample every 5th record if too many)
            if let record = parseRecordMessage(fields: fields) {
                if fitData.records.count < 10000 {
                    fitData.records.append(record)
                } else if fitData.records.count % 5 == 0 {
                    // Sample every 5th record after 10k records
                    fitData.records.append(record)
                }
            }
        }
    }
    
    private func parseRecordMessage(fields: [UInt8: Any]) -> FITRecord? {
        // Extract timestamp - required field
        guard let timestampValue = fields[recordTimestampField] as? UInt32 else {
            return nil
        }
        
        let timestamp = TimeInterval(timestampValue) + fitTimeOffset
        
        // Extract GPS coordinates (stored as semicircles)
        var latitude: Double?
        var longitude: Double?
        
        if let latSemicircles = fields[recordPositionLatField] as? Int32 {
            latitude = semicirclesToDegrees(latSemicircles)
        }
        
        if let lngSemicircles = fields[recordPositionLongField] as? Int32 {
            longitude = semicirclesToDegrees(lngSemicircles)
        }
        
        // Extract altitude (in meters, with 5m offset and 0.2m resolution)
        var altitude: Double?
        if let altValue = fields[recordAltitudeField] as? UInt16 {
            altitude = (Double(altValue) / 5.0) - 500.0
        }
        
        // Extract heart rate (bpm)
        var heartRate: Int?
        if let hrValue = fields[recordHeartRateField] as? UInt8 {
            heartRate = Int(hrValue)
        }
        
        // Extract cadence (rpm) - try multiple possible types
        var cadence: Int?
        if let cadenceValue = fields[recordCadenceField] as? UInt8 {
            cadence = Int(cadenceValue)
        } else if let cadenceValue = fields[recordCadenceField] as? Int8 {
            cadence = Int(cadenceValue)
        } else if let cadenceValue = fields[recordCadenceField] as? UInt16 {
            cadence = Int(cadenceValue)
        }
        
        // Extract distance (in meters, stored in cm)
        var distance: Double?
        if let distValue = fields[recordDistanceField] as? UInt32 {
            distance = Double(distValue) / 100.0
        }
        
        // Extract speed (in m/s, stored in mm/s)
        var speed: Double?
        if let speedValue = fields[recordSpeedField] as? UInt16 {
            speed = Double(speedValue) / 1000.0
        } else if let speedValue = fields[recordSpeedField] as? UInt32 {
            speed = Double(speedValue) / 1000.0
        }
        
        // Extract power (watts) - try multiple possible types
        var power: Int?
        if let powerValue = fields[recordPowerField] as? UInt16 {
            power = Int(powerValue)
        } else if let powerValue = fields[recordPowerField] as? UInt8 {
            power = Int(powerValue)
        } else if let powerValue = fields[recordPowerField] as? UInt32 {
            power = Int(powerValue)
        }
        
        // Extract temperature (degrees Celsius)
        var temperature: Double?
        if let tempValue = fields[recordTemperatureField] as? Int8 {
            temperature = Double(tempValue)
        }
        
        return FITRecord(
            timestamp: timestamp,
            latitude: latitude,
            longitude: longitude,
            altitude: altitude,
            speed: speed,
            distance: distance,
            heartRate: heartRate,
            cadence: cadence,
            power: power,
            temperature: temperature
        )
    }
    
    /// Convert GPS coordinates from semicircles to degrees
    /// FIT format stores coordinates as semicircles where 2^31 semicircles = 180 degrees
    private func semicirclesToDegrees(_ semicircles: Int32) -> Double {
        return Double(semicircles) * (180.0 / pow(2.0, 31))
    }
}

// MARK: - Data Structures

struct MessageDefinition {
    var globalMessageNumber: UInt16
    var isLittleEndian: Bool
    var fieldDefinitions: [FieldDefinition]
}

struct FieldDefinition {
    var fieldDefNumber: UInt8
    var size: UInt8
    var baseType: UInt8
}

struct FITData {
    var activityName: String?
    var startTime: Date?
    var totalDistance: Double = 0
    var totalTime: TimeInterval = 0
    var totalAscent: Double = 0
    var averageSpeed: Double?
    var maxSpeed: Double?
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var averageCadence: Double?
    var maxCadence: Double?
    var averagePower: Double?
    var maxPower: Double?
    var records: [FITRecord] = []
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

enum FITParseError: Error {
    case invalidFileFormat(String)
    case unexpectedEndOfFile
    case unsupportedVersion
}
