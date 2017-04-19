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
    static func downloadUrl(_ url: URL, cbk: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 5)
        URLSession.shared.dataTask(with: request, completionHandler: { data, res, err in
            DispatchQueue.main.async(execute: { 
                cbk(data, res as? HTTPURLResponse, err)
            })
            return
        }).resume()
    }

    static func downloadString(_ url: URL, cbk: @escaping (String?, HTTPURLResponse?, Error?) -> Void) {
        downloadUrl(url) { data, res, err in
            if data != nil {
                cbk(String(data: data!, encoding: String.Encoding.utf8)!, res, err)
            } else {
                cbk(nil, res, err)
            }
        }
    }
    
    static func downloadString(_ url: String, cbk: @escaping (String?, HTTPURLResponse?, Error?) -> Void) {
        downloadString(URL(string: url)!, cbk: cbk)
    }
    
    static func exists(_ path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: path)
    }
    
    static func canBeRead(_ path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.isReadableFile(atPath: path)
    }
    
    static func canBeWritten(_ path: String) -> Bool {
        let fileManager = FileManager.default
        return fileManager.isWritableFile(atPath: path)
    }

    static func createTempFile(_ fileName: String) -> (FileHandle, URL)? {
        let base = URL.init(fileURLWithPath: NSTemporaryDirectory() + "/XXXXXX.\(fileName)")
        var buffer = [Int8](repeating: 0, count: Int(PATH_MAX))
        (base as NSURL?)?.getFileSystemRepresentation(&buffer, maxLength: buffer.count)
        let fd = mkstemps(&buffer, Int32(fileName.lengthOfBytes(using: String.Encoding.utf8)) + 1)
        if fd != -1 {
            return (FileHandle(fileDescriptor: fd, closeOnDealloc: true), URL(fileURLWithFileSystemRepresentation: buffer, isDirectory: false, relativeTo: nil))
        } else {
            return nil
        }
    }
    
    static func showDialog(withOptions title: String, text: String, buttons: [String] = ["Ok", "Cancel"], icon: NSAlertStyle = NSAlertStyle.warning) -> UInt {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = title
        dialog.informativeText = text
        dialog.alertStyle = icon
        for button in buttons {
            dialog.addButton(withTitle: button)
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
    
    static func showDialog(_ title: String, text: String, buttons: [String] = ["Ok", "Cancel"], icon: NSAlertStyle = NSAlertStyle.warning) {
        let dialog: NSAlert = NSAlert()
        dialog.messageText = title
        dialog.informativeText = text
        dialog.alertStyle = icon
        for button in buttons {
            dialog.addButton(withTitle: button)
        }
        
        dialog.runModal()
    }
    
    static func fromJSON(_ json: String) -> [String: AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: json.data(using: String.Encoding.utf8)!, options: []) as? [String: AnyObject]
        } catch(_) {}
        return nil;
    }
    
    static func fromJSONDate(_ dateStr: String) -> Date? {
        let dateFor = DateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"
        return dateFor.date(from: dateStr)
    }
}

extension Date {
    var dateStr: String {
        get {
            let dateTo = DateFormatter()
            dateTo.locale = Locale(identifier: "en_GB")
            dateTo.timeZone = TimeZone.autoupdatingCurrent
            dateTo.dateFormat = "dd MMM yyyy 'at' HH:mm"
            return dateTo.string(from: self)
        }
    }
}
