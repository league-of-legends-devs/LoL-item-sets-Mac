//
//  Utilities.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Foundation
import Cocoa

class Util {
    static func downloadUrl(url: NSURL, cbk: (NSData?, NSHTTPURLResponse?, NSError?) -> Void) {
        let request = NSURLRequest.init(URL: url, cachePolicy: .ReloadIgnoringLocalCacheData, timeoutInterval: 5)
        NSURLSession.sharedSession().dataTaskWithRequest(request) { data, res, err in
            dispatch_async(dispatch_get_main_queue(), { 
                cbk(data, res as? NSHTTPURLResponse, err)
            })
        }.resume()
    }

    static func downloadString(url: NSURL, cbk: (String?, NSHTTPURLResponse?, NSError?) -> Void) {
        downloadUrl(url) { data, res, err in
            if data != nil {
                cbk(String(data: data!, encoding: NSUTF8StringEncoding)!, res, err)
            }
        }
    }
    
    static func downloadString(url: String, cbk: (String?, NSHTTPURLResponse?, NSError?) -> Void) {
        downloadString(NSURL(string: url)!, cbk: cbk)
    }
    
    static func exists(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.fileExistsAtPath(path)
    }
    
    static func canBeRead(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.isReadableFileAtPath(path)
    }
    
    static func canBeWritten(path: String) -> Bool {
        let fileManager = NSFileManager.defaultManager()
        return fileManager.isWritableFileAtPath(path)
    }
    
    static func createTempFile(fileName: String) -> (NSFileHandle, NSURL)? {
        let base = NSURL.fileURLWithPathComponents([NSTemporaryDirectory(), "XXXXXX.\(fileName)"])
        var buffer = [Int8](count: Int(PATH_MAX), repeatedValue: 0)
        base?.getFileSystemRepresentation(&buffer, maxLength: buffer.count)
        let fd = mkstemps(&buffer, fileName.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) + 1)
        if fd != -1 {
            return (NSFileHandle(fileDescriptor: fd, closeOnDealloc: true), NSURL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeToURL: nil))
        } else {
            return nil
        }
    }
    
    static func showDialog(title: String, text: String, buttons: [String] = ["Ok", "Cancel"], icon: NSAlertStyle = NSAlertStyle.WarningAlertStyle) -> UInt {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = title
        dialog.informativeText = text
        dialog.alertStyle = icon
        for button in buttons {
            dialog.addButtonWithTitle(button)
        }
        
        let a = dialog.runModal()
        if a == NSAlertFirstButtonReturn {
            return 1
        } else if a == NSAlertSecondButtonReturn {
            return 2
        } else if a == NSAlertThirdButtonReturn {
            return 3 + UInt(a - NSAlertThirdButtonReturn)
        }
        return 0
    }
    
    static func fromJSON(json: String) -> [String: AnyObject]? {
        do {
            return try NSJSONSerialization.JSONObjectWithData(json.dataUsingEncoding(NSUTF8StringEncoding)!, options: []) as? [String: AnyObject]
        } catch(_) {}
        return nil;
    }
    
    static func fromJSONDate(dateStr: String) -> NSDate? {
        let dateFor = NSDateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"
        return dateFor.dateFromString(dateStr)
    }
}

extension NSDate {
    var dateStr: String {
        get {
            let dateTo = NSDateFormatter()
            dateTo.locale = NSLocale(localeIdentifier: "en_GB")
            dateTo.timeZone = NSTimeZone.localTimeZone()
            dateTo.dateFormat = "dd MMM yyyy 'at' HH:mm"
            return dateTo.stringFromDate(self)
        }
    }
}