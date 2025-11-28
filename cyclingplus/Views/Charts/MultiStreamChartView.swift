//
//  MultiStreamChartView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import Charts

/// View for displaying multiple synchronized activity streams
struct MultiStreamChartView: View {
    let streams: ActivityStreams
    
    @State private var selectedStreams: Set<StreamType> = [.power, .heartRate]
    @State private var selectedTimeIndex: Double?
    @State private var showStreamSelector = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with stream selector
            HStack {
                Text("Activity Streams")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showStreamSelector.toggle() }) {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Streams (\(selectedStreams.count))")
                    }
                }
                .buttonStyle(.bordered)
                .popover(isPresented: $showStreamSelector) {
                    streamSelectorView
                }
            }
            
            // Selected time indicator
            if let selectedTime = selectedTimeIndex {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text("Time: \(formatTime(selectedTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Clear Selection") {
                        selectedTimeIndex = nil
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
            }
            
            // Charts
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(selectedStreams).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { streamType in
                        if hasData(for: streamType) {
                            streamChartView(for: streamType)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Subviews
    
    private var streamSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Streams")
                .font(.headline)
                .padding(.bottom, 8)
            
            ForEach(StreamType.allCases, id: \.self) { streamType in
                if hasData(for: streamType) {
                    Toggle(isOn: Binding(
                        get: { selectedStreams.contains(streamType) },
                        set: { isSelected in
                            if isSelected {
                                selectedStreams.insert(streamType)
                            } else {
                                selectedStreams.remove(streamType)
                            }
                        }
                    )) {
                        HStack {
                            Circle()
                                .fill(streamType.color)
                                .frame(width: 12, height: 12)
                            Text(streamType.displayName)
                        }
                    }
                    #if os(macOS)
                    .toggleStyle(.checkbox)
                    #else
                    .toggleStyle(.switch)
                    #endif
                }
            }
        }
        .padding()
        .frame(width: 250)
    }
    
    private func streamChartView(for streamType: StreamType) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stream header
            HStack {
                Circle()
                    .fill(streamType.color)
                    .frame(width: 10, height: 10)
                Text(streamType.displayName)
                    .font(.headline)
                
                Spacer()
                
                if let value = getValue(for: streamType, at: selectedTimeIndex) {
                    Text(streamType.formatValue(value))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(streamType.color.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // Chart
            Chart {
                ForEach(getChartData(for: streamType), id: \.time) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(streamType.color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", point.time),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                streamType.color.opacity(0.2),
                                streamType.color.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Selection indicator
                if let selectedTime = selectedTimeIndex,
                   let value = getValue(for: streamType, at: selectedTime) {
                    RuleMark(x: .value("Selected", selectedTime))
                        .foregroundStyle(Color.gray.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    
                    PointMark(
                        x: .value("Time", selectedTime),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(streamType.color)
                    .symbolSize(80)
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
            .chartXSelection(value: $selectedTimeIndex)
            .frame(height: 180)
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func hasData(for streamType: StreamType) -> Bool {
        switch streamType {
        case .power:
            return streams.hasData(in: streams.powerData)
        case .heartRate:
            return streams.hasData(in: streams.heartRateData)
        case .cadence:
            return streams.hasData(in: streams.cadenceData)
        case .speed:
            return streams.hasData(in: streams.speedData)
        case .elevation:
            return streams.hasData(in: streams.elevationData)
        }
    }
    
    private func getChartData(for streamType: StreamType) -> [ChartDataPoint] {
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
    
    private func getValue(for streamType: StreamType, at time: Double?) -> Double? {
        guard let time = time else { return nil }
        
        let data = getChartData(for: streamType)
        guard !data.isEmpty else { return nil }
        
        // Find closest time point
        let closest = data.min(by: { abs($0.time - time) < abs($1.time - time) })
        return closest?.value
    }
    
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

// MARK: - Preview

#Preview {
    let timeData = (0..<1200).map { Double($0) }
    let powerData = (0..<1200).map { i in 200.0 + sin(Double(i) / 100.0) * 80.0 }
    let hrData = (0..<1200).map { i in Int(145.0 + sin(Double(i) / 80.0) * 25.0) }
    let cadenceData = (0..<1200).map { i in Int(88.0 + sin(Double(i) / 60.0) * 12.0) }
    let speedData = (0..<1200).map { i in 9.0 + sin(Double(i) / 120.0) * 3.0 }
    let elevationData = (0..<1200).map { i in 150.0 + Double(i) * 0.15 }
    
    let sampleStreams = ActivityStreams(
        activityId: "preview",
        timeData: timeData,
        powerData: powerData.map { Optional($0) },
        heartRateData: hrData.map { Optional($0) },
        cadenceData: cadenceData.map { Optional($0) },
        speedData: speedData.map { Optional($0) },
        elevationData: elevationData.map { Optional($0) }
    )
    
    return MultiStreamChartView(streams: sampleStreams)
        .frame(width: 900, height: 800)
}
