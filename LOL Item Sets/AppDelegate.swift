//
//  AppDelegate.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: WindowDelegate?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        //NSApplication.sharedApplication().unhide(self)
        if flag {
            mainWindow?.window.orderFront(self)
        } else {
            mainWindow?.window.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    func mainWindowDelegateDidLoad(sender: WindowDelegate) {
        mainWindow = sender
    }

}

