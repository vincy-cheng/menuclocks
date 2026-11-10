import AppKit
import XCTest
@testable import MenuClocks

final class PopoverDismissalTests: XCTestCase {
    @MainActor
    func testOutsideClickMonitoringExistsOnlyWhilePopoverIsShown() {
        _ = NSApplication.shared
        let delegate = AppDelegate()
        let notification = Notification(name: NSPopover.didShowNotification)
        XCTAssertNil(delegate.outsideClickMonitor)
        delegate.popoverDidShow(notification)
        XCTAssertNotNil(delegate.outsideClickMonitor)
        delegate.popoverDidClose(Notification(name: NSPopover.didCloseNotification))
        XCTAssertNil(delegate.outsideClickMonitor)
    }

    @MainActor
    func testRepeatedShowDoesNotInstallDuplicateMonitor() {
        _ = NSApplication.shared
        let delegate = AppDelegate()
        let notification = Notification(name: NSPopover.didShowNotification)
        delegate.popoverDidShow(notification)
        let firstMonitor = delegate.outsideClickMonitor as AnyObject?
        XCTAssertNotNil(firstMonitor)
        delegate.popoverDidShow(notification)
        XCTAssertTrue(firstMonitor === (delegate.outsideClickMonitor as AnyObject?))
        delegate.popoverDidClose(Notification(name: NSPopover.didCloseNotification))
    }
    @MainActor
    func testStatusItemContextMenuOffersQuitApplication() throws {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        let item = try XCTUnwrap(delegate.statusMenu.items.first)
        XCTAssertEqual(delegate.statusMenu.items.count, 1)
        XCTAssertEqual(item.title, "Quit MenuClocks")
        XCTAssertEqual(item.action, #selector(NSApplication.terminate(_:)))
        XCTAssertTrue(item.target === app)
        XCTAssertEqual(item.keyEquivalent, "q")
    }

}
