//
//  AppDelegate.swift
//  LOL Item Sets Launcher Helper
//
//  Created by Melchor Garau Madrigal on 19/4/17.
//  Copyright © 2017 melchor629. All rights reserved.
//

import Cocoa

extension Notification.Name {
    static let kill = Notification.Name("kill-launcher")
}

@NSApplicationMain
class HelperDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let mainAppIdentifier = "org.melchor629.LOL-Item-Sets"
        var alreadyRunning = false

        for app in NSWorkspace.shared().runningApplications {
            if app.bundleIdentifier == mainAppIdentifier {
                alreadyRunning = true
                break
            }
        }

        if !alreadyRunning {
            //Wait to the kill notification
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(self.terminate), name: .kill, object: mainAppIdentifier)

            //Look for the executable in the main app
            let path = Bundle.main.bundlePath as NSString
            var components = path.pathComponents
            components.removeLast()
            components.removeLast()
            components.removeLast()
            components.append("MacOS")
            components.append("LOL Item Stats")

            //Launch it
            let newPath = NSString.path(withComponents: components)
            NSWorkspace.shared().launchApplication(newPath)
        } else {
            self.terminate()
        }
    }

    @objc fileprivate func terminate() {
        NSApp.terminate(nil)
    }

}

