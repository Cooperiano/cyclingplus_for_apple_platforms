//
//  ActivityActionsView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ActivityActionsView: View {
    let activity: Activity
    
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingExportDialog = false
    @State private var selectedExportFormat: ActivityExportService.ExportFormat = .gpx
    @State private var exportError: Error?
    @State private var showingExportError = false
    
    private let exportService = ActivityExportService()
    
    var body: some View {
        Menu {
            // Edit action
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Activity", systemImage: "pencil")
            }
            
            Divider()
            
            // Export submenu
            Menu {
                ForEach(ActivityExportService.ExportFormat.allCases, id: \.self) { format in
                    Button {
                        selectedExportFormat = format
                        exportActivity(format: format)
                    } label: {
                        Label("Export as \(format.rawValue)", systemImage: "square.and.arrow.up")
                    }
                }
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            
            Divider()
            
            // Delete action
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Delete Activity", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                ActivityEditView(activity: activity)
            }
        }
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteActivity()
            }
        } message: {
            Text("Are you sure you want to delete '\(activity.name)'? This action cannot be undone.")
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = exportError {
                Text(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Actions
    
    private func exportActivity(format: ActivityExportService.ExportFormat) {
        do {
            let data = try exportService.exportActivity(activity, format: format)
            let filename = exportService.suggestedFilename(for: activity, format: format)
            
            #if os(macOS)
            // macOS: Show save panel
            let savePanel = NSSavePanel()
            savePanel.nameFieldStringValue = filename
            savePanel.allowedContentTypes = [format.utType]
            savePanel.canCreateDirectories = true
            
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    do {
                        try data.write(to: url)
                    } catch {
                        exportError = error
                        showingExportError = true
                    }
                }
            }
            #else
            // iOS: Save to temporary directory and share
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            
            // Present share sheet
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
            #endif
        } catch {
            exportError = error
            showingExportError = true
        }
    }
    
    private func deleteActivity() {
        modelContext.delete(activity)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete activity: \(error)")
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
        timeData: (0..<100).map { Double($0) },
        powerData: (0..<100).map { _ in Optional(200.0) },
        heartRateData: (0..<100).map { _ in Optional(145) }
    )
    
    activity.streams = streams
    container.mainContext.insert(activity)
    
    return ActivityActionsView(activity: activity)
        .modelContainer(container)
        .padding()
}
