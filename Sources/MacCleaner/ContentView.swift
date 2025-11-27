import SwiftUI

struct ContentView: View {
    @StateObject private var scanner = Scanner()
    @StateObject private var largeFileScanner = LargeFileScanner()
    @StateObject private var dockerCleaner = DockerCleaner.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isCleaning = false
    @State private var showingDockerCleanup = false
    @State private var selectedDockerLevel: DockerCleaner.CleanupLevel = .unused
    
    var body: some View {
        VStack(spacing: 20) {
            Text("MacCleaner")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            if scanner.isScanning || largeFileScanner.isScanning {
                ProgressView("Scanning System Data...")
                    .padding()
            } else if isCleaning {
                ProgressView("Cleaning Selected Files...")
                    .padding()
            } else {
                List {
                    Section(header: Text("Safe to Clean")) {
                        ForEach($scanner.items) { $item in
                            HStack {
                                Toggle(isOn: $item.isSelected) {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.path)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.formattedSize)
                                    .font(.system(.body, design: .monospaced))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    if !largeFileScanner.items.isEmpty {
                        Section(header: Text("Large System Folders (Review Only)")) {
                            ForEach(largeFileScanner.items) { item in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.headline)
                                        Text(item.path)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text(item.formattedSize)
                                        .font(.system(.body, design: .monospaced))
                                    Button("Reveal") {
                                        NSWorkspace.shared.selectFile(item.path, inFileViewerRootedAtPath: "")
                                    }
                                    .buttonStyle(.link)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    if dockerCleaner.isDockerAvailable {
                        Section(header: Text("Docker Cleanup")) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Docker Containers: \(dockerCleaner.containerCount)")
                                        .font(.headline)
                                    Text("Docker Images: \(dockerCleaner.imageCount)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Clean Docker...") {
                                    showingDockerCleanup = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(.inset)
                .frame(minHeight: 300)
                
                HStack {
                    Text("Total Reclaimable:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formatBytes(scanner.totalSize))
                        .font(.title2)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    scanner.scan()
                    largeFileScanner.scan()
                }) {
                    Label("Scan", systemImage: "magnifyingglass")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .disabled(scanner.isScanning || largeFileScanner.isScanning || isCleaning)
                
                Button(action: {
                    cleanSelected()
                }) {
                    Label("Clean Selected", systemImage: "trash")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(scanner.isScanning || largeFileScanner.isScanning || isCleaning || scanner.items.isEmpty || scanner.totalSize == 0)
            }
            .padding(.bottom)
        }
        .frame(minWidth: 600, minHeight: 500)
        .padding()
        .alert("Cleaning Report", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingDockerCleanup) {
            DockerCleanupView(
                dockerCleaner: dockerCleaner,
                onCancel: { showingDockerCleanup = false },
                onClean: cleanDocker
            )
        }
        .onAppear {
            dockerCleaner.checkDocker()
        }
    }
    
    private func cleanDocker(_ items: [DockerItem]) {
        showingDockerCleanup = false
        isCleaning = true
        
        dockerCleaner.cleanSelected(items: items) { success, output in
            isCleaning = false
            
            if success {
                let totalSize = items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
                alertMessage = "Docker cleanup completed!\n\nRemoved \(formatBytes(totalSize))"
            } else {
                alertMessage = "Docker cleanup encountered issues.\n\nOutput:\n\(output)"
            }
            showingAlert = true
        }
    }
    
    private func cleanSelected() {
        let selectedItems = scanner.items.filter { $0.isSelected }
        guard !selectedItems.isEmpty else { return }
        
        isCleaning = true
        
        Cleaner.shared.clean(items: selectedItems) { cleanedBytes, errorCount, lastError in
            isCleaning = false
            scanner.scan() // Rescan after cleaning
            
            let sizeStr = formatBytes(cleanedBytes)
            if errorCount > 0 {
                alertMessage = "Cleaned \(sizeStr).\n\nEncountered \(errorCount) errors.\nLast Error: \(lastError ?? "Unknown")"
            } else {
                alertMessage = "Successfully cleaned \(sizeStr)!"
            }
            showingAlert = true
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
