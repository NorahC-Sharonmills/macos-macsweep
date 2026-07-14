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
                    Label(item.rawValue, systemImage: item.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(selection == item ? Color.accentColor.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
                .accessibilityLabel(item.rawValue)
            }
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
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Dashboard").font(.largeTitle.bold())
                    Spacer()
                    Text(viewModel.statusText).foregroundStyle(.secondary)
                }
                PermissionBanner(viewModel: viewModel)
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                    GridRow {
                        MetricView("Total", viewModel.diskUsage.total)
                        MetricView("Used", viewModel.diskUsage.used)
                        MetricView("Free", viewModel.diskUsage.free)
                        MetricView("Reviewable", viewModel.reclaimable)
                    }
                }
                StorageBar(used: viewModel.diskUsage.used, free: viewModel.diskUsage.free)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                    ForEach(viewModel.dashboardCategories, id: \.0) { category, size in
                        HStack {
                            Text(category.rawValue)
                            Spacer()
                            Text(ByteFormatting.string(size)).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                HStack {
                    Button("Scan Mac", systemImage: "magnifyingglass", action: viewModel.scanMac)
                    Button("Review Results", systemImage: "list.bullet.rectangle", action: review)
                    Button("Clean Selected", systemImage: "trash") { confirmingClean = true }
                    .disabled(viewModel.selectedItems.isEmpty)
                }
                .buttonStyle(.borderedProminent)
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
}

struct MetricView: View {
    let title: String
    let bytes: Int64

    init(_ title: String, _ bytes: Int64) {
        self.title = title
        self.bytes = bytes
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(ByteFormatting.string(bytes)).font(.title3.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
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
                Rectangle().fill(.green.opacity(0.25))
                Rectangle().fill(.blue).frame(width: usedWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 18)
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
            .background(.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
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
        }
        .padding(20)
        .confirmationDialog("Move selected files to Trash?", isPresented: $confirmingClean) {
            Button("Move to Trash", role: .destructive) { clean(sortedItems) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Review the list first. Files marked Do Not Delete are blocked.")
        }
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
