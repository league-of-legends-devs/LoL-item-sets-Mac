//
//  AppDelegate.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa
import ServiceManagement

extension Notification.Name {
    static let kill = Notification.Name("kill-launcher")
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    fileprivate var mainWindow: WindowDelegate?
    var mainViewController: ViewController? = nil
    let launcherAppIdentifier = "me.melchor9000.LOL-Item-Sets-Launcher-Helper"
    @IBOutlet weak var openAtLoginMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        var startedAtLogin = false
        for app in NSWorkspace.shared().runningApplications {
            if app.bundleIdentifier == launcherAppIdentifier {
                startedAtLogin = true
                break
            }
        }

        if startedAtLogin {
            //Kill launcher helper if running
            DistributedNotificationCenter.default().post(name: .kill, object: Bundle.main.bundleIdentifier!)
        }

        if Configuration.instance.openAtLogin {
            openAtLoginMenuItem.state = NSOnState
        } else {
            openAtLoginMenuItem.state = NSOffState
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
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

    @IBAction func deleteInstalledItemSets(_ sender: NSMenuItem) {
        let viewCtrl: ViewController
        if #available(OSX 10.10, *) {
            viewCtrl = mainWindow?.window.contentViewController as! ViewController
        } else {
            viewCtrl = mainViewController!
        }

        viewCtrl.deleteInstalledFiles()
    }

    @IBAction func changeOpenAtLogin(_ sender: Any) {
        let menuItem = sender as! NSMenuItem
        if setOpenAtLogin(menuItem.state == NSOffState) {
            menuItem.state = menuItem.state == NSOffState ? NSOnState : NSOffState
            Configuration.instance.openAtLogin = menuItem.state == NSOnState
        } else {
            Util.showDialog("Could not change the open at login state", text: "For unknown reasons, we cannot change the state of the open at login to \(menuItem.state == NSOffState ? "on" : "off")", buttons: ["Ok"], icon: .warning)
        }
    }

    private func setOpenAtLogin(_ open: Bool) -> Bool {
        return SMLoginItemSetEnabled(launcherAppIdentifier as CFString, open)
    }
}

