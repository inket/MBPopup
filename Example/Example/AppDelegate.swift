//
//  AppDelegate.swift
//  Example
//
//  Created by Mahdi Bchetnia on 16/8/25.
//  Copyright © 2016 Mahdi Bchetnia. See LICENSE.
//

import Cocoa
import MBPopup

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let popupController: MBPopupController
    let myView: NSView
    let label = NSTextField(frame: CGRect(x: 0, y: 175, width: 200, height: 50))

    override init() {
        // You can set the initial size this way, or later using `resizePopup`
        self.myView = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
        self.popupController = MBPopupController(contentView: myView)

        super.init()
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        popupController.statusItem.title = "MBPopup"
        popupController.statusItem.length = 70

        popupController.backgroundView.backgroundColor = NSColor.windowBackgroundColor // Default value

        popupController.openDuration = 0.15 // Default value
        popupController.closeDuration = 0.2 // Default value
        popupController.arrowSize = CGSize(width: 12, height: 8) // Default value
        popupController.contentInset = 1 // Default value

        popupController.willOpenPopup = { keys in
            var labelText = "Hi!"

            switch keys {
            case .option:
                debugPrint("Will open popup with option pressed!")
                labelText = "Hi, option user ;)"
            case .shift:
                debugPrint("Will open popup with shift pressed!")
            case .shiftOption:
                debugPrint("Will open popup with shift+option pressed!")
            case .none:
                debugPrint("Will open popup!")
            }

            self.label.stringValue = labelText
        }

        popupController.didOpenPopup = { debugPrint("Opened popup!") }
        popupController.willClosePopup = { debugPrint("Will close popup!") }
        popupController.didClosePopup = { debugPrint("Closed popup!") }

        label.font = NSFont.systemFont(ofSize: 24)
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = NSTextAlignment.center
        myView.addSubview(label)

        let resizeButton = NSButton(frame: CGRect(x: 60, y: 150, width: 80, height: 20))
        resizeButton.bezelStyle = .texturedSquare
        resizeButton.title = "Resize"
        resizeButton.target = self
        resizeButton.action = #selector(AppDelegate.resize)
        myView.addSubview(resizeButton)
    }

    func resize() {
        if myView.frame.size.height == 400 {
            popupController.resizePopup(width: 200, height: 300)
        } else {
            popupController.resizePopup(width: 300, height: 400)
        }
    }
}
