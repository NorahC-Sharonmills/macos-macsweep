import AppKit
import MacDeepCleanerCore
import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var confirmingClean = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorfulHeader(title: "Large Files", subtitle: "Filter big files by size and age. Old never means junk.", icon: "doc.zipper", tint: .orange) {
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
            HStack(spacing: 10) {
                ColorStat(title: "Files", value: "\(viewModel.largeFiles.count)", icon: "number", tint: .orange)
                ColorStat(title: "Total", value: ByteFormatting.string(viewModel.largeFiles.reduce(0) { $0 + $1.size }), icon: "sum", tint: .pink)
                ColorStat(title: "Threshold", value: ByteFormatting.string(viewModel.selectedLargeThreshold), icon: "slider.horizontal.3", tint: .blue)
            }
            ResultTable(items: viewModel.largeFiles, selection: $viewModel.selectedItems)
        }
        .padding(20)
        .background(AppBackground())
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
            ColorfulHeader(title: "Applications", subtitle: "Review installed apps and related files. Shared containers stay review-only.", icon: "app.fill", tint: .blue) {
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanApplications)
            }
            HStack(spacing: 10) {
                ColorStat(title: "Apps", value: "\(viewModel.applications.count)", icon: "app.badge", tint: .blue)
                ColorStat(title: "Total Size", value: ByteFormatting.string(viewModel.applications.reduce(0) { $0 + $1.size }), icon: "internaldrive", tint: .teal)
                ColorStat(title: "Leftovers", value: "\(viewModel.applications.flatMap(\.leftovers).count)", icon: "archivebox.fill", tint: .orange)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(viewModel.applications.count) apps")
                            .font(.headline)
                        Spacer()
                        Text(ByteFormatting.string(viewModel.applications.reduce(0) { $0 + $1.size }))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)

                    List(selection: $selectedApp) {
                        ForEach(viewModel.applications) { app in
                            ApplicationRow(app: app)
                                .tag(app.id)
                        }
                    }
                    .listStyle(.sidebar)
                }
                .frame(minWidth: 320, idealWidth: 380, maxWidth: 460)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))

                if let selected {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .center, spacing: 14) {
                            AppIcon(url: selected.url, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selected.name)
                                    .font(.title2.bold())
                                    .lineLimit(1)
                                Text(selected.bundleIdentifier ?? "No bundle identifier")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            Spacer()
                            Button("", systemImage: "folder") {
                                NSWorkspace.shared.activateFileViewerSelecting([selected.url])
                            }
                            .help("Reveal in Finder")
                            Button("", systemImage: "arrow.up.forward.app") {
                                NSWorkspace.shared.open(selected.url)
                            }
                            .help("Open")
                        }

                        HStack(spacing: 10) {
                            AppFact("Version", selected.version ?? "-")
                            AppFact("Size", ByteFormatting.string(selected.size))
                            AppFact("Last Used", selected.lastAccessed?.formatted(date: .abbreviated, time: .omitted) ?? "-")
                            AppFact("Related", "\(selected.leftovers.count)")
                        }

                        Divider()

                        HStack {
                            Text("Related Files").font(.headline)
                            Spacer()
                            Button("Move Selected", systemImage: "trash") {
                                viewModel.cleanSelected(from: selected.leftovers)
                            }
                            .disabled(viewModel.selectedItems.isEmpty)
                            Button("Uninstall", systemImage: "app.badge") {
                                confirmingUninstall = true
                            }
                        }

                        if selected.leftovers.isEmpty {
                            ContentUnavailableView("No related files found", systemImage: "checkmark.circle")
                        } else {
                            ResultTable(items: selected.leftovers, selection: $viewModel.selectedItems)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
                } else {
                    ContentUnavailableView("Select an app", systemImage: "app")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .padding(20)
        .background(AppBackground())
        .onChange(of: viewModel.applications) { _, apps in
            if selectedApp == nil {
                selectedApp = apps.first?.id
            }
        }
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

struct ApplicationRow: View {
    let app: ApplicationInfo

    var body: some View {
        HStack(spacing: 10) {
            AppIcon(url: app.url, size: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(ByteFormatting.string(app.size))
                    Text(app.version ?? "-")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }
}

struct AppIcon: View {
    let url: URL
    let size: CGFloat

    var body: some View {
        Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
            .resizable()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct AppFact: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospacedDigit())
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.08)))
    }
}

struct BackupsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorfulHeader(title: "iOS Backups", subtitle: "Reads backup metadata only. Private backup contents are not inspected.", icon: "iphone", tint: .indigo) {
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanBackups)
            }
            HStack(spacing: 10) {
                ColorStat(title: "Backups", value: "\(viewModel.backups.count)", icon: "iphone.gen3", tint: .indigo)
                ColorStat(title: "Total", value: ByteFormatting.string(viewModel.backups.reduce(0) { $0 + $1.size }), icon: "externaldrive.fill", tint: .blue)
                ColorStat(title: "Encrypted", value: "\(viewModel.backups.filter { $0.encrypted == true }.count)", icon: "lock.fill", tint: .green)
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
        .background(AppBackground())
    }
}

struct DuplicatesView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorfulHeader(title: "Duplicates", subtitle: "Size grouping, partial hash, then SHA-256. No copy is auto-selected.", icon: "doc.on.doc.fill", tint: .red) {
                Button("Scan", systemImage: "magnifyingglass", action: viewModel.scanDuplicates)
            }
            HStack(spacing: 10) {
                ColorStat(title: "Groups", value: "\(viewModel.duplicateGroups.count)", icon: "square.stack.3d.up.fill", tint: .red)
                ColorStat(title: "Files", value: "\(viewModel.duplicateGroups.reduce(0) { $0 + $1.files.count })", icon: "doc.fill", tint: .orange)
                ColorStat(title: "Potential", value: ByteFormatting.string(viewModel.duplicateGroups.reduce(0) { $0 + $1.size * Int64(max(0, $1.files.count - 1)) }), icon: "trash.fill", tint: .pink)
            }
            List(viewModel.duplicateGroups) { group in
                Section("\(ByteFormatting.string(group.size)) - \(group.files.count) files") {
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
        .background(AppBackground())
    }
}

struct HistoryView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorfulHeader(title: "Cleaning History", subtitle: "Tracks paths moved to Trash. File contents are never stored.", icon: "clock.arrow.circlepath", tint: .green) {
                EmptyView()
            }
            HStack(spacing: 10) {
                ColorStat(title: "Sessions", value: "\(viewModel.history.count)", icon: "calendar", tint: .green)
                ColorStat(title: "Moved", value: ByteFormatting.string(viewModel.history.reduce(0) { $0 + $1.bytes }), icon: "trash.fill", tint: .teal)
                ColorStat(title: "Files", value: "\(viewModel.history.reduce(0) { $0 + $1.paths.count })", icon: "doc.fill", tint: .blue)
            }
            Table(viewModel.history) {
                TableColumn("Date") { Text($0.date.formatted(date: .abbreviated, time: .shortened)) }
                TableColumn("Category") { Text($0.category.rawValue) }
                TableColumn("Size") { Text(ByteFormatting.string($0.bytes)) }
                TableColumn("Files") { Text("\($0.paths.count)") }
            }
        }
        .padding(20)
        .background(AppBackground())
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ColorfulHeader(title: "Settings", subtitle: "Safety-first scan scope and exclusions.", icon: "gearshape.fill", tint: .purple) {
                EmptyView()
            }
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
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
        }
        .padding(20)
        .background(AppBackground())
    }
}
