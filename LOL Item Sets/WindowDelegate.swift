//
//  WindowDelegate.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa

class WindowDelegate : NSObject, NSWindowDelegate {
    @IBOutlet weak var window: NSWindow!
    
    override init() {
        super.init()
        (NSApplication.sharedApplication().delegate as! AppDelegate).mainWindowDelegateDidLoad(self)
    }
}