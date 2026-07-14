import AppKit
import MacDeepCleanerCore
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case storage = "Storage Analyzer"
    case large = "Large Files"
    case cache = "Cache"
    case applications = "Applications"
    case developer = "Developer"
    case backups = "iOS Backups"
    case duplicates = "Duplicates"
    case history = "Cleaning History"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: "gauge"
        case .storage: "externaldrive"
        case .large: "doc.zipper"
        case .cache: "tray"
        case .applications: "app"
        case .developer: "hammer"
        case .backups: "iphone"
        case .duplicates: "doc.on.doc"
        case .history: "clock.arrow.circlepath"
        case .settings: "gearshape"
        }
    }
}

struct MainWindowView: View {
    @StateObject private var viewModel = AppViewModel()
    @State private var selection: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases) { item in
                Button {
                    var transaction = Transaction()
                    transaction.animation = nil
                    withTransaction(transaction) {
                        selection = item
                    }
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == item ? Color.accentColor : Color.secondary.opacity(0.10))
                            Image(systemName: item.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(selection == item ? .white : .secondary)
                        }
                        .frame(width: 26, height: 26)

                        Text(item.rawValue)
                            .font(.callout.weight(selection == item ? .semibold : .regular))

                        Spacer()

                        if selection == item {
                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .background(selection == item ? Color.accentColor.opacity(0.14) : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .leading) {
                    if selection == item {
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: 3, height: 22)
                    }
                }
                .accessibilityLabel(item.rawValue)
            }
            .scrollContentBackground(.hidden)
            .background(SidebarBackground())
            .navigationTitle("Mac Deep Cleaner")
            .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 420)
        } detail: {
            Group {
                switch selection {
                case .dashboard: DashboardView(viewModel: viewModel) {
                    var transaction = Transaction()
                    transaction.animation = nil
                    withTransaction(transaction) {
                        selection = .storage
                    }
                }
                case .storage: ItemListView(viewModel: viewModel, title: "Storage Analyzer", items: viewModel.storageItems, scan: viewModel.scanStorage, clean: viewModel.cleanSelected)
                case .large: LargeFilesView(viewModel: viewModel)
                case .cache: ItemListView(viewModel: viewModel, title: "Cache", items: viewModel.cacheItems, scan: viewModel.scanCache, clean: viewModel.cleanSelected)
                case .applications: ApplicationsView(viewModel: viewModel)
                case .developer: ItemListView(viewModel: viewModel, title: "Developer", items: viewModel.developerItems, scan: viewModel.scanDeveloper, clean: viewModel.cleanSelected)
                case .backups: BackupsView(viewModel: viewModel)
                case .duplicates: DuplicatesView(viewModel: viewModel)
                case .history: HistoryView(viewModel: viewModel)
                case .settings: SettingsView(viewModel: viewModel)
                }
            }
            .transaction { $0.animation = nil }
            .background(AppBackground())
            .toolbar {
                ToolbarItemGroup {
                    if viewModel.isScanning {
                        ProgressView()
                            .controlSize(.small)
                        Button("Stop", systemImage: "stop.fill", action: viewModel.cancelScan)
                            .accessibilityLabel("Stop scan")
                    }
                    Button("Scan Mac", systemImage: "magnifyingglass", action: viewModel.scanMac)
                        .disabled(viewModel.isScanning)
                        .accessibilityLabel("Scan Mac")
                }
            }
        }
        .frame(minWidth: 1080, minHeight: 680)
    }
}

struct DashboardView: View {
    @ObservedObject var viewModel: AppViewModel
    let review: () -> Void
    @State private var confirmingClean = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Dashboard")
                                .font(.largeTitle.bold())
                            Text("Local storage review. Nothing is deleted without confirmation.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        StatusPill(text: viewModel.statusText, isBusy: viewModel.isScanning)
                    }

