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

    func boundsContain(point: CGPoint) -> Bool {
        // NSPointInRect treats the upper edge of the rectangle as being outside the boundaries,
        // so a point in the upper edge of the button (or the screen's) is considered outside the button.
        // We compensate for that by faking a 1pt bigger button size.
        var buttonBounds = bounds
        buttonBounds.size.height += 1

        return NSPointInRect(point, buttonBounds)
    }
}
