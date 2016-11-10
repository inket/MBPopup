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
    public var cornerRadius: CGFloat = 6
    public var backgroundColor = NSColor.windowBackgroundColor

    var arrowSize = CGSize(width: 12, height: 8)

    private let kappa: CGFloat = 0.55

    var arrowX: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        let contentRect = self.bounds
        let path = NSBezierPath()

        let maxX = contentRect.maxX
        let minX = contentRect.minX
        let maxY = contentRect.maxY - arrowSize.height
        let minY = contentRect.minY
        let cornerControlPoint: CGFloat = -cornerRadius + (cornerRadius * kappa)

        // Arrow
        path.move(to: CGPoint(x: arrowX, y: contentRect.maxY))
        path.line(to: CGPoint(x: arrowX + arrowSize.width / 2, y: maxY))
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

        path.line(to: CGPoint(x: arrowX - arrowSize.width / 2, y: maxY))
        path.close()

        backgroundColor.setFill()
        path.fill()
    }
}

public class MBPopupContainerView: NSView {
    public var contentInset: CGFloat = 1

    var contentView: NSView? {
        didSet {
            removeConstraints(constraints)
            guard let contentView = contentView else { return }

            contentView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(contentView)
            ["H:|-0-[contentView]-0-|", "V:|-0-[contentView]-0-|"].forEach {
                addConstraints(NSLayoutConstraint.constraints(withVisualFormat: $0,
                                                              options: .directionLeadingToTrailing,
                                                              metrics: nil,
                                                              views: ["contentView": contentView]))
            }
        }
    }

    var superviewConstraints = [NSLayoutConstraint]()

    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        resetConstraints()
    }

    func resetConstraints() {
        guard let superview = superview as? MBPopupBackgroundView else { return }

        superview.removeConstraints(superviewConstraints)

        let horizontalFormat = "H:|-\(contentInset)-[containerView]-\(contentInset)-|"
        let verticalFormat = "V:|-\(superview.arrowSize.height + contentInset)-[containerView]-\(contentInset)-|"

        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: horizontalFormat,
                                                                   options: .directionLeadingToTrailing,
                                                                   metrics: nil,
                                                                   views: ["containerView" : self])
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: verticalFormat,
                                                                 options: .directionLeadingToTrailing,
                                                                 metrics: nil,
                                                                 views: ["containerView" : self])

        self.superviewConstraints = horizontalConstraints + verticalConstraints
        superview.addConstraints(superviewConstraints)
    }
}
