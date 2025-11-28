//
//  ActivityDetailView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct ActivityDetailView: View {
    let activity: Activity
    
    @State private var selectedTab: DetailTab = .overview
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                activityHeader
                
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    ForEach(DetailTab.allCases, id: \.self) { tab in
                        Text(tab.displayName).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .overview:
                        overviewView
                    case .charts:
                        chartsView
                    case .analysis:
                        analysisView
                    case .map:
                        mapView
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(activity.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ActivityActionsView(activity: activity)
            }
        }
    }
    
    // MARK: - Header
    
    private var activityHeader: some View {
        VStack(spacing: 16) {
            // Activity name and date
            VStack(spacing: 8) {
                Text(activity.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.secondary)
                    Text(activity.startDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    Text(activity.startDate, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Key metrics
            HStack(spacing: 20) {
                metricCard(
                    icon: "ruler",
                    title: "Distance",
                    value: formatDistance(activity.distance),
                    color: .blue
                )
                
                metricCard(
                    icon: "timer",
                    title: "Duration",
                    value: formatDuration(activity.duration),
                    color: .green
                )
                
                metricCard(
                    icon: "arrow.up.right",
                    title: "Elevation",
                    value: formatElevation(activity.elevationGain),
                    color: .orange
                )
                
                if let avgPower = activity.powerAnalysis?.averagePower {
                    metricCard(
                        icon: "bolt.fill",
                        title: "Avg Power",
                        value: "\(Int(avgPower)) W",
                        color: .yellow
                    )
                }
            }
            .padding(.horizontal)
            
            // Source badge
            HStack {
                Image(systemName: sourceIcon)
                    .foregroundColor(.secondary)
                Text("Source: \(activity.source.displayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Tab Views
    
    private var overviewView: some View {
        VStack(spacing: 16) {
            // Summary statistics
            if let streams = activity.streams {
                summaryStatsView(streams: streams)
            }
            
            // Power analysis summary
            if let powerAnalysis = activity.powerAnalysis {
                powerAnalysisSummary(analysis: powerAnalysis)
            }
            
            // Heart rate analysis summary
            if let hrAnalysis = activity.heartRateAnalysis {
                heartRateAnalysisSummary(analysis: hrAnalysis)
            }
        }
    }
    
    private var chartsView: some View {
        Group {
            if let streams = activity.streams {
                MultiStreamChartView(streams: streams)
            } else {
                Text("No stream data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var analysisView: some View {
        VStack(spacing: 16) {
            if let powerAnalysis = activity.powerAnalysis {
                detailedPowerAnalysis(analysis: powerAnalysis)
            }
            
            if let hrAnalysis = activity.heartRateAnalysis {
                detailedHeartRateAnalysis(analysis: hrAnalysis)
            }
            
            if activity.powerAnalysis == nil && activity.heartRateAnalysis == nil {
                Text("No analysis data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    private var mapView: some View {
        VStack {
            if let streams = activity.streams, let latLng = streams.latLngData, !latLng.isEmpty {
                Text("Map view coming soon")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("No GPS data available")
                    .foregroundColor(.secondary)
                    .padding()
            }
        }
    }
    
    // MARK: - Summary Views
    
    private func summaryStatsView(streams: ActivityStreams) -> some View {
        let powerValues = sanitizedDoubleValues(from: streams.powerData, validRange: 0.0...3000.0)
        let heartRateValues = sanitizedIntValues(from: streams.heartRateData, validRange: 30...230)
        let cadenceValues = sanitizedIntValues(from: streams.cadenceData, validRange: 0...220)
        let speedValues = sanitizedDoubleValues(from: streams.speedData, validRange: 0.0...40.0)
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Stream Data")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                statItem(
                    title: "Avg Power",
                    value: "\(Int(round(average(of: powerValues)))) W"
                )
                statItem(
                    title: "Max Power",
                    value: "\(Int(powerValues.max() ?? 0)) W"
                )
                
                statItem(
                    title: "Avg HR",
                    value: "\(Int(round(average(of: heartRateValues)))) bpm"
                )
                statItem(
                    title: "Max HR",
                    value: "\(heartRateValues.max() ?? 0) bpm"
                )
                
                statItem(
                    title: "Avg Cadence",
                    value: "\(Int(round(average(of: cadenceValues)))) rpm"
                )
                
                let avgSpeed = average(of: speedValues) * 3.6
                statItem(
                    title: "Avg Speed",
                    value: String(format: "%.1f km/h", avgSpeed)
                )
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    private func powerAnalysisSummary(analysis: PowerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Power Analysis")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let np = analysis.normalizedPower {
                    statItem(title: "Normalized Power", value: "\(Int(np)) W")
                }
                if let intensity = analysis.intensityFactor {
                    statItem(title: "Intensity Factor", value: String(format: "%.2f", intensity))
                }
                if let tss = analysis.trainingStressScore {
                    statItem(title: "TSS", value: String(format: "%.0f", tss))
                }
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    private func heartRateAnalysisSummary(analysis: HeartRateAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Analysis")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let avgHR = analysis.averageHR {
                    statItem(title: "Avg HR", value: "\(avgHR) bpm")
                }
                if let maxHR = analysis.maxHR {
                    statItem(title: "Max HR", value: "\(maxHR) bpm")
                }
                if let hrTSS = analysis.hrTSS {
                    statItem(title: "hrTSS", value: String(format: "%.0f", hrTSS))
                }
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    // MARK: - Detailed Analysis Views
    
    private func detailedPowerAnalysis(analysis: PowerAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Power Metrics")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let eftp = analysis.eFTP {
                    detailRow(label: "Estimated FTP", value: "\(Int(eftp)) W")
                }
                if let cp = analysis.criticalPower {
                    detailRow(label: "Critical Power", value: "\(Int(cp)) W")
                }
                if let wPrime = analysis.wPrime {
                    detailRow(label: "W'", value: "\(Int(wPrime)) J")
                }
                if let vi = analysis.variabilityIndex {
                    detailRow(label: "Variability Index", value: String(format: "%.2f", vi))
                }
                if let ef = analysis.efficiencyFactor {
                    detailRow(label: "Efficiency Factor", value: String(format: "%.2f", ef))
                }
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    private func detailedHeartRateAnalysis(analysis: HeartRateAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Heart Rate Metrics")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let vo2max = analysis.estimatedVO2Max {
                    detailRow(label: "Estimated VO₂max", value: String(format: "%.1f ml/kg/min", vo2max))
                }
            }
        }
        .padding()
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func metricCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(macOS)
        .background(Color(nsColor: .windowBackgroundColor))
        #else
        .background(Color(.systemBackground))
        #endif
        .cornerRadius(6)
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Computed Properties
    
    private var sourceIcon: String {
        switch activity.source {
        case .strava: return "figure.outdoor.cycle"
        case .igpsport: return "antenna.radiowaves.left.and.right"
        case .gpx, .tcx, .fit: return "doc"
        }
    }
    
    // MARK: - Formatters
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.2f km", km)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm %ds", minutes, secs)
        }
    }
    
    private func formatElevation(_ meters: Double) -> String {
        return String(format: "%.0f m", meters)
    }

    private func sanitizedDoubleValues(from stream: [Double?]?, validRange: ClosedRange<Double>) -> [Double] {
        guard let stream else { return [] }
        return stream.compactMap { value in
            guard let value, value.isFinite else { return nil }
            return validRange.contains(value) ? value : nil
        }
    }
    
    private func sanitizedIntValues(from stream: [Int?]?, validRange: ClosedRange<Int>) -> [Int] {
        guard let stream else { return [] }
        return stream.compactMap { value in
            guard let value else { return nil }
            return validRange.contains(value) ? value : nil
        }
    }
    
    private func average(of values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        let total = values.reduce(0, +)
        return total / Double(values.count)
    }
    
    private func average(of values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        let total = values.reduce(0, +)
        return Double(total) / Double(values.count)
    }
}

// MARK: - Supporting Types

enum DetailTab: String, CaseIterable {
    case overview
    case charts
    case analysis
    case map
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .charts: return "Charts"
        case .analysis: return "Analysis"
        case .map: return "Map"
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Activity.self, configurations: config)
    
    let activity = Activity(
        name: "Morning Ride",
        startDate: Date(),
        distance: 45000,
        duration: 5400,
        elevationGain: 650,
        source: .strava,
        stravaId: 12345
    )
    
    let streams = ActivityStreams(
        activityId: activity.id,
        timeData: (0..<1200).map { Double($0) },
        powerData: (0..<1200).map { Optional(200 + sin(Double($0) / 100) * 80) },
        heartRateData: (0..<1200).map { Optional(Int(145 + sin(Double($0) / 80) * 25)) },
        cadenceData: (0..<1200).map { Optional(Int(88 + sin(Double($0) / 60) * 12)) },
        speedData: (0..<1200).map { Optional(9.0 + sin(Double($0) / 120) * 3) },
        elevationData: (0..<1200).map { Optional(150 + Double($0) * 0.15) }
    )
    
    activity.streams = streams
    
    let powerAnalysis = PowerAnalysis(
        activityId: activity.id,
        eFTP: 250,
        normalizedPower: 210,
        intensityFactor: 0.84,
        trainingStressScore: 85,
        variabilityIndex: 1.05,
        averagePower: 200
    )
    
    activity.powerAnalysis = powerAnalysis
    
    container.mainContext.insert(activity)
    
    return NavigationStack {
        ActivityDetailView(activity: activity)
    }
    .modelContainer(container)
    .frame(width: 1000, height: 800)
}
