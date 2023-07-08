//
//  MBPopupExtensions.swift
//  MBPopup
//

import Foundation
import Cocoa

extension NSEvent {
    var pressedModifiers: MBPopupKeys {
        let clearFlags = self.modifierFlags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue
        let shiftFlags = NSEvent.ModifierFlags.shift.rawValue
        let optionFlags = NSEvent.ModifierFlags.option.rawValue
        let shiftOptionFlags = NSEvent.ModifierFlags.shift.rawValue | NSEvent.ModifierFlags.option.rawValue

        if clearFlags == shiftOptionFlags {
            return .shiftOption
        } else if clearFlags == shiftFlags {
            return .shift
        } else if clearFlags == optionFlags {
            return .option
        } else {
            return .none
        }
    }

    var clickedStatusItem: NSStatusItem? {
        guard let window = window else { return nil }

        // Make sure our target window is that of a status item, with the class NSStatusBarWindow
        guard window.className.hasPrefix("NSStatusBar"), window.className.hasSuffix("Window") else { return nil }

        // Get the status item of the clicked status bar window,
        // which can be an NSStatusItem or an NSStatusItemReplicant
        return window.value(forKey: "statusItem") as? NSStatusItem
    }
}

extension NSStatusItem {
    var realItem: NSStatusItem? {
        if className == "NSStatusItem" {
            return self
        } else {
            // In the case of an NSStatusItemReplicant (a replica for displaying the status item on inactive
            // spaces/screens that happens to be an NSStatusItem subclass), we get the NSStatusItem that's being
            // replicated from the property "parentItem".
            return value(forKey: "parentItem") as? NSStatusItem
        }
    }

    var realWindow: NSWindow? {
        if className == "NSStatusItem" {
            return button?.window
        } else {
            // In the case of an NSStatusItemReplicant, we get the window from the property "window"
            // as using button?.window will return the original status item's window.
            return value(forKey: "window") as? NSWindow
        }
    }

    /**
     Transform the button's rectangle in relation to the screen's coordinates.

     - parameter referenceWindow: The window to use as a reference to determine which screen coordinates we're
     interested in.

     - returns: A CGRect representing the button's position and size on screen.
     */
    func globalRect(usingWindow referenceWindow: NSWindow?) -> CGRect? {
        guard let button = button else { return nil }

        var buttonRect = button.frame
        let rectInWindow = button.convert(buttonRect, to: nil)

        if let frameInScreen = (referenceWindow ?? button.window)?.convertToScreen(rectInWindow) {
            buttonRect.origin = frameInScreen.origin
            return buttonRect
        }

        return nil
    }

    /**
     Determine whether the event represents a click on this status item or not.

     - parameter event: The event to check

     - returns: `true` if the event on the button, `false` if it's not.
     */
    func shouldTrigger(forEvent event: NSEvent) -> Bool {
        let sameButton = button != nil && button == event.clickedStatusItem?.realItem?.button
        let sameWindow = event.window != nil && event.window == event.clickedStatusItem?.realWindow
        let bartenderEvent = event.eventNumber == 1337

        // Command-click is used to move the status bar item in newer macOS versions, so we shouldn't open the popup
        // in that case. This doesn't apply when other modifiers are pressed (like command-opt-click)
        let isMoveEvent =
            event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
            && event.type == .leftMouseDown

        return sameButton && sameWindow && !bartenderEvent && !isMoveEvent
    }
}

extension NSStatusBarButton {
    override open func mouseDown(with event: NSEvent) {
        guard self != MBPopup.statusItemButton else { return }

        super.mouseDown(with: event)
    }
}
