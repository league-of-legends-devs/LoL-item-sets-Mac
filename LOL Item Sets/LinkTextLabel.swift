//
//  LinkTextLabel.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 22/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa

class LinkTextLabel : NSTextField {
    fileprivate var url: Foundation.URL?
    fileprivate var trackingArea: NSTrackingArea?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        constr()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        constr()
    }
    
    fileprivate func constr() {
        let frameRect = NSMakeRect(0, 0, frame.width, frame.height)
        self.allowsEditingTextAttributes = true
        self.isSelectable = false
        let op = NSTrackingAreaOptions.mouseEnteredAndExited.union(.mouseMoved).union(.activeInKeyWindow)
        trackingArea = NSTrackingArea(rect: frameRect, options: op, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    @IBInspectable
    var URL: String? {
        set {
            let attrStr = NSMutableAttributedString(string: self.stringValue)
            if newValue != nil {
                self.url = Foundation.URL(string: newValue!)
                let range = NSMakeRange(0, self.stringValue.characters.count)
                attrStr.beginEditing()
                attrStr.addAttribute(NSLinkAttributeName, value: url!, range: range)
                attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: range)
                attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(value: 1 as Int32), range: range)
                attrStr.endEditing()
            } else {
                url = nil
            }
            
            DispatchQueue.main.async {
                self.attributedStringValue = attrStr
            }
        }
        
        get {
            return url?.absoluteString
        }
    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        super.mouseEntered(with: theEvent)
        NSCursor.pointingHand().push()
        NSCursor.pointingHand().set()
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        NSCursor.pointingHand().pop()
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        super.mouseUp(with: theEvent)
        if url != nil {
            NSWorkspace.shared().open(url!)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        removeTrackingArea(trackingArea!)
        
        let frameRect = NSMakeRect(0, 0, frame.width, frame.height)
        let op = NSTrackingAreaOptions.mouseEnteredAndExited.union(.mouseMoved).union(.activeInKeyWindow)
        trackingArea = NSTrackingArea(rect: frameRect, options: op, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
}
