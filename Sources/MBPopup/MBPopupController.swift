//
//  MBPopupController.swift
//  MBPopup
//

import Foundation
import Cocoa

public struct MBPopup {
    static var statusItemButton: NSStatusBarButton?
}

public enum MBPopupKeys {
    case none
    case shift
    case option
    case shiftOption
}

public class MBPopupController: NSWindowController {
    public let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    public let panel = MBPopupPanel()

    public let backgroundView = MBPopupBackgroundView()
    public let containerView = MBPopupContainerView()
    public var contentView: NSView

    public var openDuration: TimeInterval = 0.15
    public var closeDuration: TimeInterval = 0.2

    public var arrowSize: CGSize {
        get { return backgroundView.arrowSize }
        set { backgroundView.arrowSize = newValue }
    }

    public var contentInset: CGFloat {
        get { return containerView.contentInset }
        set {
            let size = containerView.frame.size
            containerView.contentInset = newValue
            resizePopup(width: size.width, height: size.height)
        }
    }

    private(set) public var isOpen: Bool = false {
        didSet {
            // Highlight instantly if the popup is opened, but wait until the popup is closed to unhighlight
            if isOpen {
                statusItem.button?.isHighlighted = isOpen
            }
        }
    }
    fileprivate var isOpening: Bool = false

    public var shouldOpenPopup: ((MBPopupKeys) -> Bool)?
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
            let shouldOpenPopup =
                self?.statusItem.shouldTrigger(forEvent: event) == true
                && self?.shouldOpenPopup?(event.pressedModifiers) ?? true

            if shouldOpenPopup {
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
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = NSColor.clear
        panel.styleMask = .nonactivatingPanel
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.delegate = self
        panel.contentView = backgroundView
        backgroundView.addSubview(containerView)

        let contentSize = contentView.frame.size

        containerView.setup()
        containerView.contentView = contentView

        panel.initialFirstResponder = contentView

        resizePopup(width: contentSize.width, height: contentSize.height)
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

    /**
     Resizes the panel (animated). Although the background view will be resized with the panel, your content view will
     not be, unless it's using auto-layout constraints to match the background view's size.

     - parameter width: The desired width
     - parameter height: The desired height
     */
    public func resizePopup(width: CGFloat, height: CGFloat) {
        var frame = panel.frame

        var newSize = CGSize(width: width, height: height)
        newSize.height += arrowSize.height + contentInset * 2
        newSize.width += contentInset * 2

        frame.origin.y -= newSize.height - frame.size.height
        frame.size.height = newSize.height

        let widthDifference = newSize.width - frame.size.width
        if widthDifference != 0 {
            frame.origin.x -= widthDifference / 2
            frame.size.width = newSize.width
        }

        containerView.resetConstraints()
        panel.setFrame(frame, display: true, animate: panel.isVisible)
    }

    /**
     Resizes the panel (animated). Although the background view will be resized with the panel, your content view will
     not be, unless it's using auto-layout constraints to match the background view's size.

     - parameter width: The desired width
     */
    public func resizePopup(width: CGFloat) {
        resizePopup(width: width, height: contentView.frame.size.height)
    }

    /**
     Resizes the panel (animated). Although the background view will be resized with the panel, your content view will
     not be, unless it's using auto-layout constraints to match the background view's size.

     - parameter height: The desired height
     */
    public func resizePopup(height: CGFloat) {
        resizePopup(width: contentView.frame.size.width, height: height)
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

        repositionPopupArrow()

        panel.makeKeyAndOrderFront(self)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = openDuration
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
            context.duration = closeDuration
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
        // Get the screen containing the status item that was clicked by the user
        // If no click happened (panel opened programmatically), use the main screen
        let statusItemWindow = lastMouseDownEvent?.clickedStatusItem?.realWindow
        guard let screen = statusItemWindow?.screen ?? NSScreen.main else {
            return (CGRect.zero, CGRect.zero, CGRect.zero)
        }

        let screenRect = screen.frame
        let statusRect = self.statusRect(forWindow: panel)

        var panelRect = panel.frame
        panelRect.origin.x = round(statusRect.midX - panelRect.width / 2)
        panelRect.origin.y = statusRect.maxY - panelRect.size.height

        if panelRect.maxX > (screenRect.maxX - arrowSize.height) {
            panelRect.origin.x -= panelRect.maxX - (screenRect.maxX - arrowSize.height)
        }

        return (screenRect, statusRect, panelRect)
    }

    // MARK: Repositioning/Resizing Views when needed

    func repositionPopupArrow() {
        let statusRect = self.statusRect(forWindow: panel)
        let panelRect = panel.frame

        let statusX = round(statusRect.midX)
        let panelX = statusX - panelRect.minX

        backgroundView.arrowX = panelX
    }

    // MARK: Deinitializing

    deinit {
        if let monitor = mouseDownEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        if let monitor = mouseUpEventMonitor {
            NSEvent.removeMonitor(monitor)
        }

        NSStatusBar.system.removeStatusItem(statusItem)
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
        repositionPopupArrow()
    }
}

// MARK: - (NSResponder)
extension MBPopupPanel {
    // Allow closing the popup with the escape key
    public override func cancelOperation(_ sender: Any?) {
        resignKey()
    }
}
