//
//  MBPopupController.swift
//  MBPopup
//
//  Created by Mahdi Bchetnia on 16/8/25.
//  Copyright © 2016 Mahdi Bchetnia. See LICENSE.
//

import Foundation
import Cocoa

public struct MBPopup {
    static var openDuration: TimeInterval = 0.15
    static var closeDuration: TimeInterval = 0.1
    static var arrowSize = MBPopupArrowSize(height: 8.0, width: 12.0)
}

public struct MBPopupArrowSize {
    let height: CGFloat
    let width: CGFloat
}

public enum MBPopupKeys {
    case none
    case shift
    case option
    case shiftOption
}

public class MBPopupController: NSWindowController {
    public let statusItem = NSStatusBar.system().statusItem(withLength: 24)
    public let panel = MBPopupPanel()

    public let backgroundView = MBPopupBackgroundView()
    public var contentView: NSView

    private(set) public var isOpen: Bool = false {
        didSet {
            statusItem.button?.isHighlighted = isOpen
        }
    }

    public var willOpenPopup: ((MBPopupKeys) -> Void)?
    public var didOpenPopup: (() -> Void)?
    public var willClosePopup: (() -> Void)?
    public var didClosePopup: (() -> Void)?

    var eventMonitor: Any?

    // MARK: Initializing

    public init(contentView: NSView) {
        self.contentView = contentView

        super.init(window: panel)

        setup()
    }
    
    required public init?(coder: NSCoder) {
        self.contentView = coder.decodeObject(forKey: "contentView") as? NSView ?? NSView()

        super.init(coder: coder)
        self.window = panel

        setup()
    }

    // Mark: Setup

    private func setup() {
        self.eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let statusItemButton = self?.statusItem.button else { return event }

            // NSPointInRect treats the upper edge of the rectangle as being outside the boundaries, so clicking on the
            // upper edge of the button (and the screen's) won't return true.
            // We compensate for that by faking a 1pt bigger button size.
            var buttonBounds = statusItemButton.bounds
            buttonBounds.size.height += 1

            if NSPointInRect(event.locationInWindow, buttonBounds) {
                self?.togglePopup()

                // Stop propagating the event
                return nil
            }

            return event
        }

        panel.windowController = self
        panel.acceptsMouseMovedEvents = true
        panel.level = Int(CGWindowLevelForKey(CGWindowLevelKey.popUpMenuWindow))
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.styleMask = .nonactivatingPanel
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.delegate = self
        panel.contentView = backgroundView
        backgroundView.addSubview(contentView)

        var contentFrame = contentView.frame
        contentFrame.origin.x = 1
        contentFrame.origin.y = 1
        contentView.frame = contentFrame

        panel.initialFirstResponder = contentView
    }

    // MARK: Actions

    public func openPopup() {
        openPanel()
    }

    public func closePopup() {
        closePanel()
    }

    public func togglePopup() {
        if isOpen == true {
            closePanel()
        } else {
            openPanel()
        }
    }

    // MARK: Controlling the Panel

    private func openPanel() {
        if let currentEvent = NSApp.currentEvent, currentEvent.type == .leftMouseDown {
            willOpenPopup?(currentEvent.mbpopup_pressedModifiers())
        } else {
            willOpenPopup?(.none)
        }

        self.isOpen = true

        contentView.isHidden = false
        let (_, statusRect, panelRect) = rectsForPanel(panel)

        NSApp.activate(ignoringOtherApps: false)
        panel.alphaValue = 0
        panel.setFrame(statusRect, display: true)
        panel.makeKeyAndOrderFront(self)

        panel.setFrame(panelRect, display: true)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = MBPopup.openDuration
            panel.animator().alphaValue = 1
        }, completionHandler: {
            self.didOpenPopup?()
        })
    }

    private func closePanel() {
        willClosePopup?()

        self.isOpen = false

        contentView.isHidden = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = MBPopup.closeDuration
            window?.animator().alphaValue = 0
        }, completionHandler: {
            self.window?.orderOut(nil)
            self.statusItem.button?.isHighlighted = false
            self.didClosePopup?()
        })
    }

    // MARK: Calculating CGRects

    fileprivate func statusRectForWindow(_ window: NSWindow) -> CGRect {
        guard let screenRect = NSScreen.screens()?.first?.frame else { return .zero }

        var statusRect = CGRect.zero

        if let statusItemButton = statusItem.button {
            statusRect = statusItemButton.globalRect ?? statusRect
            statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect)
        } else {
            statusRect.size = NSMakeSize(statusItem.length, NSStatusBar.system().thickness)
            statusRect.origin.x = round((NSWidth(screenRect) - NSWidth(statusRect)) / 2)
            statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2
        }

        return statusRect
    }

    private func rectsForPanel(_ panel: NSPanel) -> (screenRect: CGRect, statusRect: CGRect, panelRect: CGRect) {
        // Headless Mac case
        guard let mainScreen = NSScreen.main() else { return (CGRect.zero, CGRect.zero, CGRect.zero) }

        let screenRect = mainScreen.frame
        let statusRect = statusRectForWindow(panel)

        var panelRect = panel.frame
        panelRect.size.height = contentView.frame.height + 2 + MBPopup.arrowSize.height
        panelRect.size.width = contentView.frame.width + 2
        panelRect.origin.x = round(NSMidX(statusRect) - NSWidth(panelRect) / 2)
        panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect)

        if NSMaxX(panelRect) > (NSMaxX(screenRect) - MBPopup.arrowSize.height) {
            panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - MBPopup.arrowSize.height)
        }

        return (screenRect, statusRect, panelRect)
    }

    // MARK: Deinitializing

    deinit {
        NSEvent.removeMonitor(eventMonitor)
        NSStatusBar.system().removeStatusItem(statusItem)
    }
}

// MARK: - (NSWindowDelegate)
extension MBPopupController: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        closePopup()
    }

    public func windowDidResignKey(_ notification: Notification) {
        if window?.isVisible == true {
            closePopup()
        }
    }

    public func windowDidResize(_ notification: Notification) {
        let statusRect = statusRectForWindow(panel)
        let panelRect = panel.frame

        let statusX = round(NSMidX(statusRect))
        let panelX = statusX - NSMinX(panelRect)

        backgroundView.arrowX = panelX
    }
}

// MARK: - (NSResponder)
extension MBPopupPanel {
    // Allow closing the popup with the escape key
    public override func cancelOperation(_ sender: Any?) {
        resignKey()
    }
}
