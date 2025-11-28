//
//  FileImportView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct FileImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var isImporting = false
    @State private var importProgress: Double = 0.0
    @State private var importStatus: String = ""
    @State private var importedActivities: [Activity] = []
    @State private var importErrors: [String] = []
    @State private var showFilePicker = false
    @State private var selectedFileType: FileFormat = .gpx
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !isImporting && importedActivities.isEmpty {
                    dropZoneView
                } else if isImporting {
                    importingView
                } else {
                    resultsView
                }
            }
            .padding()
            .navigationTitle("Import Activities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: allowedFileTypes,
                allowsMultipleSelection: true
            ) { result in
                handleFileSelection(result)
            }
        }
    }
    
    private var dropZoneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Import Activity Files")
                .font(.title2)
                .bold()
            
            Text("Drag and drop GPX, TCX, or FIT files here, or click to browse")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                fileTypeSelector
                
                Button("Browse Files") {
                    showFilePicker = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            supportedFormatsInfo
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(.blue.opacity(0.5))
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private var fileTypeSelector: some View {
        Picker("File Type", selection: $selectedFileType) {
            Text("GPX").tag(FileFormat.gpx)
            Text("TCX").tag(FileFormat.tcx)
            Text("FIT").tag(FileFormat.fit)
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 300)
    }
    
    private var supportedFormatsInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supported Formats:")
                .font(.caption)
                .bold()
            
            FormatInfoRow(format: "GPX", description: "GPS Exchange Format")
            FormatInfoRow(format: "TCX", description: "Training Center XML")
            FormatInfoRow(format: "FIT", description: "Flexible and Interoperable Data Transfer")
        }
        .padding()
        #if os(macOS)
        #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
        #else
        .background(Color(.secondarySystemBackground))
        #endif
        .cornerRadius(8)
    }
    
    private var importingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: importProgress) {
                Text("Importing Activities...")
                    .font(.headline)
            }
            .progressViewStyle(LinearProgressViewStyle())
            
            Text(importStatus)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Cancel") {
                cancelImport()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private var resultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Import Complete")
                .font(.title2)
                .bold()
            
            VStack(spacing: 8) {
                Text("\(importedActivities.count) activities imported successfully")
                    .font(.body)
                
                if !importErrors.isEmpty {
                    Text("\(importErrors.count) files failed to import")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if !importErrors.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Errors:")
                            .font(.caption)
                            .bold()
                        
                        ForEach(importErrors, id: \.self) { error in
                            Text(error)
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    #if os(macOS)
                    #if os(macOS)
                .background(Color(nsColor: .controlBackgroundColor))
                #else
                .background(Color(.secondarySystemBackground))
                #endif
                    #else
                    .background(Color(.secondarySystemBackground))
                    #endif
                    .cornerRadius(8)
                }
                .frame(maxHeight: 150)
            }
            
            HStack(spacing: 12) {
                Button("Import More") {
                    resetImport()
                }
                .buttonStyle(.bordered)
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - File Handling
    
    private var allowedFileTypes: [UTType] {
        switch selectedFileType {
        case .gpx:
            return [UTType(filenameExtension: "gpx") ?? .xml]
        case .tcx:
            return [UTType(filenameExtension: "tcx") ?? .xml]
        case .fit:
            return [UTType(filenameExtension: "fit") ?? .data]
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                    Task { @MainActor in
                        await importFile(url: url)
                    }
                }
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await importFiles(urls: urls)
            }
        case .failure(let error):
            importErrors.append("File selection failed: \(error.localizedDescription)")
        }
    }
    
    private func importFiles(urls: [URL]) async {
        isImporting = true
        importProgress = 0.0
        importedActivities.removeAll()
        importErrors.removeAll()
        
        for (index, url) in urls.enumerated() {
            importStatus = "Importing \(index + 1) of \(urls.count)..."
            await importFile(url: url)
            importProgress = Double(index + 1) / Double(urls.count)
        }
        
        isImporting = false
    }
    
    @MainActor
    private func importFile(url: URL) async {
        do {
            // Ensure we have access to the file
            guard url.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "FileImport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Parse the file using FileParsingService
            let parsingService = FileParsingService()
            let (activity, streams) = try parseFileByType(url: url, parsingService: parsingService)
            let repository = DataRepository(modelContext: modelContext)
            
            if let duplicate = try repository.findDuplicateActivity(
                similarTo: activity,
                timeTolerance: 30,
                distanceTolerance: 50,
                durationTolerance: 30
            ) {
                throw NSError(
                    domain: "FileImport",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Activity already exists (matches '\(duplicate.name)')"]
                )
            }
            
            // Save activity to database
            modelContext.insert(activity)
            
            // Save streams if available
            if let streams = streams {
                streams.activity = activity
                activity.streams = streams
                modelContext.insert(streams)
            }
            
            try modelContext.save()
            
            importedActivities.append(activity)
        } catch {
            importErrors.append("\(url.lastPathComponent): \(error.localizedDescription)")
        }
    }
    
    private func parseFileByType(url: URL, parsingService: FileParsingService) throws -> (Activity, ActivityStreams?) {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "gpx":
            return try parsingService.parseGPXFile(from: url)
        case "tcx":
            return try parsingService.parseTCXFile(from: url)
        case "fit":
            return try parsingService.parseFITFile(from: url)
        default:
            throw NSError(domain: "FileImport", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unsupported file format: \(fileExtension)"])
        }
    }
    
    private func cancelImport() {
        isImporting = false
        importStatus = "Import cancelled"
    }
    
    private func resetImport() {
        importedActivities.removeAll()
        importErrors.removeAll()
        importProgress = 0.0
        importStatus = ""
    }
}

struct FormatInfoRow: View {
    let format: String
    let description: String
    
    var body: some View {
        HStack {
            Text(format)
                .font(.caption)
                .bold()
                .frame(width: 40, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

enum FileFormat {
    case gpx, tcx, fit
}

#Preview {
    FileImportView()
        .modelContainer(for: Activity.self, inMemory: true)
}
