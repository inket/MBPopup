//
//  MBPopupClickInterceptorView.swift
//  MBPopup
//

import Foundation
import Cocoa

/// A transparent view covering the status item's button. It receives the button's mouse down events and ignores them,
/// so that the button doesn't run its own tracking loop (which would fight us over the highlight state, swallow the
/// mouse up, and break peeking). Opening/closing the popup is handled by the controller's event monitors instead.
final class MBPopupClickInterceptorView: NSView {
    override func mouseDown(with event: NSEvent) {}

    // Match the status bar button so the first click is delivered while the app is inactive
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