                    HStack {
                        Button("Scan Mac", systemImage: "magnifyingglass", action: viewModel.scanMac)
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        Button("Review Results", systemImage: "list.bullet.rectangle", action: review)
                            .controlSize(.large)
                        Button("Clean Selected", systemImage: "trash") { confirmingClean = true }
                            .controlSize(.large)
                            .disabled(viewModel.selectedItems.isEmpty)
                    }
                }

                PermissionBanner(viewModel: viewModel)

                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        MetricView("Total", viewModel.diskUsage.total, icon: "internaldrive", tint: .blue)
                        MetricView("Used", viewModel.diskUsage.used, icon: "chart.pie.fill", tint: .orange)
                        MetricView("Free", viewModel.diskUsage.free, icon: "checkmark.seal.fill", tint: .green)
                        MetricView("Reviewable", viewModel.reclaimable, icon: "sparkles", tint: .teal)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Disk Overview").font(.headline)
                        Spacer()
                        Text("\(ByteFormatting.string(viewModel.diskUsage.used)) used")
                            .foregroundStyle(.secondary)
                    }
                    StorageBar(used: viewModel.diskUsage.used, free: viewModel.diskUsage.free)
                }
                .padding(14)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12)))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.dashboardCategories, id: \.0) { category, size in
                        HStack(spacing: 10) {
                            Image(systemName: icon(for: category))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(tint(for: category))
                                .frame(width: 24, height: 24)
                                .background(tint(for: category).opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
                            Text(category.rawValue).lineLimit(1)
                            Spacer()
                            Text(ByteFormatting.string(size))
                                .font(.callout.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
                    }
                }
            }
            .padding(24)
        }
        .confirmationDialog("Move selected files to Trash?", isPresented: $confirmingClean) {
            Button("Move to Trash", role: .destructive) {
                viewModel.cleanSelected(from: viewModel.storageItems + viewModel.cacheItems + viewModel.developerItems + viewModel.largeFiles + viewModel.attachmentItems)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Review selected files first. Protected items are blocked.")
        }
    }

    private func icon(for category: CleanerCategory) -> String {
        switch category {
        case .applications: "app.fill"
        case .downloads: "arrow.down.circle.fill"
        case .documents: "doc.text.fill"
        case .developerFiles: "hammer.fill"
        case .cache: "tray.fill"
        case .logs: "doc.plaintext.fill"
        case .iOSBackups: "iphone"
        case .mailAttachments: "paperclip"
        case .messagesAttachments: "message.fill"
        case .largeFiles: "doc.zipper"
        case .oldFiles: "clock.fill"
        case .duplicateFiles: "doc.on.doc.fill"
        case .applicationLeftovers: "archivebox.fill"
        case .storage: "externaldrive.fill"
        }
    }

    private func tint(for category: CleanerCategory) -> Color {
        switch category {
        case .applications, .storage: .blue
        case .developerFiles, .largeFiles: .orange
        case .cache, .logs: .teal
        case .iOSBackups, .mailAttachments, .messagesAttachments: .indigo
        case .duplicateFiles, .applicationLeftovers, .oldFiles: .red
        default: .green
        }
    }
}

struct MetricView: View {
    let title: String
    let bytes: Int64
    let icon: String
    let tint: Color

    init(_ title: String, _ bytes: Int64, icon: String, tint: Color) {
        self.title = title
        self.bytes = bytes
        self.icon = icon
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(tint, in: RoundedRectangle(cornerRadius: 7))
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(ByteFormatting.string(bytes))
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12)))
    }
}

struct StorageBar: View {
    let used: Int64
    let free: Int64

    var body: some View {
        GeometryReader { proxy in
            let total = max(1, used + free)
            let usedWidth = proxy.size.width * CGFloat(Double(used) / Double(total))
            ZStack(alignment: .leading) {
                Rectangle().fill(.green.opacity(0.20))
                LinearGradient(colors: [.blue, .teal], startPoint: .leading, endPoint: .trailing)
                    .frame(width: usedWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.white.opacity(0.18)))
        }
        .frame(height: 20)
        .accessibilityLabel("Disk usage")
    }
}

