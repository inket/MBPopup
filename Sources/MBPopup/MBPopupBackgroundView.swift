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
            updateGlassEffect()
            subviews.forEach { $0.needsLayout = true }
        }
    }

    /// Whether to use a Liquid Glass background like status item menus, on macOS 26 and later. The glass can't take
    /// the shape of the arrow, so `backgroundColor` is used instead while `showsArrow` is enabled.
    public var usesGlassEffect = false {
        didSet {
            updateGlassEffect()
        }
    }

    /// The background color, when not using the glass effect
    public var backgroundColor = NSColor.windowBackgroundColor {
        didSet {
            self.needsDisplay = true
        }
    }

    var arrowSize = CGSize(width: 12, height: 8)
    var showsArrow = false {
        didSet {
            updateGlassEffect()
        }
    }

    private var glassEffectView: NSView?

    private var showsGlassEffect: Bool {
        if #available(macOS 26.0, *) {
            return usesGlassEffect && !showsArrow
        } else {
            return false
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

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        updateGlassEffect()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        updateGlassEffect()
    }

    private func updateGlassEffect() {
        needsDisplay = true

        guard #available(macOS 26.0, *), showsGlassEffect else {
            glassEffectView?.removeFromSuperview()
            glassEffectView = nil
            layer?.mask = nil
            return
        }

        let glassEffectView = (self.glassEffectView as? NSGlassEffectView) ?? NSGlassEffectView(frame: bounds)
        glassEffectView.style = .regular
        glassEffectView.cornerRadius = cornerRadius
        glassEffectView.autoresizingMask = [.width, .height]

        if glassEffectView.superview == nil {
            glassEffectView.frame = bounds
            addSubview(glassEffectView, positioned: .below, relativeTo: nil)
        }

        self.glassEffectView = glassEffectView

        // The glass covers the whole rectangle as far as the window server is concerned, which gives the window a
        // rectangular shadow/border. Clip to the rounded shape so the corners are transparent.
        wantsLayer = true
        let mask = (layer?.mask) ?? CALayer()
        // Follow the view's size immediately, since implicit animations would make the popup lag behind when resizing
        mask.actions = ["bounds": NSNull(), "position": NSNull(), "cornerRadius": NSNull()]
        mask.backgroundColor = NSColor.black.cgColor
        mask.cornerRadius = cornerRadius
        mask.cornerCurve = .continuous
        mask.frame = bounds
        layer?.mask = mask
        window?.invalidateShadow()
    }

    public override func layout() {
        super.layout()

        if let mask = layer?.mask {
            mask.frame = bounds
            window?.invalidateShadow()
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
        guard !showsGlassEffect, let context = NSGraphicsContext.current?.cgContext else { return }

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
