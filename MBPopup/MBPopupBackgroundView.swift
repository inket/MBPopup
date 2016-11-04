//
//  MBPopupBackgroundView.swift
//  MBPopup
//
//  Created by Mahdi Bchetnia on 16/8/25.
//  Copyright © 2016 Mahdi Bchetnia. See LICENSE.
//

import Foundation
import Cocoa

public class MBPopupBackgroundView: NSView {
    public var inset: CGFloat = 1 {
        didSet {
            guard let subview = subviews.first else { return }
            subview.setFrameOrigin(NSPoint(x: inset, y: inset))
        }
    }
    public var cornerRadius: CGFloat = 6
    public var backgroundColor = NSColor.windowBackgroundColor

    private let kappa: CGFloat = 0.55

    public var arrowX: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        let contentRect = self.bounds
        let path = NSBezierPath()

        let maxX = contentRect.maxX
        let minX = contentRect.minX
        let maxY = contentRect.maxY - MBPopup.arrowSize.height
        let minY = contentRect.minY
        let cornerControlPoint: CGFloat = -cornerRadius + (cornerRadius * kappa)

        // Arrow
        path.move(to: CGPoint(x: arrowX, y: contentRect.maxY))
        path.line(to: CGPoint(x: arrowX + MBPopup.arrowSize.width / 2, y: maxY))
        path.line(to: CGPoint(x: maxX - cornerRadius, y: maxY))

        // Top right corner
        path.curve(to: CGPoint(x: maxX, y: maxY - cornerRadius),
                   controlPoint1: CGPoint(x: maxX + cornerControlPoint, y: maxY),
                   controlPoint2: CGPoint(x: maxX, y: maxY + cornerControlPoint))

        path.line(to: CGPoint(x: maxX, y: minY + cornerRadius))

        // Bottom right corner
        path.curve(to: CGPoint(x: maxX - cornerRadius, y: minY),
                   controlPoint1: CGPoint(x: maxX, y: minY - cornerControlPoint),
                   controlPoint2: CGPoint(x: maxX + cornerControlPoint, y: minY))

        path.line(to: CGPoint(x: minX + cornerRadius, y: minY))

        // Bottom left corner
        path.curve(to: CGPoint(x: minX, y: minY + cornerRadius),
                   controlPoint1: CGPoint(x: minX - cornerControlPoint, y: minY),
                   controlPoint2: CGPoint(x: minX, y: minY - cornerControlPoint))

        path.line(to: CGPoint(x: minX, y: maxY - cornerRadius))

        // Top left corner
        path.curve(to: CGPoint(x: minX + cornerRadius, y: maxY),
                   controlPoint1: CGPoint(x: minX, y: maxY + cornerControlPoint),
                   controlPoint2: CGPoint(x: minX - cornerControlPoint, y: maxY))

        path.line(to: CGPoint(x: arrowX - MBPopup.arrowSize.width / 2, y: maxY))
        path.close()

        backgroundColor.setFill()
        path.fill()
    }
}
