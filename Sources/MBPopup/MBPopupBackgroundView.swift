//
//  MBPopupBackgroundView.swift
//  MBPopup
//

import Foundation
import Cocoa
import SwiftUI

public class MBPopupBackgroundView: NSView {
    /// Matches the corner radius of status item menus: 12 on macOS 26 and later, 6 on macOS 14–15
    public var cornerRadius: CGFloat = MBPopupBackgroundView.defaultCornerRadius {
        didSet {
            self.needsDisplay = true
            subviews.forEach { $0.needsLayout = true }
        }
    }

    public var backgroundColor = NSColor.windowBackgroundColor

    var arrowSize = CGSize(width: 12, height: 8)
    var showsArrow = false {
        didSet {
            self.needsDisplay = true
        }
    }

    /// The space taken by the arrow, `.zero` when it's hidden
    var visibleArrowSize: CGSize {
        return showsArrow ? arrowSize : .zero
    }

    var arrowX: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }

    static var defaultCornerRadius: CGFloat {
        if #available(macOS 26.0, *) {
            return 12
        } else {
            return 6
        }
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        let arrowSize = visibleArrowSize
        var bodyRect = self.bounds
        bodyRect.size.height -= arrowSize.height

        // Continuous ("squircle") corners like system menus and windows
        let path = CGMutablePath()
        path.addPath(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous).path(in: bodyRect).cgPath
        )

        if showsArrow {
            path.addLines(between: [
                CGPoint(x: arrowX - arrowSize.width / 2, y: bodyRect.maxY),
                CGPoint(x: arrowX, y: self.bounds.maxY),
                CGPoint(x: arrowX + arrowSize.width / 2, y: bodyRect.maxY),
            ])
            path.closeSubpath()
        }

        context.addPath(path)
        context.setFillColor(backgroundColor.cgColor)
        context.fillPath()
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

    public override func layout() {
        super.layout()

        // Clip the content to the popup's rounded corners
        guard let superview = superview as? MBPopupBackgroundView else { return }
        wantsLayer = true
        layer?.cornerRadius = max(superview.cornerRadius - contentInset, 0)
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
    }

    func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false
        resetConstraints()
    }

    func resetConstraints() {
        guard let superview = superview as? MBPopupBackgroundView else { return }

        superview.removeConstraints(superviewConstraints)

        let horizontalFormat = "H:|-\(contentInset)-[containerView]-\(contentInset)-|"
        let verticalFormat = "V:|-\(superview.visibleArrowSize.height + contentInset)-[containerView]-\(contentInset)-|"

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
