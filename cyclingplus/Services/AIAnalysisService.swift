//
//  AIAnalysisService.swift
//  cyclingplus
//
//  Created by Codex on 2025/11/29.
//

import Foundation
import SwiftData

/// Lightweight, on-device AI-style analysis based on existing ride metrics.
/// This avoids network calls while still giving users immediate insights.
struct AIAnalysisService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    func generateAnalysis(for activity: Activity) throws -> AIAnalysis {
        let userProfile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first
        let ftp = userProfile?.ftp
        let maxHR = userProfile?.maxHeartRate
        let weightKg = userProfile?.weight
        
        let aiProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "local"
        let apiKey = UserDefaults.standard.string(forKey: "aiAPIKey") ?? ""
        
        // Basic metrics
        let distanceKm = activity.distance / 1000.0
        let durationHrs = activity.duration / 3600.0
        let elevation = activity.elevationGain
        let avgSpeedKph = durationHrs > 0 ? distanceKm / durationHrs : 0
        
        // Power/HR metrics
        let avgPower = activity.powerAnalysis?.averagePower ?? average(from: activity.streams?.powerData)
        let avgHR = activity.heartRateAnalysis?.averageHR ?? average(from: activity.streams?.heartRateData)
        let np = normalizedPower(from: activity.streams?.powerData, ftp: ftp) ?? avgPower
        let intensityFactor: Double?
        if let ftp = ftp, let np = np, ftp > 0 {
            intensityFactor = np / ftp
        } else {
            intensityFactor = nil
        }
        let estimatedTSS = trainingStressScore(np: np, duration: activity.duration, ftp: ftp)
        
        // HR zone distribution (if maxHR available)
        let hrZones = maxHR.flatMap { hrZoneDistribution(from: activity.streams?.heartRateData, maxHR: $0) }
        
        // Training load estimate
        let tss = activity.powerAnalysis?.trainingStressScore ?? estimatedTSS
        let hrTSS = activity.heartRateAnalysis?.hrTSS
        let estimatedLoad = tss ?? hrTSS ?? estimatedLoadFromDistance(distanceKm, durationHrs)
        
        let insights = buildInsights(
            distanceKm: distanceKm,
            avgSpeedKph: avgSpeedKph,
            elevation: elevation,
            avgPower: avgPower,
            np: np,
            intensityFactor: intensityFactor,
            tss: tss,
            avgHR: avgHR,
            hrZones: hrZones,
            load: estimatedLoad,
            weightKg: weightKg
        )
        let recommendations = buildRecommendations(
            load: estimatedLoad,
            elevation: elevation,
            durationHrs: durationHrs,
            intensityFactor: intensityFactor,
            tss: tss
        )
        let recovery = recoveryAdvice(for: estimatedLoad)
        let score = performanceScore(load: estimatedLoad, avgSpeed: avgSpeedKph, elevation: elevation)
        
        var summaryLines: [String] = []
        summaryLines.append("骑行摘要：\(String(format: "%.1f", distanceKm)) km，用时 \(formattedDuration(activity.duration))，平均速度 \(String(format: "%.1f", avgSpeedKph)) km/h，爬升 \(Int(elevation)) m。")
        if let np {
            let ifText = intensityFactor.map { String(format: ", IF %.2f", $0) } ?? ""
            summaryLines.append("标准化功率 \(Int(np)) W\(ifText)。")
        } else if let avgPower {
            summaryLines.append("平均功率 \(Int(avgPower)) W。")
        }
        if let tss {
            summaryLines.append("训练负荷 TSS ≈ \(Int(tss)).")
        }
        if let avgHR {
            let zoneText = hrZones.map { "，区间分布：\($0.description)" } ?? ""
            summaryLines.append("平均心率 \(avgHR) bpm\(zoneText)。")
        }
        let summary = summaryLines.joined(separator: " ")
        
        let analysis = AIAnalysis(
            activityId: activity.id,
            analysisText: summary,
            performanceInsights: insights,
            trainingRecommendations: recommendations,
            recoveryAdvice: recovery,
            performanceScore: score,
            aiProvider: "local-heuristic"
        )
        
        analysis.activity = activity
        activity.aiAnalysis = analysis
        try modelContext.save()
        
