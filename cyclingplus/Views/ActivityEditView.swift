//
//  ActivityEditView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct ActivityEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let activity: Activity
    
    @State private var name: String
    @State private var notes: String = ""
    @State private var showingSaveConfirmation = false
    
    init(activity: Activity) {
        self.activity = activity
        _name = State(initialValue: activity.name)
    }
    
    var body: some View {
        Form {
            Section("Activity Details") {
                TextField("Activity Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes")
                        .font(.headline)
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .border(Color.gray.opacity(0.2))
                }
            }
            
            Section("Activity Information") {
                infoRow(label: "Date", value: activity.startDate.formatted(date: .long, time: .shortened))
                infoRow(label: "Source", value: activity.source.displayName)
                infoRow(label: "Distance", value: formatDistance(activity.distance))
                infoRow(label: "Duration", value: formatDuration(activity.duration))
                infoRow(label: "Elevation Gain", value: formatElevation(activity.elevationGain))
            }
            
            if activity.source == .strava, let stravaId = activity.stravaId {
                Section("Strava") {
                    infoRow(label: "Activity ID", value: "\(stravaId)")
                }
            }
            
            if activity.source == .igpsport, let rideId = activity.igpsportRideId {
                Section("iGPSport") {
                    infoRow(label: "Ride ID", value: "\(rideId)")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Edit Activity")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveChanges()
                }
                .disabled(name.isEmpty)
            }
        }
        .alert("Changes Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your changes have been saved successfully.")
        }
    }
    
    // MARK: - Helper Views
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
    
    // MARK: - Actions
    
    private func saveChanges() {
        activity.name = name
        activity.updatedAt = Date()
        
        do {
            try modelContext.save()
            showingSaveConfirmation = true
        } catch {
            print("Failed to save changes: \(error)")
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
            return String(format: "%dh %dm %ds", hours, minutes, secs)
        } else {
            return String(format: "%dm %ds", minutes, secs)
        }
    }
    
    private func formatElevation(_ meters: Double) -> String {
        return String(format: "%.0f m", meters)
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
    
    container.mainContext.insert(activity)
    
    return NavigationStack {
        ActivityEditView(activity: activity)
    }
    .modelContainer(container)
    .frame(width: 600, height: 500)
}
