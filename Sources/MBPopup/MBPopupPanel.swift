//
//  MBPopupPanel.swift
//  MBPopup
//

import Foundation
import Cocoa

public class MBPopupPanel: NSPanel {}

// MARK: - (NSWindow)
extension MBPopupPanel {
    public override var canBecomeKey: Bool {
        get {
            // Allow the search field to become the first responder
            return true
        }
    }
}
