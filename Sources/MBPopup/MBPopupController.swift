//
//  MBPopupController.swift
//  MBPopup
//

import Foundation
import Cocoa

public enum MBPopupKeys {
    case none
    case shift
    case option
    case shiftOption
}

/// How the popup is positioned horizontally relative to its status item
public enum MBPopupAlignment {
    /// Centered under the status item
    case centered
    /// Like status item menus: the popup's leading edge is aligned with the status item's leading edge, or its trailing
    /// edge with the status item's trailing edge when it wouldn't fit on screen otherwise
    case natural
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

    public var alignment: MBPopupAlignment = .natural

    public var showsArrow: Bool {
        get { return backgroundView.showsArrow }
        set {
            let size = containerView.frame.size
            backgroundView.showsArrow = newValue
            resizePopup(width: size.width, height: size.height)
        }
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

    /// Space between the bottom of the menu bar and the top of the popup
    private let menuBarSpacing: CGFloat = 1

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
        if usesExpandedInterfaceSession {
            setupExpandedInterfaceSession()
        } else {
            setupClickHandling()
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

    private func setupClickHandling() {
        if let button = statusItem.button {
            let clickInterceptor = MBPopupClickInterceptorView(frame: button.bounds)
            clickInterceptor.autoresizingMask = [.width, .height]
            button.addSubview(clickInterceptor)
        }

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
        newSize.height += backgroundView.visibleArrowSize.height + contentInset * 2
        newSize.width += contentInset * 2

        frame.origin.y -= newSize.height - frame.size.height
        frame.size.height = newSize.height

        let widthDifference = newSize.width - frame.size.width
        if widthDifference != 0 {
            if panel.isVisible {
                let (screenRect, statusRect, _) = rects(forPanel: panel)
                frame.origin.x = panelOriginX(forWidth: newSize.width, statusRect: statusRect, screenRect: screenRect)
            } else {
                frame.origin.x -= widthDifference / 2
            }
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

        willOpenPopup?(currentModifiers)

        self.isOpen = true

        contentView.isHidden = false
        let (_, _, panelRect) = rects(forPanel: panel)

        NSApp.activate()
        panel.alphaValue = 0
        panel.setFrame(panelRect, display: true)

        repositionPopupArrow()

        panel.makeKeyAndOrderFront(self)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = openDuration
            self.panel.animator().alphaValue = 1
        }, completionHandler: {
            // AppKit calls animation completion handlers on the main thread
            MainActor.assumeIsolated {
                self.isOpening = false

                if self.isOpen {
                    self.didOpenPopup?()

                    // Trying to open the popup from an inactive space/screen, will open the panel but lose key status
                    // because the system's "active screen change" overrides it. If the panel isn't the key window,
                    // clicking outside it won't close the popup. Therefore, we try to make the panel key _after_
                    // opening it.
                    self.panel.makeKeyAndOrderFront(self)
                }
            }
        })
    }

    private func closePanel() {
        willClosePopup?()

        self.isOpen = false

        endExpandedInterfaceSession()

        contentView.isHidden = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = closeDuration
            self.panel.animator().alphaValue = 0
        }, completionHandler: {
            // AppKit calls animation completion handlers on the main thread
            MainActor.assumeIsolated {
                guard !self.isOpen else { return }

                self.panel.orderOut(nil)
                self.statusItem.button?.isHighlighted = false
                self.didClosePopup?()
            }
        })
    }

    /// The modifiers held while opening the popup: those of the clicking event if there is one, otherwise the ones
    /// currently held (e.g. when the popup is opened programmatically or by moving over from another menu)
    var currentModifiers: MBPopupKeys {
        if let currentEvent = NSApp.currentEvent, currentEvent.type == .leftMouseDown {
            return currentEvent.pressedModifiers
        } else {
            return MBPopupKeys(modifierFlags: NSEvent.modifierFlags)
        }
    }

    // MARK: Calculating CGRects

    /// The window of the status item that was clicked by the user (which can be a replica on another screen before
    /// macOS 15), or our status item's window if the popup wasn't opened by clicking
    private var statusItemWindow: NSWindow? {
        return lastMouseDownEvent?.clickedStatusItem?.realWindow ?? statusItem.button?.window
    }

    /// The edges that status item menus align to. Starting with macOS 26, menus extend 5pt past the status item's
    /// window.
    private func menuAlignmentRect(fallback statusRect: CGRect) -> CGRect {
        guard let frame = statusItemWindow?.frame else { return statusRect }

        if #available(macOS 26.0, *) {
            return frame.insetBy(dx: -5, dy: 0)
        } else {
            return frame
        }
    }

    fileprivate func statusRect(forWindow window: NSWindow) -> CGRect {
        var statusRect = statusItem.globalRect(usingWindow: statusItemWindow) ?? .zero

        // Place the popup below the menu bar rather than below the button, which is shorter than the menu bar. The
        // status item's window spans the full menu bar height.
        let menuBarMinY = statusItemWindow?.frame.minY ?? statusRect.minY
        statusRect.origin.y = menuBarMinY - menuBarSpacing - statusRect.height
        return statusRect
    }

    private func rects(forPanel panel: NSPanel) -> (screenRect: CGRect, statusRect: CGRect, panelRect: CGRect) {
        // Get the screen containing the status item, or the main screen
        guard let screen = statusItemWindow?.screen ?? NSScreen.main else {
            return (CGRect.zero, CGRect.zero, CGRect.zero)
        }

        let screenRect = screen.frame
        let statusRect = self.statusRect(forWindow: panel)

        var panelRect = panel.frame
        panelRect.origin.x = panelOriginX(forWidth: panelRect.width, statusRect: statusRect, screenRect: screenRect)
        panelRect.origin.y = statusRect.maxY - panelRect.size.height

        return (screenRect, statusRect, panelRect)
    }

    /// The panel's horizontal position for the given width, following `alignment` and keeping it on screen
    private func panelOriginX(forWidth width: CGFloat, statusRect: CGRect, screenRect: CGRect) -> CGFloat {
        switch alignment {
        case .centered:
            let x = round(statusRect.midX - width / 2)
            let maxX = screenRect.maxX - arrowSize.height
            return x + width > maxX ? maxX - width : x
        case .natural:
            let alignmentRect = menuAlignmentRect(fallback: statusRect)
            let leftAligned = alignmentRect.minX
            let rightAligned = alignmentRect.maxX - width

            if NSApp.userInterfaceLayoutDirection == .rightToLeft {
                return rightAligned >= screenRect.minX ? rightAligned : leftAligned
            } else {
                return leftAligned + width <= screenRect.maxX ? leftAligned : rightAligned
            }
        }
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

    isolated deinit {
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
