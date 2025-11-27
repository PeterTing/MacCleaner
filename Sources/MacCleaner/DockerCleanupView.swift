import SwiftUI

struct DockerCleanupView: View {
    @ObservedObject var dockerCleaner: DockerCleaner
    let onCancel: () -> Void
    let onClean: ([DockerItem]) -> Void
    
    var totalSize: Int64 {
        dockerCleaner.items.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Docker Cleanup")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            if dockerCleaner.isScanning {
                ProgressView("Scanning Docker volumes...")
                    .padding()
            } else if dockerCleaner.items.isEmpty {
                VStack {
                    Text("No unused Docker volumes found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("All volumes are in use or already cleaned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                VStack(alignment: .leading) {
                    Text("Unused Volumes (Not attached to any container)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    List {
                        ForEach(Array(dockerCleaner.items.enumerated()), id: \.element.id) { index, item in
                            HStack {
                                Toggle(isOn: Binding(
                                    get: { dockerCleaner.items[index].isSelected },
                                    set: { dockerCleaner.items[index].isSelected = $0 }
                                )) {
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .font(.system(.body, design: .monospaced))
                                            .lineLimit(1)
                                        Text(item.type.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Text(item.formattedSize)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                    .frame(height: 300)
                    
                    HStack {
                        Text("Total Selected:")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(formatBytes(totalSize))
                            .font(.headline)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
            }
            
            HStack(spacing: 20) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Button("Rescan") {
                    dockerCleaner.scanItems()
                }
                .buttonStyle(.bordered)
                .disabled(dockerCleaner.isScanning)
                
                Button("Delete Selected") {
                    onClean(dockerCleaner.items.filter { $0.isSelected })
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(dockerCleaner.items.isEmpty || dockerCleaner.items.filter { $0.isSelected }.isEmpty || dockerCleaner.isScanning)
            }
            .padding(.bottom)
        }
        .frame(width: 700, height: 500)
        .padding()
        .onAppear {
            dockerCleaner.scanItems()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

