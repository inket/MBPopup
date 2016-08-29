//
//  MBPopupExtensions.swift
//  MBPopup
//
//  Created by Mahdi Bchetnia on 16/8/25.
//  Copyright © 2016 Mahdi Bchetnia. See LICENSE.
//

import Foundation
import Cocoa

extension NSEvent {
    func mbpopup_pressedModifiers() -> MBPopupKeys {
        let clearFlags = self.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue
        let shiftFlags = NSEventModifierFlags.shift.rawValue
        let optionFlags = NSEventModifierFlags.option.rawValue
        let shiftOptionFlags = NSEventModifierFlags.shift.rawValue | NSEventModifierFlags.option.rawValue

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
}

extension NSStatusBarButton {
    var globalRect: CGRect? {
        var buttonRect = frame
        let rectInWindow = convert(buttonRect, to: nil)

        guard let frameInScreen = window?.convertToScreen(rectInWindow) else { return nil }
        buttonRect.origin = frameInScreen.origin
        
        return buttonRect
    }
}
