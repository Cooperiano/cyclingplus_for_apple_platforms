//
//  ActivityListView.swift
//  cyclingplus
//
//  Created by Kiro on 2025/11/7.
//

import SwiftUI
import SwiftData

struct ActivityListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.startDate, order: .reverse) private var activities: [Activity]
    
    @State private var searchText = ""
    @State private var selectedSource: ActivitySource?
    @State private var sortOrder: SortOrder = .dateDescending
    @State private var selectedActivity: Activity?
    @State private var selectionMode = false
    @State private var selectedActivityIDs = Set<String>()
    @State private var showingBulkDeleteAlert = false
    
    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Toolbar
                toolbar
                
                // Activity list
                contentList
            }
            .navigationTitle("Activities")
        } detail: {
            if let activity = selectedActivity {
                ActivityDetailView(activity: activity)
            } else {
                emptyDetailView
            }
        }
        .searchable(text: $searchText, prompt: "Search activities")
        .alert("Delete Activities", isPresented: $showingBulkDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSelectedActivities()
            }
        } message: {
            Text(bulkDeleteAlertMessage)
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbar: some View {
        HStack(spacing: 12) {
            // Source filter
            Menu {
                Button("All Sources") {
                    selectedSource = nil
                }
                Divider()
                ForEach(ActivitySource.allCases, id: \.self) { source in
                    Button(source.displayName) {
                        selectedSource = source
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedSource?.displayName ?? "All Sources")
                }
            }
            .buttonStyle(.bordered)
            
            // Sort order
            Menu {
                Button("Date (Newest First)") {
                    sortOrder = .dateDescending
                }
                Button("Date (Oldest First)") {
                    sortOrder = .dateAscending
                }
                Button("Distance (Longest)") {
                    sortOrder = .distanceDescending
                }
                Button("Duration (Longest)") {
                    sortOrder = .durationDescending
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                    Text(sortOrder.displayName)
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            if selectionMode {
                Text(selectionSummaryText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button {
                    toggleSelectAll()
                } label: {
                    Text(areAllSelected ? "Clear All" : "Select All")
                }
                .buttonStyle(.bordered)
                .disabled(filteredActivities.isEmpty)
            } else {
                Text("\(filteredActivities.count) activities")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            Button {
                toggleSelectionMode()
            } label: {
                Label(selectionMode ? "Done" : "Batch Manage", systemImage: selectionMode ? "checkmark.circle" : "checklist.unchecked")
            }
            .buttonStyle(.borderedProminent)
            
            if selectionMode {
                Button(role: .destructive) {
                    showingBulkDeleteAlert = true
                } label: {
                    Label("Delete Selected", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(selectedActivityIDs.isEmpty)
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
    }
    
    // MARK: - Empty States
    
    private var contentList: some View {
        Group {
            if filteredActivities.isEmpty {
                emptyStateView
            } else {
                if selectionMode {
                    selectionList
                } else {
                    navigationList
                }
            }
        }
    }
    
    private var navigationList: some View {
        List(selection: $selectedActivity) {
            ForEach(filteredActivities) { activity in
                NavigationLink(value: activity) {
                    ActivityRowView(activity: activity)
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    private var selectionList: some View {
        List {
            ForEach(filteredActivities) { activity in
                Button {
                    toggleSelection(for: activity)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSelected(activity) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected(activity) ? .accentColor : .secondary)
                            .frame(width: 20)
                        
                        ActivityRowView(activity: activity)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.outdoor.cycle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Activities")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect to Strava or import files to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.left")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select an Activity")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose an activity from the list to view details")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Computed Properties
    
    private var filteredActivities: [Activity] {
        var filtered = activities
        
        // Apply source filter
        if let source = selectedSource {
            filtered = filtered.filter { $0.source == source }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { activity in
                activity.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort order
        switch sortOrder {
        case .dateDescending:
            filtered.sort { $0.startDate > $1.startDate }
        case .dateAscending:
            filtered.sort { $0.startDate < $1.startDate }
        case .distanceDescending:
            filtered.sort { $0.distance > $1.distance }
        case .durationDescending:
            filtered.sort { $0.duration > $1.duration }
        }
        
        return filtered
    }
    
    private var selectionSummaryText: String {
        let count = selectedActivityIDs.count
        if count == 0 {
            return "No activities selected"
        } else if count == 1 {
            return "1 activity selected"
        } else {
            return "\(count) activities selected"
        }
    }
    
    private var bulkDeleteAlertMessage: String {
        let count = selectedActivityIDs.count
        if count == 1 {
            return "Delete the selected activity? This action cannot be undone."
        }
        return "Delete \(count) activities? This action cannot be undone."
    }
    
    private func toggleSelectionMode() {
        withAnimation {
            selectionMode.toggle()
            
            if selectionMode {
                selectedActivity = nil
            } else {
                selectedActivityIDs.removeAll()
            }
        }
    }
    
    private func toggleSelection(for activity: Activity) {
        if selectedActivityIDs.contains(activity.id) {
            selectedActivityIDs.remove(activity.id)
        } else {
            selectedActivityIDs.insert(activity.id)
        }
    }
    
    private var areAllSelected: Bool {
        !filteredActivities.isEmpty && selectedActivityIDs.count == filteredActivities.count
    }
    
    private func toggleSelectAll() {
        if areAllSelected {
            selectedActivityIDs.removeAll()
        } else {
            selectedActivityIDs = Set(filteredActivities.map { $0.id })
        }
    }
    
    private func isSelected(_ activity: Activity) -> Bool {
        selectedActivityIDs.contains(activity.id)
    }
    
    private func deleteSelectedActivities() {
        guard !selectedActivityIDs.isEmpty else { return }
        
        let toDelete = activities.filter { selectedActivityIDs.contains($0.id) }
        
        for activity in toDelete {
            modelContext.delete(activity)
        }
        
        do {
            try modelContext.save()
            selectedActivityIDs.removeAll()
            selectionMode = false
        } catch {
            print("Failed to delete activities: \(error)")
        }
    }
}

// MARK: - Activity Row View

struct ActivityRowView: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 12) {
            // Source icon
            Image(systemName: sourceIcon)
                .font(.title3)
                .foregroundColor(sourceColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // Activity name
                Text(activity.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Date
                Text(activity.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Metrics
                HStack(spacing: 12) {
                    metricLabel(icon: "ruler", value: formatDistance(activity.distance))
                    metricLabel(icon: "timer", value: formatDuration(activity.duration))
                    metricLabel(icon: "arrow.up.right", value: formatElevation(activity.elevationGain))
                    
                    if let avgPower = activity.powerAnalysis?.averagePower {
                        metricLabel(icon: "bolt.fill", value: "\(Int(avgPower))W")
                    }
                }
                .font(.caption)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func metricLabel(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private var sourceIcon: String {
        switch activity.source {
        case .strava: return "figure.outdoor.cycle"
        case .igpsport: return "antenna.radiowaves.left.and.right"
        case .gpx, .tcx, .fit: return "doc.fill"
        }
    }
    
    private var sourceColor: Color {
        switch activity.source {
        case .strava: return .orange
        case .igpsport: return .blue
        case .gpx, .tcx, .fit: return .green
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        let km = meters / 1000.0
        return String(format: "%.1fkm", km)
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return String(format: "%dh%dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func formatElevation(_ meters: Double) -> String {
        return String(format: "%.0fm", meters)
    }
}

// MARK: - Supporting Types

enum SortOrder {
    case dateDescending
    case dateAscending
    case distanceDescending
    case durationDescending
    
    var displayName: String {
        switch self {
        case .dateDescending: return "Newest First"
        case .dateAscending: return "Oldest First"
        case .distanceDescending: return "Longest Distance"
        case .durationDescending: return "Longest Duration"
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Activity.self, configurations: config)
    
    // Create sample activities
    for i in 1...10 {
        let activity = Activity(
            name: "Ride \(i)",
            startDate: Date().addingTimeInterval(-Double(i) * 86400),
            distance: Double.random(in: 20000...80000),
            duration: Double.random(in: 1800...7200),
            elevationGain: Double.random(in: 200...1000),
            source: ActivitySource.allCases.randomElement()!
        )
        container.mainContext.insert(activity)
    }
    
    return ActivityListView()
        .modelContainer(container)
        .frame(width: 1200, height: 800)
}
