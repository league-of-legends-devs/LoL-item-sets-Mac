//
//  LinkTextLabel.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 22/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa

class LinkTextLabel : NSTextField {
    private var url: NSURL?
    private var trackingArea: NSTrackingArea?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        constr()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        constr()
    }
    
    private func constr() {
        let frameRect = NSMakeRect(0, 0, frame.width, frame.height)
        self.allowsEditingTextAttributes = true
        self.selectable = false
        let op = NSTrackingAreaOptions.MouseEnteredAndExited.union(.MouseMoved).union(.ActiveInKeyWindow)
        trackingArea = NSTrackingArea(rect: frameRect, options: op, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
    @IBInspectable
    var URL: String? {
        set {
            let attrStr = NSMutableAttributedString(string: self.stringValue)
            if newValue != nil {
                self.url = NSURL(string: newValue!)
                let range = NSMakeRange(0, self.stringValue.characters.count)
                attrStr.beginEditing()
                attrStr.addAttribute(NSLinkAttributeName, value: url!, range: range)
                attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blueColor(), range: range)
                attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(int: 1), range: range)
                attrStr.endEditing()
            } else {
                url = nil
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.attributedStringValue = attrStr
            }
        }
        
        get {
            return url?.absoluteString
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        super.mouseEntered(theEvent)
        NSCursor.pointingHandCursor().push()
        NSCursor.pointingHandCursor().set()
        Swift.print("Enter")
    }
    
    override func mouseExited(theEvent: NSEvent) {
        super.mouseExited(theEvent)
        NSCursor.pointingHandCursor().pop()
        Swift.print("Exit")
    }
    
    override func mouseUp(theEvent: NSEvent) {
        super.mouseUp(theEvent)
        if url != nil {
            NSWorkspace.sharedWorkspace().openURL(url!)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        removeTrackingArea(trackingArea!)
        
        let frameRect = NSMakeRect(0, 0, frame.width, frame.height)
        let op = NSTrackingAreaOptions.MouseEnteredAndExited.union(.MouseMoved).union(.ActiveInKeyWindow)
        trackingArea = NSTrackingArea(rect: frameRect, options: op, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }
    
}
