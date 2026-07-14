import AppKit
import MacDeepCleanerCore
import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var confirmingClean = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Large Files").font(.largeTitle.bold())
                Spacer()
                Picker("Size", selection: $viewModel.selectedLargeThreshold) {
                    Text("> 100 MB").tag(Int64(100 * 1024 * 1024))
                    Text("> 500 MB").tag(Int64(500 * 1024 * 1024))
                    Text("> 1 GB").tag(Int64(1024 * 1024 * 1024))
                    Text("> 5 GB").tag(Int64(5 * 1024 * 1024 * 1024))
                }
                Picker("Age", selection: $viewModel.selectedOldDays) {
                    Text("Any").tag(nil as Int?)
                    Text("30 days").tag(Optional(30))
                    Text("90 days").tag(Optional(90))
                    Text("180 days").tag(Optional(180))
                    Text("365 days").tag(Optional(365))
                }
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanLargeFiles)
                Button("Move to Trash", systemImage: "trash") { confirmingClean = true }
                    .disabled(viewModel.selectedItems.isEmpty)
            }
            ResultTable(items: viewModel.largeFiles, selection: $viewModel.selectedItems)
        }
        .padding(20)
        .confirmationDialog("Move selected files to Trash?", isPresented: $confirmingClean) {
            Button("Move to Trash", role: .destructive) { viewModel.cleanSelected(from: viewModel.largeFiles) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Large or old files are not automatically junk. Review each file first.")
        }
    }
}

struct ApplicationsView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var selectedApp: ApplicationInfo.ID?
    @State private var confirmingUninstall = false

    var selected: ApplicationInfo? {
        viewModel.applications.first { $0.id == selectedApp }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Applications").font(.largeTitle.bold())
                Spacer()
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanApplications)
            }
            HSplitView {
                Table(viewModel.applications, selection: $selectedApp) {
                    TableColumn("Name") { Text($0.name) }
                    TableColumn("Bundle ID") { Text($0.bundleIdentifier ?? "-") }
                    TableColumn("Version") { Text($0.version ?? "-") }
                    TableColumn("Size") { Text(ByteFormatting.string($0.size)) }
                    TableColumn("Last Used") { Text($0.lastAccessed?.formatted(date: .abbreviated, time: .omitted) ?? "-") }
                }
                VStack(alignment: .leading) {
                    Text("Related Files").font(.headline)
                    if let selected {
                        ResultTable(items: selected.leftovers, selection: $viewModel.selectedItems)
                        Button("Move Selected to Trash", systemImage: "trash") {
                            viewModel.cleanSelected(from: selected.leftovers)
                        }
                        .disabled(viewModel.selectedItems.isEmpty)
                        Button("Uninstall App", systemImage: "app.badge") {
                            confirmingUninstall = true
                        }
                    } else {
                        ContentUnavailableView("Select an app", systemImage: "app")
                    }
                }
                .frame(minWidth: 420)
            }
        }
        .padding(20)
        .confirmationDialog("Move app to Trash?", isPresented: $confirmingUninstall) {
            Button("Move to Trash", role: .destructive) {
                guard let selected else { return }
                let appItem = ScanItem(
                    url: selected.url,
                    size: selected.size,
                    category: .applications,
                    riskLevel: .review,
                    isDirectory: true,
                    lastAccessed: selected.lastAccessed,
                    typeDescription: "Application",
                    warning: "Application bundle selected by user."
                )
                let leftovers = selected.leftovers.filter { viewModel.selectedItems.contains($0.id) }
                viewModel.clean([appItem] + leftovers)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The app bundle and checked related files move to Trash. Group containers remain Review only.")
        }
    }
}

struct BackupsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("iOS Backups").font(.largeTitle.bold())
                Spacer()
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanBackups)
            }
            Table(viewModel.backups) {
                TableColumn("Device") { Text($0.deviceName ?? "Unknown device") }
                TableColumn("Date") { Text($0.backupDate?.formatted(date: .abbreviated, time: .omitted) ?? "-") }
                TableColumn("iOS") { Text($0.iOSVersion ?? "-") }
                TableColumn("Encrypted") { Text(($0.encrypted ?? false) ? "Yes" : "Unknown/No") }
                TableColumn("Size") { Text(ByteFormatting.string($0.size)) }
                TableColumn("Path") { Text($0.url.path).lineLimit(1).foregroundStyle(.secondary) }
            }
        }
        .padding(20)
    }
}

struct DuplicatesView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Duplicates").font(.largeTitle.bold())
                Spacer()
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanDuplicates)
            }
            List(viewModel.duplicateGroups) { group in
                Section("\(ByteFormatting.string(group.size)) · \(group.files.count) files") {
                    ForEach(group.files) { item in
                        HStack {
                            Text(item.url.path)
                            Spacer()
                            Button("", systemImage: "eye") { QuickLookController.shared.preview(item.url) }
                            Button("", systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                        }
                    }
                }
            }
        }
        .padding(20)
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cleaning History").font(.largeTitle.bold())
            Table(viewModel.history) {
                TableColumn("Date") { Text($0.date.formatted(date: .abbreviated, time: .shortened)) }
                TableColumn("Category") { Text($0.category.rawValue) }
                TableColumn("Size") { Text(ByteFormatting.string($0.bytes)) }
                TableColumn("Files") { Text("\($0.paths.count)") }
            }
        }
        .padding(20)
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        Form {
            Section("Scanning") {
                Toggle("Follow symbolic links", isOn: $viewModel.options.followSymbolicLinks)
                Toggle("Scan external volumes", isOn: $viewModel.options.scanExternalVolumes)
                Toggle("Scan network volumes", isOn: $viewModel.options.scanNetworkVolumes)
                Toggle("Show hidden files", isOn: $viewModel.options.showHiddenFiles)
                Toggle("Developer mode", isOn: $viewModel.options.developerMode)
                Stepper("Old file threshold: \(viewModel.options.oldFileDays) days", value: $viewModel.options.oldFileDays, in: 1...3650)
            }
            Section("Safety") {
                Toggle("Confirmation before cleaning", isOn: .constant(true))
                Toggle("Permanent deletion", isOn: .constant(false))
                    .disabled(true)
                Text("Permanent deletion is intentionally disabled in this build. Trash is the default workflow.")
                    .foregroundStyle(.secondary)
            }
            Section("Exclusions") {
                TextField("Excluded folders", text: Binding(
                    get: { viewModel.options.exclusions.folderPrefixes.joined(separator: ", ") },
                    set: { viewModel.options.exclusions.folderPrefixes = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }
                ))
                TextField("Excluded extensions", text: Binding(
                    get: { viewModel.options.exclusions.extensions.joined(separator: ", ") },
                    set: { viewModel.options.exclusions.extensions = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces).lowercased() } }
                ))
            }
            Section("Privacy") {
                Text("All scans run locally. No analytics, telemetry, uploads, or file-content indexing.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
    }
}
