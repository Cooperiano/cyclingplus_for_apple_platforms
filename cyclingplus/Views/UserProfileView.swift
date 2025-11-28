//
//  UserProfileView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct UserProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    
    @State private var name: String = ""
    @State private var weight: String = ""
    @State private var ftp: String = ""
    @State private var maxHR: String = ""
    @State private var restingHR: String = ""
    @State private var lthr: String = ""
    @State private var showingSaveConfirmation = false
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        Form {
            Section("Personal Information") {
                TextField("Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                HStack {
                    TextField("Weight", text: $weight)
                        .textFieldStyle(.roundedBorder)
                    Text("kg")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Power Zones") {
                HStack {
                    TextField("FTP (Functional Threshold Power)", text: $ftp)
                        .textFieldStyle(.roundedBorder)
                    Text("watts")
                        .foregroundColor(.secondary)
                }
                
                if let ftpValue = Double(ftp), ftpValue > 0 {
                    powerZonesPreview(ftp: ftpValue)
                }
            }
            
            Section("Heart Rate Zones") {
                HStack {
                    TextField("Max Heart Rate", text: $maxHR)
                        .textFieldStyle(.roundedBorder)
                    Text("bpm")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Resting Heart Rate", text: $restingHR)
                        .textFieldStyle(.roundedBorder)
                    Text("bpm")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    TextField("Lactate Threshold HR", text: $lthr)
                        .textFieldStyle(.roundedBorder)
                    Text("bpm")
                        .foregroundColor(.secondary)
                }
                
                if let maxHRValue = Int(maxHR), let restingHRValue = Int(restingHR),
                   maxHRValue > restingHRValue {
                    heartRateZonesPreview(maxHR: maxHRValue, restingHR: restingHRValue)
                }
            }
            
            Section {
                Button("Save Profile") {
                    saveProfile()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("User Profile")
        .onAppear {
            loadProfile()
        }
        .onChange(of: profiles) { oldValue, newValue in
            loadProfile()
        }
        .alert("Profile Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your profile has been saved successfully. Power and heart rate zones have been calculated.")
        }
    }
    
    // MARK: - Zone Previews
    
    private func powerZonesPreview(ftp: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Power Zones")
                .font(.headline)
                .padding(.top, 8)
            
            zoneRow(number: 1, name: "Active Recovery", range: "< \(Int(ftp * 0.55))W", color: .gray)
            zoneRow(number: 2, name: "Endurance", range: "\(Int(ftp * 0.55))-\(Int(ftp * 0.75))W", color: .blue)
            zoneRow(number: 3, name: "Tempo", range: "\(Int(ftp * 0.76))-\(Int(ftp * 0.90))W", color: .green)
            zoneRow(number: 4, name: "Lactate Threshold", range: "\(Int(ftp * 0.91))-\(Int(ftp * 1.05))W", color: .yellow)
            zoneRow(number: 5, name: "VO2 Max", range: "\(Int(ftp * 1.06))-\(Int(ftp * 1.20))W", color: .orange)
            zoneRow(number: 6, name: "Anaerobic", range: "\(Int(ftp * 1.21))-\(Int(ftp * 1.50))W", color: .red)
            zoneRow(number: 7, name: "Neuromuscular", range: "> \(Int(ftp * 1.50))W", color: .purple)
        }
        .padding(.vertical, 8)
    }
    
    private func heartRateZonesPreview(maxHR: Int, restingHR: Int) -> some View {
        let hrReserve = maxHR - restingHR
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Heart Rate Zones")
                .font(.headline)
                .padding(.top, 8)
            
            zoneRow(number: 1, name: "Recovery", range: "< \(restingHR + Int(Double(hrReserve) * 0.60)) bpm", color: .gray)
            zoneRow(number: 2, name: "Aerobic", range: "\(restingHR + Int(Double(hrReserve) * 0.60))-\(restingHR + Int(Double(hrReserve) * 0.70)) bpm", color: .blue)
            zoneRow(number: 3, name: "Tempo", range: "\(restingHR + Int(Double(hrReserve) * 0.70))-\(restingHR + Int(Double(hrReserve) * 0.80)) bpm", color: .green)
            zoneRow(number: 4, name: "Threshold", range: "\(restingHR + Int(Double(hrReserve) * 0.80))-\(restingHR + Int(Double(hrReserve) * 0.90)) bpm", color: .orange)
            zoneRow(number: 5, name: "Maximum", range: "\(restingHR + Int(Double(hrReserve) * 0.90))-\(maxHR) bpm", color: .red)
        }
        .padding(.vertical, 8)
    }
    
    private func zoneRow(number: Int, name: String, range: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            Text("Z\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 30, alignment: .leading)
            Text(name)
                .font(.caption)
                .frame(width: 120, alignment: .leading)
            Text(range)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Actions
    
    private func loadProfile() {
        if let profile = currentProfile {
            name = profile.name
            weight = profile.weight.map { String(format: "%.1f", $0) } ?? ""
            ftp = profile.ftp.map { String(format: "%.0f", $0) } ?? ""
            maxHR = profile.maxHeartRate.map { String($0) } ?? ""
            restingHR = profile.restingHeartRate.map { String($0) } ?? ""
            lthr = profile.lactateThresholdHR.map { String($0) } ?? ""
        }
    }
    
    private func saveProfile() {
        let profile = currentProfile ?? UserProfile(name: name)
        
        profile.name = name
        profile.weight = Double(weight)
        profile.ftp = Double(ftp)
        profile.maxHeartRate = Int(maxHR)
        profile.restingHeartRate = Int(restingHR)
        profile.lactateThresholdHR = Int(lthr)
        profile.updatedAt = Date()
        
        // Calculate zones
        profile.calculatePowerZones()
        profile.calculateHeartRateZones()
        
        if currentProfile == nil {
            modelContext.insert(profile)
        }
        
        do {
            try modelContext.save()
            showingSaveConfirmation = true
        } catch {
            print("Failed to save profile: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, configurations: config)
    
    return NavigationStack {
        UserProfileView()
    }
    .modelContainer(container)
    .frame(width: 700, height: 800)
}
