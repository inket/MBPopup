//
//  MBPopupExpandedInterfaceSession.swift
//  MBPopup
//

import Foundation
import Cocoa

// Starting with macOS 27, status items that show their own window instead of an NSMenu should let the system drive
// opening/closing via an "expanded interface session". This makes the status item stay highlighted while the popup is
// open, and lets the user move between our popup and other status items' menus like with system menus.
//
// NSStatusItemExpandedInterfaceDelegate only exists in the macOS 27 SDK (Xcode 27, Swift 6.4), hence the compiler check
// so the package still builds with older Xcode versions.

extension MBPopupController {
    var usesExpandedInterfaceSession: Bool {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            return true
        }
        #endif

        return false
    }

    func setupExpandedInterfaceSession() {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            statusItem.expandedInterfaceDelegate = self

            // While the session is active, clicks on the status item are handled by the system menu bar and never reach
            // our app, and the system doesn't end the session by itself. Watch for them globally to close the popup.
            self.mouseDownEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
                guard let self, isOpen else { return }

                if statusItem.globalRect(usingWindow: nil)?.contains(NSEvent.mouseLocation) == true {
                    closePopup()
                }
            }
        }
        #endif
    }

    /// Lets the system know that we closed the popup ourselves (escape key, clicking outside, `closePopup()`…)
    func endExpandedInterfaceSession() {
        #if compiler(>=6.4)
        if #available(macOS 27.0, *) {
            statusItem.expandedInterfaceSession?.cancel()
        }
        #endif
    }
}

#if compiler(>=6.4)
@available(macOS 27.0, *)
extension MBPopupController: @MainActor NSStatusItemExpandedInterfaceDelegate {
    public func statusItem(_ statusItem: NSStatusItem, didBegin session: NSStatusItemExpandedInterfaceSession) {
        guard !isOpen else { return }

        guard shouldOpenPopup?(currentModifiers) ?? true else {
            session.cancel()
            return
        }

        openPopup()
    }

    public func statusItemDidEndExpandedInterfaceSession(_ statusItem: NSStatusItem, animated: Bool) {
        guard isOpen else { return }

        closePopup()
    }
}
#endif
