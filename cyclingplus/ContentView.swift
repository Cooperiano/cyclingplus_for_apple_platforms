//
//  ContentView.swift
//  cyclingplus
//
//  Created by Julian Cooper on 2025/11/5.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Activity.startDate, order: .reverse) private var activities: [Activity]
    @State private var dataRepository: DataRepository?
    @State private var showingSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Top toolbar with connection status and sync
            HStack(spacing: 12) {
                ConnectionStatusWidget()
                
                Spacer()
                
                // Manual sync buttons
                ToolbarSyncButtons()
                
                SyncMenuButton()
                
                // Settings button with better hit area
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.title3)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help("Settings")
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
            
            // Main content
            if activities.isEmpty {
                EmptyStateView(modelContext: modelContext)
            } else {
                ActivityListView()
            }
        }
        .onAppear {
            // Initialize repository with the actual modelContext
            if dataRepository == nil {
                dataRepository = DataRepository(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// Note: ActivityListView, ActivityRowView, and ActivityDetailView are now in separate files

struct EmptyStateView: View {
    let modelContext: ModelContext
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bicycle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("No Activities Yet")
                .font(.title2)
                .bold()
            
            Text("Import files or sync with Strava/iGPSport to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Create Sample Activity") {
                Task {
                    try? SampleDataService.createSampleActivity(in: modelContext)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bicycle.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to CyclingPlus")
                .font(.largeTitle)
                .bold()
            
            Text("Your comprehensive cycling data analysis companion")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced power analysis")
                FeatureRow(icon: "heart.fill", text: "Heart rate zone analysis")
                FeatureRow(icon: "brain.head.profile", text: "AI-powered insights")
                FeatureRow(icon: "doc.badge.plus", text: "Import GPX, TCX, FIT files")
                FeatureRow(icon: "arrow.clockwise", text: "Sync with Strava & iGPSport")
            }
            .padding()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Activity.self, inMemory: true)
}
