## MBPopup
![](https://img.shields.io/badge/Swift-3.0-orange.svg) ![](https://img.shields.io/badge/Carthage-supported-brightgreen.svg) ![](https://img.shields.io/badge/CocoaPods-supported-brightgreen.svg)

MBPopup is a macOS framework for easily adding a customizable status bar popup to your apps.

MBPopup is based on [Popup by shpakovski](https://github.com/shpakovski/Popup),
after it had been used in [HAPU](https://mahdi.jp/apps/hapu) for 3+ years and incrementally improved on,
and is now rewritten for Swift and improved for the Swift era.

More importantly, multiple parts have been rewritten in order to replicate the behavior of system menu bar items:
- Opens with the right event
- Closes on escape
- Allows peeking (hold click to open then release to close)
- Opens in the correct screen when clicked from a different (in)active screen
- Changes focus as expected
- etc.

While also,
- Reacting to Auto Layout constraints as expected
- Providing callbacks for user actions
- Allowing for different states when modifier keys are used

MBPopup is App Store-approved and is currently being used in the app [stts](https://itunes.apple.com/app/stts/id1187772509?ls=1&mt=12):

<img src="https://i.imgur.com/OAK3hR0.png" width="218" height="324" />


### Usage

(For more examples, check the __Example__ project, or [stts' source](https://github.com/inket/stts))

Add MBPopup via Carthage:

__Cartfile__
```
github "inket/MBPopup"
```

or via CocoaPods:

__Podfile__
```
pod "MBPopup"
```

Use MBPopup in your app:

```swift
import MBPopup

let myView = NSView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
let popupController = MBPopupController(contentView: myView)

// Use popupController.statusItem to customize the NSStatusItem, set a title or an image
popupController.statusItem.title = "Test"
popupController.statusItem.length = 70

// Use popupController.backgroundView to customize the popup's background
popupController.backgroundView.backgroundColor = NSColor.windowBackgroundColor // Default value

// Customize animations, view sizes
popupController.openDuration = 0.15 // Default value
popupController.closeDuration = 0.2 // Default value
popupController.arrowSize = CGSize(width: 12, height: 8) // Default value
popupController.contentInset = 1 // Default value

// Use callbacks to user actions
popupController.willOpenPopup = { keys in debugPrint("Will open popup!") }
popupController.didOpenPopup = { debugPrint("Opened popup!") }
popupController.willClosePopup = { debugPrint("Will close popup!") }
popupController.didClosePopup = { debugPrint("Closed popup!") }

// Resize your popup to your liking
popupController.resizePopup(width: 300, height: 400)
```

#### Contact

[@inket](https://github.com/inket) / [@inket](https://twitter.com/inket) on Twitter / [mahdi.jp](https://mahdi.jp)
