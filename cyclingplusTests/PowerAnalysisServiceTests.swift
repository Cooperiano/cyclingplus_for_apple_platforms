//
//  PowerAnalysisServiceTests.swift
//  cyclingplusTests
//
//  Created by Kiro on 2025/11/7.
//

import XCTest
@testable import cyclingplus

final class PowerAnalysisServiceTests: XCTestCase {
    
    var service: PowerAnalysisService!
    
    override func setUp() {
        super.setUp()
        service = PowerAnalysisService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Basic Power Metrics Tests
    
    func testCalculateAveragePower() {
        // Create test data: constant 200W for 10 minutes
        let powerData = Array(repeating: 200.0, count: 600)
        let timeData = (0..<600).map { Double($0) }
        
        let streams = ActivityStreams(
            activityId: "test-1",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: 250)
        
        XCTAssertNotNil(analysis.averagePower)
        XCTAssertEqual(analysis.averagePower!, 200.0, accuracy: 0.1)
        XCTAssertEqual(analysis.maxPower!, 200.0, accuracy: 0.1)
    }
    
    func testNormalizedPowerWithVariablePower() {
        // Create variable power data
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // 5 minutes at 150W, 5 minutes at 250W
        for i in 0..<300 {
            powerData.append(150.0)
            timeData.append(Double(i))
        }
        for i in 300..<600 {
            powerData.append(250.0)
            timeData.append(Double(i))
        }
        
        let streams = ActivityStreams(
            activityId: "test-2",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: 250)
        
        XCTAssertNotNil(analysis.normalizedPower)
        XCTAssertNotNil(analysis.averagePower)
        
        // NP should be higher than average power for variable efforts
        XCTAssertGreaterThan(analysis.normalizedPower!, analysis.averagePower!)
    }
    
    func testIntensityFactorCalculation() {
        // Create steady power at FTP
        let powerData = Array(repeating: 250.0, count: 600)
        let timeData = (0..<600).map { Double($0) }
        
        let streams = ActivityStreams(
            activityId: "test-3",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: 250)
        
        XCTAssertNotNil(analysis.intensityFactor)
        // IF should be close to 1.0 when riding at FTP
        XCTAssertEqual(analysis.intensityFactor!, 1.0, accuracy: 0.05)
    }
    
    func testTSSCalculation() {
        // 1 hour at FTP should give TSS of 100
        let powerData = Array(repeating: 250.0, count: 3600)
        let timeData = (0..<3600).map { Double($0) }
        
        let streams = ActivityStreams(
            activityId: "test-4",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: 250)
        
        XCTAssertNotNil(analysis.trainingStressScore)
        // TSS should be close to 100 for 1 hour at FTP
        XCTAssertEqual(analysis.trainingStressScore!, 100.0, accuracy: 5.0)
    }
    
    func testVariabilityIndex() {
        // Create steady power data
        let steadyPower = Array(repeating: 200.0, count: 600)
        let timeData = (0..<600).map { Double($0) }
        
        let streams = ActivityStreams(
            activityId: "test-5",
            timeData: timeData,
            powerData: steadyPower
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: 250)
        
        XCTAssertNotNil(analysis.variabilityIndex)
        // VI should be close to 1.0 for steady power
        XCTAssertEqual(analysis.variabilityIndex!, 1.0, accuracy: 0.05)
    }
    
    // MARK: - Mean Maximal Power Tests
    
    func testMeanMaximalPowerCalculation() {
        // Create power data with a 5-minute effort at 300W
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // 5 minutes at 300W
        for i in 0..<300 {
            powerData.append(300.0)
            timeData.append(Double(i))
        }
        // 5 minutes at 150W
        for i in 300..<600 {
            powerData.append(150.0)
            timeData.append(Double(i))
        }
        
        let mmp = service.calculateMeanMaximalPower(powerData: powerData, timeData: timeData)
        
        XCTAssertFalse(mmp.isEmpty)
        
        // Check that 5-minute MMP is close to 300W
        if let fiveMinMMP = mmp.first(where: { $0.duration == 300 }) {
            XCTAssertEqual(fiveMinMMP.power, 300.0, accuracy: 10.0)
        }
    }
    
    // MARK: - Critical Power Tests
    
    func testCriticalPowerCalculation() {
        // Create synthetic data for CP calculation
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // Simulate a workout with efforts at different durations
        // 3 minutes at 350W
        for i in 0..<180 {
            powerData.append(350.0)
            timeData.append(Double(i))
        }
        // Recovery
        for i in 180..<480 {
            powerData.append(150.0)
            timeData.append(Double(i))
        }
        // 12 minutes at 280W
        for i in 480..<1200 {
            powerData.append(280.0)
            timeData.append(Double(i))
        }
        
        if let result = service.calculateCriticalPower(powerData: powerData, timeData: timeData) {
            XCTAssertGreaterThan(result.cp, 0)
            XCTAssertGreaterThan(result.wPrime, 0)
            // CP should be less than 3-min power
            XCTAssertLessThan(result.cp, 350.0)
        }
    }
    
    // MARK: - W' Balance Tests
    
    func testWPrimeBalanceCalculation() {
        let cp = 250.0
        let wPrime = 20000.0
        
        // Create power data above and below CP
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // 2 minutes above CP (depleting W')
        for i in 0..<120 {
            powerData.append(350.0)
            timeData.append(Double(i))
        }
        // 3 minutes below CP (recovering W')
        for i in 120..<300 {
            powerData.append(200.0)
            timeData.append(Double(i))
        }
        
        let wBalance = service.calculateWPrimeBalance(
            powerData: powerData,
            timeData: timeData,
            cp: cp,
            wPrime: wPrime
        )
        
        XCTAssertEqual(wBalance.count, powerData.count)
        XCTAssertEqual(wBalance.first!, wPrime, accuracy: 100)
        
        // W' should decrease during hard effort
        XCTAssertLessThan(wBalance[119], wBalance[0])
        
        // W' should increase during recovery
        XCTAssertGreaterThan(wBalance[299], wBalance[119])
    }
    
    // MARK: - Power Zone Distribution Tests
    
    func testPowerZoneDistribution() {
        let ftp = 250.0
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // Create data with time in different zones
        // 5 minutes in Z2 (65% FTP = 162.5W)
        for i in 0..<300 {
            powerData.append(162.5)
            timeData.append(Double(i))
        }
        // 5 minutes in Z4 (95% FTP = 237.5W)
        for i in 300..<600 {
            powerData.append(237.5)
            timeData.append(Double(i))
        }
        // 2 minutes in Z5 (110% FTP = 275W)
        for i in 600..<720 {
            powerData.append(275.0)
            timeData.append(Double(i))
        }
        
        let streams = ActivityStreams(
            activityId: "test-zones",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: ftp)
        
        // Basic validation - check that power zones were calculated
        XCTAssertFalse(analysis.powerZones.isEmpty, "Power zones should not be empty. Count: \(analysis.powerZones.count)")
        
        // If we have zones, verify they make sense
        if !analysis.powerZones.isEmpty {
            XCTAssertEqual(analysis.powerZones.count, 7, "Should have 7 power zones")
            
            // Verify total percentage adds up to 100%
            let totalPercentage = analysis.powerZones.reduce(0.0) { $0 + $1.percentageInZone }
            XCTAssertEqual(totalPercentage, 100.0, accuracy: 0.1, "Total percentage should be 100%")
            
            // Check that some zones have time in them
            let zonesWithTime = analysis.powerZones.filter { $0.timeInZone > 0 }
            XCTAssertGreaterThan(zonesWithTime.count, 0, "At least one zone should have time")
        }
    }
    
    func testPowerZoneDistributionWithCustomZones() {
        let ftp = 250.0
        let customZones = [
            ftp * 0.60, // Custom Z1
            ftp * 0.80, // Custom Z2
            ftp * 1.00, // Custom Z3
            ftp * 1.10, // Custom Z4
            ftp * 1.30, // Custom Z5
            ftp * 1.60  // Custom Z6
        ]
        
        var powerData: [Double] = []
        var timeData: [Double] = []
        
        // 10 minutes at 200W (Z3 in custom zones)
        for i in 0..<600 {
            powerData.append(200.0)
            timeData.append(Double(i))
        }
        
        let streams = ActivityStreams(
            activityId: "test-custom-zones",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams, userFTP: ftp, userPowerZones: customZones)
        
        XCTAssertFalse(analysis.powerZones.isEmpty)
        
        // Most time should be in Z3 (200W is between 80% and 100% of FTP)
        if let z3 = analysis.powerZones.first(where: { $0.zone == 3 }) {
            XCTAssertGreaterThan(z3.percentageInZone, 90.0)
        }
    }
    
    // MARK: - Edge Cases
    
    func testEmptyPowerData() {
        let streams = ActivityStreams(
            activityId: "test-empty",
            timeData: [],
            powerData: nil
        )
        
        let analysis = service.calculatePowerMetrics(from: streams)
        
        XCTAssertNil(analysis.averagePower)
        XCTAssertNil(analysis.normalizedPower)
    }
    
    func testFTPEstimation() {
        // Create 25-minute power data at 250W
        let powerData = Array(repeating: 250.0, count: 1500)
        let timeData = (0..<1500).map { Double($0) }
        
        let streams = ActivityStreams(
            activityId: "test-ftp",
            timeData: timeData,
            powerData: powerData
        )
        
        let analysis = service.calculatePowerMetrics(from: streams)
        
        XCTAssertNotNil(analysis.eFTP)
        // eFTP should be around 95% of average power
        XCTAssertEqual(analysis.eFTP!, 237.5, accuracy: 5.0)
    }
}
