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
    public static var openDuration: TimeInterval = 0.15
    public static var closeDuration: TimeInterval = 0.2
    public static var arrowSize = CGSize(width: 12, height: 8)
    static var statusItemButton: NSStatusBarButton?
}

public enum MBPopupKeys {
    case none
    case shift
    case option
    case shiftOption
}

public class MBPopupController: NSWindowController {
    public let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    public let panel = MBPopupPanel()

    public let backgroundView = MBPopupBackgroundView()
    public var contentView: NSView

    private(set) public var isOpen: Bool = false {
        didSet {
            // Highlight instantly if the popup is opened, but wait until the popup is closed to unhighlight
            if isOpen {
                statusItem.button?.isHighlighted = isOpen
            }
        }
    }
    fileprivate var isOpening: Bool = false

    public var willOpenPopup: ((MBPopupKeys) -> Void)?
    public var didOpenPopup: (() -> Void)?
    public var willClosePopup: (() -> Void)?
    public var didClosePopup: (() -> Void)?

    var lastMouseDownEvent: NSEvent?
    var mouseDownEventMonitor: Any?
    var mouseUpEventMonitor: Any?

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
        MBPopup.statusItemButton = statusItem.button

        self.mouseDownEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if self?.statusItem.shouldTrigger(forEvent: event) == true {
                self?.lastMouseDownEvent = event
                self?.togglePopup()
            }

            return event
        }

        self.mouseUpEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { [weak self] event in
            guard let lastMouseDownEvent = self?.lastMouseDownEvent else { return event }
            guard self?.isOpen == true else { return event }

            if self?.statusItem.shouldTrigger(forEvent: event) == true,
               event.timestamp - lastMouseDownEvent.timestamp > 0.35 {
                self?.togglePopup()
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

        contentView.setFrameOrigin(NSPoint(x: backgroundView.inset, y: backgroundView.inset))

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
        self.isOpening = true

        if let currentEvent = NSApp.currentEvent, currentEvent.type == .leftMouseDown {
            willOpenPopup?(currentEvent.pressedModifiers)
        } else {
            willOpenPopup?(.none)
        }

        self.isOpen = true

        contentView.isHidden = false
        let (_, _, panelRect) = rects(forPanel: panel)

        NSApp.activate(ignoringOtherApps: false)
        panel.alphaValue = 0
        panel.setFrame(panelRect, display: true)
        panel.makeKeyAndOrderFront(self)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = MBPopup.openDuration
            self.panel.animator().alphaValue = 1
        }, completionHandler: {
            self.isOpening = false

            if self.isOpen {
                self.didOpenPopup?()

                // Trying to open the popup from an inactive space/screen, will open the panel but lose key status
                // because the system's "active screen change" overrides it. If the panel isn't the key window, clicking
                // outside it won't close the popup. Therefore, we try to make the panel key _after_ opening it.
                self.panel.makeKeyAndOrderFront(self)
            }
        })
    }

    private func closePanel() {
        willClosePopup?()

        self.isOpen = false

        contentView.isHidden = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = MBPopup.closeDuration
            self.panel.animator().alphaValue = 0
        }, completionHandler: {
            guard !self.isOpen else { return }

            self.panel.orderOut(nil)
            self.statusItem.button?.isHighlighted = false
            self.didClosePopup?()
        })
    }

    // MARK: Calculating CGRects

    fileprivate func statusRect(forWindow window: NSWindow) -> CGRect {
        let statusItemWindow = lastMouseDownEvent?.clickedStatusItem?.realWindow

        var statusRect = statusItem.globalRect(usingWindow: statusItemWindow) ?? .zero
        statusRect.origin.y = statusRect.minY - statusRect.height
        return statusRect
    }

    private func rects(forPanel panel: NSPanel) -> (screenRect: CGRect, statusRect: CGRect, panelRect: CGRect) {
        let statusItemWindow = lastMouseDownEvent?.clickedStatusItem?.realWindow
        guard let screen = statusItemWindow?.screen else { return (CGRect.zero, CGRect.zero, CGRect.zero) }

        let screenRect = screen.frame
        let statusRect = self.statusRect(forWindow: panel)

        var panelRect = panel.frame
        panelRect.size.height = contentView.frame.height + 2 + MBPopup.arrowSize.height
        panelRect.size.width = contentView.frame.width + 2
        panelRect.origin.x = round(statusRect.midX - panelRect.width / 2)
        panelRect.origin.y = statusRect.maxY - panelRect.height

        if panelRect.maxX > (screenRect.maxX - MBPopup.arrowSize.height) {
            panelRect.origin.x -= panelRect.maxX - (screenRect.maxX - MBPopup.arrowSize.height)
        }

        return (screenRect, statusRect, panelRect)
    }

    // MARK: Deinitializing

    deinit {
        if let monitor = mouseDownEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        if let monitor = mouseUpEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        NSStatusBar.system().removeStatusItem(statusItem)
    }
}

// MARK: - (NSWindowDelegate)
extension MBPopupController: NSWindowDelegate {
    public func windowWillClose(_ notification: Notification) {
        closePopup()
    }

    public func windowDidResignKey(_ notification: Notification) {
        if window?.isVisible == true && !isOpening {
            closePopup()
        }
    }

    public func windowDidResize(_ notification: Notification) {
        let statusRect = self.statusRect(forWindow: panel)
        let panelRect = panel.frame

        let statusX = round(statusRect.midX)
        let panelX = statusX - panelRect.minX

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
