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
    fileprivate var mainWindow: WindowDelegate?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        //NSApplication.sharedApplication().unhide(self)
        if flag {
            mainWindow?.window.orderFront(self)
        } else {
            mainWindow?.window.makeKeyAndOrderFront(self)
        }
        return true
    }
    
    func mainWindowDelegateDidLoad(_ sender: WindowDelegate) {
        mainWindow = sender
    }

}

