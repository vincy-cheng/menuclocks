import AppKit
import SwiftUI
import Combine
import ClockCore

@MainActor
final class ClockStore: ObservableObject {
    @Published var clocks: [Clock] { didSet { save() } }
    @Published var use24Hour: Bool { didSet { UserDefaults.standard.set(use24Hour, forKey: "use24Hour") } }
    @Published var twoLineMenuBar: Bool { didSet { UserDefaults.standard.set(twoLineMenuBar, forKey: "twoLineMenuBar") } }
    @Published var now = Date()
    @Published var previewHours = 0.0
    private var timer: Timer?
    var viewedDate: Date { now.addingTimeInterval(previewHours * 3600) }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "clocks"),
           let saved = try? JSONDecoder().decode([Clock].self, from: data) {
            var seen = Set<String>()
            clocks = saved.filter { TimeZone(identifier: $0.id) != nil && seen.insert($0.id).inserted }
        } else {
            var seen = Set<String>()
            clocks = [Clock(id: TimeZone.current.identifier, pinned: true),
                      Clock(id: "Europe/London"),
                      Clock(id: "America/New_York", pinned: true)]
                .filter { seen.insert($0.id).inserted }
        }
        twoLineMenuBar = defaults.object(forKey: "twoLineMenuBar") as? Bool ?? false
        use24Hour = defaults.object(forKey: "use24Hour") as? Bool ?? true
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func save() {
        if let data = try? JSONEncoder().encode(clocks) {
            UserDefaults.standard.set(data, forKey: "clocks")
        }
    }

    func add(_ identifier: String) {
        guard !clocks.contains(where: { $0.id == identifier }) else { return }
        clocks.append(Clock(id: identifier))
    }

    func move(_ id: String, by distance: Int) {
        guard let index = clocks.firstIndex(where: { $0.id == id }), clocks.indices.contains(index + distance) else { return }
        clocks.swapAt(index, index + distance)
    }

    func copyTimes() {
        let date = viewedDate
        let text = clocks.map { "\($0.name): \($0.time(at: date, use24Hour: use24Hour)) · \($0.dateText(at: date)) · \($0.offset(at: date))" }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

struct ClockPanel: View {
    @ObservedObject var store: ClockStore
    @State private var editing = false
    @State private var adding = false
    @State private var query = ""
    @State private var copied = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if adding { searchPanel } else { clockList }
            Divider()
            if !adding { timeline }
            footer
        }
        .frame(width: 390, height: 580)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "globe.americas.fill")
                .font(.system(size: 25)).foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("MenuClocks").font(.system(size: 17, weight: .semibold))
                Text(adding ? "Find your next time zone" : "A little closer, across time zones.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                adding.toggle()
                query = ""
            } label: { Image(systemName: adding ? "xmark" : "plus").frame(width: 24, height: 24) }
                .buttonStyle(.borderless).help(adding ? "Close search" : "Add time zone")
                .accessibilityLabel(adding ? "Close search" : "Add time zone")
        }
        .padding(18)
    }

    private var clockList: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Text("YOUR CLOCKS").font(.system(size: 10, weight: .semibold)).tracking(1.4).foregroundStyle(.secondary)
                    Spacer()
                    Button(editing ? "Done" : "Edit") { editing.toggle() }.buttonStyle(.borderless)
                }
                .padding(.bottom, 2)
                if store.clocks.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "globe").font(.largeTitle).foregroundStyle(.secondary)
                        Text("Your world starts here").font(.headline)
                        Button("Add a time zone") { adding = true }
                    }.frame(maxWidth: .infinity).padding(.vertical, 60)
                }
                ForEach($store.clocks) { $clock in
                    clockRow($clock)
                }
            }.padding(16)
        }
    }

    private func clockRow(_ binding: Binding<Clock>) -> some View {
        let clock = binding.wrappedValue
        let date = store.viewedDate
        let difference = clock.dayDifference(at: date, relativeTo: .current)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: clock.isDaytime(at: date) ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(clock.isDaytime(at: date) ? Color.orange : Color.indigo)
                    .frame(width: 26)
                    .accessibilityLabel(clock.isDaytime(at: date) ? "Daytime" : "Nighttime")
                VStack(alignment: .leading, spacing: 5) {
                    Text(clock.name).font(.system(size: 14, weight: .semibold)).lineLimit(1)
                    Text("\(clock.abbreviation(at: date) ?? clock.id) · \(clock.offset(at: date))")
                        .font(.system(size: 10)).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(clock.time(at: date, use24Hour: store.use24Hour))
                        .font(.system(size: 24, weight: .medium, design: .rounded)).monospacedDigit()
                    HStack(spacing: 4) {
                        Text(clock.dateText(at: date))
                        if difference != 0 { Text("\(difference > 0 ? "+" : "")\(difference)d").foregroundStyle(.teal) }
                    }.font(.system(size: 10)).foregroundStyle(.secondary)
                }
            }
            if editing {
                HStack(spacing: 8) {
                    TextField("Custom label", text: binding.label).textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Label for \(clock.city)")
                    Button { store.move(clock.id, by: -1) } label: { Image(systemName: "arrow.up") }
                        .help("Move up").accessibilityLabel("Move \(clock.name) up")
                        .disabled(store.clocks.first?.id == clock.id)
                    Button { store.move(clock.id, by: 1) } label: { Image(systemName: "arrow.down") }
                        .help("Move down").accessibilityLabel("Move \(clock.name) down")
                        .disabled(store.clocks.last?.id == clock.id)
                    Button { store.clocks.removeAll { $0.id == clock.id } } label: { Image(systemName: "trash") }
                        .help("Remove time zone").accessibilityLabel("Remove \(clock.name)")
                }.buttonStyle(.borderless)
                Picker("Menu bar name", selection: binding.menuBarNameMode) {
                    Text("Full name").tag(Clock.MenuBarNameMode.fullName)
                    Text("Time zone abbreviation").tag(Clock.MenuBarNameMode.abbreviation)
                    Text("Custom short name").tag(Clock.MenuBarNameMode.custom)
                }
                .font(.system(size: 11))
                .accessibilityLabel("Menu bar name for \(clock.name)")
                if clock.menuBarNameMode == .custom {
                    TextField("Short name, e.g. HK", text: binding.shortName)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("Menu bar short name for \(clock.name)")
                }
            }
            HStack {
                if editing { Text(clock.id).font(.system(size: 9)).foregroundStyle(.secondary).lineLimit(1) }
                Spacer()
                Toggle("In menu bar", isOn: binding.pinned)
                    .toggleStyle(.checkbox).font(.system(size: 10))
                    .accessibilityLabel("Show \(clock.name) in menu bar")
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.05)))
    }

    private var timeline: some View {
        VStack(spacing: 9) {
            HStack {
                Text("LOOK AHEAD").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundStyle(.secondary)
                Spacer()
                if store.previewHours == 0 {
                    Circle().fill(.teal).frame(width: 5, height: 5)
                    Text("Live").font(.system(size: 11)).foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%+.1f hours", store.previewHours)).font(.system(size: 11)).monospacedDigit()
                    Button("Now") { store.previewHours = 0 }.buttonStyle(.borderless)
                }
            }
            Slider(value: $store.previewHours, in: -24...24, step: 0.5)
                .tint(.teal).accessibilityLabel("Preview time offset in hours")
            HStack {
                Text("−24h")
                Spacer()
                Text("Preview only · menu bar stays live")
                Spacer()
                Text("+24h")
            }.font(.system(size: 9)).foregroundStyle(.secondary)
        }.padding(.horizontal, 18).padding(.vertical, 14)
    }

    private var searchPanel: some View {
        VStack(spacing: 10) {
            TextField("Search city or time zone…", text: $query)
                .textFieldStyle(.roundedBorder).padding(.horizontal, 16).padding(.top, 16)
                .accessibilityLabel("Search time zones")
            Text("Search system time zones, such as Tokyo, New York, or UTC.")
                .font(.system(size: 10)).foregroundStyle(.secondary).padding(.horizontal, 16)
            ScrollView {
                LazyVStack(spacing: 0) {
                    let results = Clock.search(query)
                    if results.isEmpty { Text("No matching time zones").foregroundStyle(.secondary).padding(30) }
                    ForEach(results, id: \.self) { identifier in
                        let exists = store.clocks.contains { $0.id == identifier }
                        Button {
                            store.add(identifier)
                            adding = false
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(Clock(id: identifier).city).font(.system(size: 13, weight: .medium))
                                    Text(identifier.replacingOccurrences(of: "_", with: " ")).font(.system(size: 10)).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: exists ? "checkmark" : "plus.circle").foregroundStyle(.teal)
                            }.padding(.horizontal, 18).padding(.vertical, 10).contentShape(Rectangle())
                        }.buttonStyle(.plain).disabled(exists)
                        Divider().padding(.horizontal, 18)
                    }
                }
            }
        }.frame(maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Toggle("24-hour", isOn: $store.use24Hour).toggleStyle(.checkbox).font(.system(size: 11))
            Spacer()
            Button {
                store.copyTimes()
                copied = true
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc") }
                .help(copied ? "Copied" : "Copy all times").accessibilityLabel("Copy all times")
            Menu {
                Toggle("Two-line menu bar", isOn: $store.twoLineMenuBar)
                Divider()
                Text("MenuClocks 1.0")
                Text("Menu bar clocks update every 5 seconds.")
            } label: { Image(systemName: "ellipsis.circle") }
                .menuStyle(.borderlessButton).fixedSize().help("More options")
                .accessibilityLabel("More options")
        }.buttonStyle(.borderless).padding(.horizontal, 18).padding(.vertical, 13)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    private let store = ClockStore()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var updates = Set<AnyCancellable>()
    private(set) var outsideClickMonitor: Any?
    let statusMenu: NSMenu = {
        let menu = NSMenu()
        let quit = NSMenuItem(title: "Quit MenuClocks", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApplication.shared
        menu.addItem(quit)
        return menu
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
            button.setAccessibilityLabel("MenuClocks world clocks")
        }
        popover.behavior = .transient
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: ClockPanel(store: store))
        store.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateTitle() }
        }.store(in: &updates)
        updateTitle()
    }

    private func updateTitle() {
        let pinned = store.clocks.filter(\.pinned)
        guard let button = statusItem.button else { return }
        if pinned.isEmpty {
            button.title = ""
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "MenuClocks")
        } else if store.twoLineMenuBar {
            button.title = ""
            button.image = twoLineImage()
        } else {
            button.image = nil
            button.title = Clock.menuBarTitle(clocks: store.clocks, at: store.now, use24Hour: store.use24Hour)
        }
        let description = pinned.isEmpty ? "MenuClocks — click to add time zones" :
            pinned.map { "\($0.name): \($0.time(at: store.now, use24Hour: store.use24Hour))" }.joined(separator: "\n")
        button.toolTip = description
        button.setAccessibilityLabel("MenuClocks world clocks. \(description)")
    }

    private func twoLineImage() -> NSImage {
        let entries = Clock.menuBarEntries(clocks: store.clocks, at: store.now, use24Hour: store.use24Hour)
        let nameAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: 9, weight: .medium), .foregroundColor: NSColor.black]
        let timeAttributes: [NSAttributedString.Key: Any] = [.font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium), .foregroundColor: NSColor.black]
        let columns = entries.map {
            (name: NSAttributedString(string: $0.name, attributes: nameAttributes),
             time: NSAttributedString(string: $0.time, attributes: timeAttributes))
        }
        let widths = columns.map { ceil(max($0.name.size().width, $0.time.size().width)) }
        let overflow = store.clocks.filter(\.pinned).count - entries.count
        let suffix = NSAttributedString(string: overflow > 0 ? "+\(overflow)" : "", attributes: timeAttributes)
        let spacing: CGFloat = 8
        let width = widths.reduce(0, +) + CGFloat(max(0, columns.count - 1)) * spacing
            + (overflow > 0 ? spacing + ceil(suffix.size().width) : 0)
        let image = NSImage(size: NSSize(width: width, height: 22), flipped: false) { _ in
            var x: CGFloat = 0
            for (column, width) in zip(columns, widths) {
                column.name.draw(at: NSPoint(x: x + (width - column.name.size().width) / 2, y: 11))
                column.time.draw(at: NSPoint(x: x + (width - column.time.size().width) / 2, y: 0))
                x += width + spacing
            }
            if overflow > 0 { suffix.draw(at: NSPoint(x: x, y: (22 - suffix.size().height) / 2)) }
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func statusItemClicked() {
        guard let button = statusItem.button else { return }
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true {
            popover.performClose(nil)
            statusMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button)
        } else {
            togglePanel()
        }
    }

    private func togglePanel() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            store.now = Date()
            store.previewHours = 0
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    func popoverDidShow(_ notification: Notification) {
        guard outsideClickMonitor == nil else { return }
        // Transient popovers do not dismiss for every menu interaction.
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.performClose(nil) }
        }
    }

    func popoverDidClose(_ notification: Notification) {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
        store.previewHours = 0
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