struct PermissionBanner: View {
    @ObservedObject var viewModel: AppViewModel

    var body: some View {
        if viewModel.permissionStatus.fullDiskAccess == .limited {
            HStack {
                Image(systemName: "lock")
                Text(viewModel.permissionStatus.limitedReason ?? "Limited access")
                Spacer()
                Button("Open Settings", systemImage: "gear", action: viewModel.openSettingsForFullDiskAccess)
            }
            .padding(12)
            .background(.yellow.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.yellow.opacity(0.22)))
        }
    }
}

struct ItemListView: View {
    @ObservedObject var viewModel: AppViewModel
    let title: String
    let items: [ScanItem]
    let scan: () -> Void
    let clean: ([ScanItem]) -> Void
    @State private var sort = SortOption.size
    @State private var confirmingClean = false

    private var sortedItems: [ScanItem] {
        switch sort {
        case .size: items.sorted { $0.size > $1.size }
        case .name: items.sorted { $0.url.lastPathComponent.localizedCaseInsensitiveCompare($1.url.lastPathComponent) == .orderedAscending }
        case .lastModified: items.sorted { ($0.lastModified ?? .distantPast) > ($1.lastModified ?? .distantPast) }
        case .lastAccessed: items.sorted { ($0.lastAccessed ?? .distantPast) > ($1.lastAccessed ?? .distantPast) }
        case .fileType: items.sorted { $0.typeDescription < $1.typeDescription }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.largeTitle.bold())
                Spacer()
                Picker("Sort", selection: $sort) {
                    ForEach(SortOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .frame(width: 180)
                Button("Scan", systemImage: "magnifyingglass", action: scan)
                Button("Move to Trash", systemImage: "trash") { confirmingClean = true }
                    .disabled(viewModel.selectedItems.isEmpty)
            }
            ResultTable(items: sortedItems, selection: $viewModel.selectedItems)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.10)))
        }
        .padding(20)
        .background(AppBackground())
        .confirmationDialog("Move selected files to Trash?", isPresented: $confirmingClean) {
            Button("Move to Trash", role: .destructive) { clean(sortedItems) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Review the list first. Files marked Do Not Delete are blocked.")
        }
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.08),
                    Color.teal.opacity(0.05),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

struct SidebarBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .controlBackgroundColor),
                Color.accentColor.opacity(0.04)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct StatusPill: View {
    let text: String
    let isBusy: Bool

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(isBusy ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.12)))
    }
}

struct ResultTable: View {
    let items: [ScanItem]
    @Binding var selection: Set<ScanItem.ID>

    var body: some View {
        Table(items, selection: $selection) {
            TableColumn("Name") { item in
                Text(item.url.lastPathComponent).lineLimit(1)
            }
            TableColumn("Size") { item in
                Text(ByteFormatting.string(item.size)).monospacedDigit()
            }
            TableColumn("Modified") { item in
                Text(item.lastModified?.formatted(date: .abbreviated, time: .omitted) ?? "-")
            }
            TableColumn("Accessed") { item in
                Text(item.lastAccessed?.formatted(date: .abbreviated, time: .omitted) ?? "-")
            }
            TableColumn("Type") { item in
                Text(item.typeDescription)
            }
            TableColumn("Risk") { item in
                Text(item.riskLevel.rawValue)
                    .foregroundStyle(item.riskLevel == .safe ? .green : item.riskLevel == .review ? .orange : .red)
            }
            TableColumn("Path") { item in
                Text(item.url.path).lineLimit(1).foregroundStyle(.secondary)
            }
            TableColumn("Actions") { item in
                HStack(spacing: 6) {
                    Button("", systemImage: "eye") { QuickLookController.shared.preview(item.url) }
                        .help("Quick Look")
                    Button("", systemImage: "folder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                        .help("Reveal in Finder")
                    Button("", systemImage: "arrow.up.forward.app") { NSWorkspace.shared.open(item.url) }
                        .help("Open")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