        // Optional remote refinement (hybrid): if API key present, attempt provider and overwrite text
        if !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task.detached { @MainActor in
                do {
                    let provider = RemoteAIClient.Provider(rawValue: aiProvider.lowercased()) ?? .deepseek
                    let prompt = buildRemotePrompt(activity: activity, summary: summary, np: np, intensityFactor: intensityFactor, tss: tss, hrZones: hrZones, weightKg: weightKg)
                    let systemPrompt = remoteSystemPrompt()
                    let client = RemoteAIClient()
                    let remoteText = try await client.chat(provider: provider, apiKey: apiKey, prompt: prompt, model: nil, system: systemPrompt)
                    analysis.analysisText = remoteText
                    analysis.aiProvider = provider.rawValue
                    analysis.updatedAt = Date()
                    try modelContext.save()
                } catch {
                    // Keep local analysis if remote fails
                    print("Remote AI analysis failed: \(error)")
                }
            }
        }
        
        return analysis
    }
    
    // MARK: - Helpers
    
    private func average(from values: [Double?]?) -> Double? {
        guard let values else { return nil }
        let filtered = values.compactMap { $0 }.filter { $0.isFinite && $0 > 0 }
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0, +) / Double(filtered.count)
    }
    
    private func average(from values: [Int?]?) -> Int? {
        guard let values else { return nil }
        let filtered = values.compactMap { $0 }.filter { $0 > 0 }
        guard !filtered.isEmpty else { return nil }
        return filtered.reduce(0, +) / filtered.count
    }
    
    private func maxDouble(from values: [Double?]?) -> Double? {
        guard let values else { return nil }
        return values.compactMap { $0 }.filter { $0.isFinite }.max()
    }
    
    private func maxInt(from values: [Int?]?) -> Int? {
        guard let values else { return nil }
        return values.compactMap { $0 }.max()
    }
    
    private func estimatedLoadFromDistance(_ km: Double, _ hours: Double) -> Double {
        guard hours > 0 else { return 0 }
        // Simple heuristic: distance + time weighting
        return Swift.max(10, (km * 2) + (hours * 30))
    }
    
    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let hrs = Int(seconds) / 3600
        let mins = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02dh %02dm %02ds", hrs, mins, secs)
    }
    
    private func buildInsights(distanceKm: Double, avgSpeedKph: Double, elevation: Double, avgPower: Double?, np: Double?, intensityFactor: Double?, tss: Double?, avgHR: Int?, hrZones: HeartRateZoneSummary?, load: Double, weightKg: Double?) -> [String] {
        var items: [String] = []
        if distanceKm > 0 {
            items.append("Solid endurance: \(String(format: "%.1f", distanceKm)) km completed.")
        }
        if avgSpeedKph > 0 {
            items.append("Cruised at \(String(format: "%.1f", avgSpeedKph)) km/h average speed.")
        }
        if elevation > 300 {
            items.append("Climbed \(Int(elevation)) m — good hill stimulus.")
        }
        if let avgPower {
            items.append("Average power around \(Int(avgPower)) W indicates consistent pacing.")
        }
        if let np = np {
            var npLine = "Normalized power \(Int(np)) W"
            if let intensityFactor = intensityFactor {
                npLine += String(format: ", IF %.2f", intensityFactor)
            }
            items.append(npLine + ".")
        }
        if let tss {
            items.append("Estimated training load TSS ≈ \(Int(tss)).")
        } else {
            items.append("Estimated load: \(Int(load)).")
        }
        if let avgHR = avgHR {
            var hrLine = "Average HR \(avgHR) bpm shows sustainable aerobic effort."
            if let hrZones = hrZones {
                hrLine += " Zone distribution: \(hrZones.description)"
            }
            items.append(hrLine)
        }
        if let weightKg = weightKg {
            if weightKg > 0, let avgPower {
                items.append(String(format: "Power-to-weight: %.2f W/kg (avg).", avgPower / weightKg))
            } else {
                items.append("Log weight to refine W/kg insights.")
            }
        }
        return items
    }
    
    private func buildRecommendations(load: Double, elevation: Double, durationHrs: Double, intensityFactor: Double?, tss: Double?) -> [String] {
        var recs: [String] = []
        let effectiveLoad = tss ?? load
        if effectiveLoad > 100 {
            recs.append("High load — plan an easy spin or rest tomorrow.")
        } else if effectiveLoad > 60 {
            recs.append("Moderate load — consider tempo or sweet-spot tomorrow if recovered.")
        } else {
            recs.append("Light load — add intervals or a longer endurance ride next session.")
        }
        if elevation > 500 {
            recs.append("Include some flat cadence work to balance climbing fatigue.")
        }
        if durationHrs < 1.0 {
            recs.append("Extend endurance rides to 90–120 minutes for aerobic gains.")
        }
        if let intensityFactor = intensityFactor {
            if intensityFactor > 0.95 {
                recs.append(String(format: "IF %.2f suggests a near-threshold effort—schedule recovery or easy aerobic next.", intensityFactor))
            } else if intensityFactor < 0.70 {
                recs.append(String(format: "IF %.2f is low—add some tempo/threshold blocks to lift stimulus.", intensityFactor))
            }
        }
        return recs
    }
    
    private func recoveryAdvice(for load: Double) -> String {
        switch load {
        case ..<50:
            return "Recovery: light mobility and hydration should be enough."
        case 50..<90:
            return "Recovery: easy spin 20–40 minutes and good nutrition."
        default:
            return "Recovery: prioritize sleep, easy day tomorrow, and refuel with carbs/protein."
        }
    }
    
    private func performanceScore(load: Double, avgSpeed: Double, elevation: Double) -> Double {
        // Simple bounded score 0-100 using load and speed scaled by elevation
        let base = min(100, load)
        let speedBonus = min(10, avgSpeed / 3.0)
        let climbBonus = min(10, elevation / 300.0)
        return min(100, base * 0.6 + speedBonus + climbBonus)
    }

    // MARK: - Derived metrics
    
    private func normalizedPower(from powerData: [Double?]?, ftp: Double?) -> Double? {
        guard let samples = powerData?.compactMap({ $0 }).filter({ $0 > 0 }), !samples.isEmpty else {
            return nil
        }
        // Approximate NP using 4th power mean (simple variant)
        let fourthPowerMean = samples.map { pow($0, 4) }.reduce(0, +) / Double(samples.count)
        return pow(fourthPowerMean, 0.25)
    }
    
    private func trainingStressScore(np: Double?, duration: TimeInterval, ftp: Double?) -> Double? {
        guard let np, let ftp, ftp > 0 else { return nil }
        // Classic TSS formula: (sec * NP * IF) / (FTP * 3600) * 100
        let intensityFactor = np / ftp
        return (duration * np * intensityFactor) / (ftp * 3600.0) * 100.0
    }
    
    private struct HeartRateZoneSummary {
        let z1: Double
        let z2: Double
        let z3: Double
        let z4: Double
        let z5: Double
        
        var description: String {
            func pct(_ v: Double) -> String { String(format: "%.0f%%", v * 100) }
            return "Z1 \(pct(z1)), Z2 \(pct(z2)), Z3 \(pct(z3)), Z4 \(pct(z4)), Z5 \(pct(z5))"
        }
    }
    
    private func hrZoneDistribution(from data: [Int?]?, maxHR: Int) -> HeartRateZoneSummary {
        guard let data else {
            return HeartRateZoneSummary(z1: 0, z2: 0, z3: 0, z4: 0, z5: 0)
        }
        let valid = data.compactMap { $0 }.filter { $0 > 0 }
        guard !valid.isEmpty else {
            return HeartRateZoneSummary(z1: 0, z2: 0, z3: 0, z4: 0, z5: 0)
        }
        let counts = valid.reduce(into: [Int](repeating: 0, count: 5)) { acc, hr in
            let pct = Double(hr) / Double(maxHR)
            switch pct {
            case ..<0.60: acc[0] += 1
            case ..<0.75: acc[1] += 1
            case ..<0.85: acc[2] += 1
            case ..<0.95: acc[3] += 1
            default: acc[4] += 1
            }
        }
        let total = Double(valid.count)
        return HeartRateZoneSummary(
            z1: Double(counts[0]) / total,
            z2: Double(counts[1]) / total,
            z3: Double(counts[2]) / total,
            z4: Double(counts[3]) / total,
            z5: Double(counts[4]) / total
        )
    }

    private func buildRemotePrompt(activity: Activity, summary: String, np: Double?, intensityFactor: Double?, tss: Double?, hrZones: HeartRateZoneSummary?, weightKg: Double?) -> String {
        let distanceKm = activity.distance / 1000.0
        let durationHrs = activity.duration / 3600.0
        let elevation = activity.elevationGain
        let avgSpeedKph = durationHrs > 0 ? distanceKm / durationHrs : 0
        let avgPower = activity.powerAnalysis?.averagePower ?? average(from: activity.streams?.powerData)
        let avgHR = activity.heartRateAnalysis?.averageHR ?? average(from: activity.streams?.heartRateData)
        
        let streamSummary: String
        if let streams = activity.streams {
            let points = streams.timeData.count
            streamSummary = "Stream points: \(points); power=\(streams.hasData(in: streams.powerData)), hr=\(streams.hasData(in: streams.heartRateData)), cadence=\(streams.hasData(in: streams.cadenceData)), speed=\(streams.hasData(in: streams.speedData)), elevation=\(streams.hasData(in: streams.elevationData))."
        } else {
            streamSummary = "No stream data."
        }

        return """
骑行数据摘要（用于 AI 分析）：
- 距离：\(String(format: "%.1f", distanceKm)) km，时长：\(formattedDuration(activity.duration))，爬升：\(Int(elevation)) m
- 平均速度：\(String(format: "%.1f", avgSpeedKph)) km/h
- 平均功率：\(avgPower.map { String(Int($0)) + " W" } ?? "n/a")，NP：\(np.map { String(Int($0)) + " W" } ?? "n/a")，IF：\(intensityFactor.map { String(format: "%.2f", $0) } ?? "n/a")，TSS：\(tss.map { String(Int($0)) } ?? "n/a")
- 平均心率：\(avgHR.map { "\($0) bpm" } ?? "n/a")，心率区间：\(hrZones?.description ?? "n/a")
- 体重：\(weightKg.map { String(format: "%.1f kg", $0) } ?? "unknown")
- 流数据：\(streamSummary)

请基于以上数据生成结构化中文报告，包含：
1) 训练强度评估：AP/NP/IF、心率分布、Pa:Hr（如可能），指出强度合理性。
2) 训练效果评估：TSS/负荷、EF（若可推）、功率曲线要点，给出主要刺激类型与趋势。
3) 恢复与疲劳建议：结合负荷（若有 TSB/趋势也可），给出恢复时长与方式。
4) 改进与优化建议：技术/配速/区间训练方向，2-3 条可执行建议。
如数据不足，请说明限制。用标题+要点，语言专业但易懂。
"""
    }

    private func remoteSystemPrompt() -> String {
        return """
你是一位专业的骑行教练与运动生理数据分析专家，擅长通过功率、心率及训练负荷数据评估骑行表现，并提供个性化训练策略。
你的目标是生成系统化、专业但易懂的骑行训练分析报告。

分析报告需从以下方面展开（可根据数据完整性自动调整）：

### 一、训练强度评估
- 平均功率（AP）与标准化功率（NP），强度因子（IF）
- 心率分布区间，占比是否符合目标区间
- 最大/平均心率比值、功率-心率漂移（Pa:Hr）评估耐力稳定性
- 结论：强度过强/过弱/合理，给出原因

### 二、训练效果评估
- 训练负荷（TSS或等效负荷）、效率因子（EF=NP/HR）
- 功率曲线关键点（20min/5min/1min/30s）若有
- 可引用 CTL/ATL/TSB 趋势（若无则跳过）
- 结论：主要刺激类型、是否达成目标、趋势（提升/平台/疲劳）

### 三、恢复与疲劳建议
- 根据负荷/TSB（或主观感受假设）给出恢复需求
- 建议恢复时间、恢复类型（休息/低强度/交叉训练），说明依据

### 四、改进与优化建议
- 技术：踏频、功率平稳度(VI)、配速策略、上坡/平路输出一致性
- 训练结构：Tempo/Sweet Spot/VO2max 等区间强化建议
- 功率/心率分布优化，节奏控制

输出要求：
- 结构化报告（标题+要点），中文，专业但易懂
- 结合数据解释与训练意义，给出可执行建议
- 数据不足时说明限制并给出补充建议
"""
    }
}
