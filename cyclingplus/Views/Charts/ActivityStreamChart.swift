//
//  ActivityStreamChart.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import Charts

/// Interactive chart for displaying activity stream data
struct ActivityStreamChart: View {
    let streams: ActivityStreams
    let streamType: StreamType
    
    @State private var selectedIndex: Int?
    @State private var chartScale: CGFloat = 1.0
    @State private var chartOffset: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Chart title and legend
            HStack {
                Text(streamType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = selectedValue {
                    Text(streamType.formatValue(value))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Chart view
            Chart {
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value(streamType.displayName, point.value)
                    )
                    .foregroundStyle(streamType.color)
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedIndex = selectedIndex, selectedIndex == index {
                        PointMark(
                            x: .value("Time", point.time),
                            y: .value(streamType.displayName, point.value)
                        )
                        .foregroundStyle(streamType.color)
                        .symbolSize(100)
                    }
                }
                
                // Add area fill
                ForEach(Array(chartData.enumerated()), id: \.offset) { index, point in
                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value(streamType.displayName, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [streamType.color.opacity(0.3), streamType.color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let seconds = value.as(Double.self) {
                            Text(formatTime(seconds))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let val = value.as(Double.self) {
                            Text(streamType.formatAxisValue(val))
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedIndex)
            .frame(height: 200)
            .padding(.vertical, 8)
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var chartData: [ChartDataPoint] {
        switch streamType {
        case .power:
            return doubleChartData(from: streams.powerData)
        case .heartRate:
            return intChartData(from: streams.heartRateData)
        case .cadence:
            return intChartData(from: streams.cadenceData)
        case .speed:
            return doubleChartData(from: streams.speedData)
        case .elevation:
            return doubleChartData(from: streams.elevationData)
        }
    }
    
    private var selectedValue: Double? {
        guard let selectedIndex = selectedIndex,
              selectedIndex < chartData.count else { return nil }
        return chartData[selectedIndex].value
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    private func doubleChartData(from stream: [Double?]?) -> [ChartDataPoint] {
        guard let stream else { return [] }
        return zip(streams.timeData, stream).map { time, value in
            ChartDataPoint(time: time, value: value ?? 0)
        }
    }
    
    private func intChartData(from stream: [Int?]?) -> [ChartDataPoint] {
        guard let stream else { return [] }
        return zip(streams.timeData, stream).map { time, value in
            ChartDataPoint(time: time, value: Double(value ?? 0))
        }
    }
}

// MARK: - Supporting Types

struct ChartDataPoint {
    let time: Double
    let value: Double
}

enum StreamType: String, CaseIterable {
    case power
    case heartRate
    case cadence
    case speed
    case elevation
    
    var displayName: String {
        switch self {
        case .power: return "Power"
        case .heartRate: return "Heart Rate"
        case .cadence: return "Cadence"
        case .speed: return "Speed"
        case .elevation: return "Elevation"
        }
    }
    
    var color: Color {
        switch self {
        case .power: return .orange
        case .heartRate: return .red
        case .cadence: return .purple
        case .speed: return .blue
        case .elevation: return .green
        }
    }
    
    var unit: String {
        switch self {
        case .power: return "W"
        case .heartRate: return "bpm"
        case .cadence: return "rpm"
        case .speed: return "km/h"
        case .elevation: return "m"
        }
    }
    
    func formatValue(_ value: Double) -> String {
        switch self {
        case .power:
            return String(format: "%.0f %@", value, unit)
        case .heartRate, .cadence:
            return String(format: "%.0f %@", value, unit)
        case .speed:
            return String(format: "%.1f %@", value * 3.6, unit) // m/s to km/h
        case .elevation:
            return String(format: "%.0f %@", value, unit)
        }
    }
    
    func formatAxisValue(_ value: Double) -> String {
        switch self {
        case .power, .heartRate, .cadence, .elevation:
            return String(format: "%.0f", value)
        case .speed:
            return String(format: "%.0f", value * 3.6) // m/s to km/h
        }
    }
}

// MARK: - Preview

#Preview {
    let timeData = (0..<600).map { Double($0) }
    let powerData = (0..<600).map { i in 200.0 + sin(Double(i) / 50.0) * 50.0 }
    let hrData = (0..<600).map { i in Int(140.0 + sin(Double(i) / 40.0) * 20.0) }
    let cadenceData = (0..<600).map { i in Int(85.0 + sin(Double(i) / 30.0) * 10.0) }
    let speedData = (0..<600).map { i in 8.0 + sin(Double(i) / 60.0) * 2.0 }
    let elevationData = (0..<600).map { i in 100.0 + Double(i) * 0.1 }
    
    let sampleStreams = ActivityStreams(
        activityId: "preview",
        timeData: timeData,
        powerData: powerData.map { Optional($0) },
        heartRateData: hrData.map { Optional($0) },
        cadenceData: cadenceData.map { Optional($0) },
        speedData: speedData.map { Optional($0) },
        elevationData: elevationData.map { Optional($0) }
    )
    
    return ScrollView {
        VStack(spacing: 16) {
            ForEach(StreamType.allCases, id: \.self) { type in
                ActivityStreamChart(streams: sampleStreams, streamType: type)
            }
        }
        .padding()
    }
    .frame(width: 800, height: 1200)
}
