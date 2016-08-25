//
//  MBPopupPanel.swift
//  MBPopup
//
//  Created by Mahdi Bchetnia on 16/8/25.
//  Copyright © 2016 Mahdi Bchetnia. See LICENSE.
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
