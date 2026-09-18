import AppKit
import SwiftUI
import Combine
import MyPriKit

enum DockSide: String {
    case left, right
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var currentFileURL = MacStoreSupport.savedFileURL()
    lazy var store = PriorityStore(io: LocalFileIO(url: currentFileURL))
    var mainWindow: NSWindow!
    var detailWindows: [UUID: NSWindow] = [:]
    var detailWindowSubscriptions: [UUID: AnyCancellable] = [:]

    private let dockSideKey = "MyPri.dockSide"

    private var dockSide: DockSide {
        get { DockSide(rawValue: UserDefaults.standard.string(forKey: dockSideKey) ?? "") ?? .right }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: dockSideKey) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenuBar()
        createMainWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        // Pull in any changes the other platform's app made while we were
        // in the background — the file is shared via Google Drive, so
        // there's no push notification when it changes elsewhere.
        store.refresh()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindow.makeKeyAndOrderFront(nil)
        return true
    }

    // MARK: - Main window

    private func targetScreen() -> NSScreen {
        let screens = NSScreen.screens
        if screens.count > 1 {
            // Prefer a screen other than the one holding the menu bar (index 0).
            return screens.first { $0 != NSScreen.main } ?? screens[1]
        }
        return screens.first ?? NSScreen.main!
    }

    private func frame(on screen: NSScreen, side: DockSide, widthFraction: CGFloat) -> NSRect {
        let visible = screen.visibleFrame
        let width = max(240, visible.width * widthFraction)
        let x = side == .right ? visible.maxX - width : visible.minX
        return NSRect(x: x, y: visible.minY, width: width, height: visible.height)
    }

    private func createMainWindow() {
        let screen = targetScreen()
        let widthFraction: CGFloat = 0.20
        let initialFrame = frame(on: screen, side: dockSide, widthFraction: widthFraction)

        let window = NSWindow(
            contentRect: initialFrame,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        window.title = "MyPri"
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.minSize = NSSize(width: 240, height: 300)
        window.backgroundColor = NSColor(Color.mpBackground)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.setFrame(initialFrame, display: true)

        let content = MainListView(store: store) { [weak self] id in
            self?.openDetailWindow(for: id)
        }
        window.contentView = NSHostingView(rootView: content)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)

        mainWindow = window
    }

    func dock(to side: DockSide) {
        dockSide = side
        let screen = mainWindow.screen ?? targetScreen()
        let widthFraction = mainWindow.frame.width / screen.visibleFrame.width
        mainWindow.setFrame(frame(on: screen, side: side, widthFraction: max(0.12, widthFraction)), display: true, animate: true)
    }

    func resetSizeAndPosition() {
        let screen = targetScreen()
        mainWindow.setFrame(frame(on: screen, side: dockSide, widthFraction: 0.20), display: true, animate: true)
    }

    // MARK: - Detail windows

    func openDetailWindow(for id: UUID) {
        if let existing = detailWindows[id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let title = store.items.first(where: { $0.id == id })?.title ?? "Priority"

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 660),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = title.isEmpty ? "Priority" : title
        window.isReleasedWhenClosed = false
        window.isRestorable = false
        window.backgroundColor = NSColor(Color.mpBackground)
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        if let mainFrame = mainWindow?.frame {
            let x = dockSide == .right ? mainFrame.minX - 580 : mainFrame.maxX + 20
            window.setFrameTopLeftPoint(NSPoint(x: max(20, x), y: mainFrame.maxY))
        } else {
            window.center()
        }

        let closeAction: () -> Void = { [weak self, weak window] in
            window?.performClose(nil)
            self?.detailWindows.removeValue(forKey: id)
            self?.detailWindowSubscriptions.removeValue(forKey: id)
        }

        let detail = DetailHostView(store: store, id: id, onClose: closeAction)
        window.contentView = NSHostingView(rootView: detail)
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        detailWindows[id] = window
        detailWindowSubscriptions[id] = store.$items.sink { [weak window] items in
            guard let title = items.first(where: { $0.id == id })?.title else { return }
            window?.title = title.isEmpty ? "Priority" : title
        }
    }

    // MARK: - Menu bar

    private func buildMenuBar() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About MyPri", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Hide MyPri", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "Quit MyPri", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "New Priority", action: #selector(newPriority), keyEquivalent: "n")
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "Choose Data File Location…", action: #selector(chooseDataFile), keyEquivalent: "")
        fileMenu.addItem(withTitle: "Reveal Data File in Finder", action: #selector(revealDataFile), keyEquivalent: "")
        fileMenuItem.submenu = fileMenu
        fileMenu.items.forEach { $0.target = self }
        mainMenu.addItem(fileMenuItem)

        // Edit menu (needed for standard cut/copy/paste/undo shortcuts in text fields)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(.separator())
        let dockLeft = NSMenuItem(title: "Dock Left", action: #selector(dockLeftAction), keyEquivalent: "")
        let dockRight = NSMenuItem(title: "Dock Right", action: #selector(dockRightAction), keyEquivalent: "")
        let resetItem = NSMenuItem(title: "Reset Size & Position", action: #selector(resetSizeAndPositionAction), keyEquivalent: "")
        [dockLeft, dockRight, resetItem].forEach { $0.target = self; windowMenu.addItem($0) }
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func newPriority() { store.addItem() }
    @objc private func chooseDataFile() {
        if let newURL = MacStoreSupport.chooseNewFileLocation(for: store, currentURL: currentFileURL) {
            currentFileURL = newURL
        }
    }
    @objc private func revealDataFile() { MacStoreSupport.revealInFinder(currentFileURL, store: store) }
    @objc private func dockLeftAction() { dock(to: .left) }
    @objc private func dockRightAction() { dock(to: .right) }
    @objc private func resetSizeAndPositionAction() { resetSizeAndPosition() }
}

extension AppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if let id = detailWindows.first(where: { $0.value === window })?.key {
            store.saveNow()
            detailWindows.removeValue(forKey: id)
            detailWindowSubscriptions.removeValue(forKey: id)
        }
        if window === mainWindow {
            store.saveNow()
        }
    }
}
