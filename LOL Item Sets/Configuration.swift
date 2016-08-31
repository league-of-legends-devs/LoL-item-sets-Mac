//
//  Configuration.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Foundation

class Configuration {
    private static var _instance: Configuration?
    private let storage: NSUserDefaults

    private init() {
        storage = NSUserDefaults.standardUserDefaults()
        storage.registerDefaults([
            "installedVersion": "0.0.0",
            "autoCheck": true
        ])
    }
    
    static var instance: Configuration {
        get {
            if _instance == nil {
                _instance = Configuration()
            }
            return _instance!
        }
    }
    
    struct Version {
        var major: UInt
        var minor: UInt
        var patch: UInt
        
        init(major: UInt, minor: UInt, patch: UInt) {
            self.major = major
            self.minor = minor
            self.patch = patch
        }
        
        init(fromString string: String) {
            let splitted = string.componentsSeparatedByString(".")
            major = UInt(splitted[0])!
            minor = UInt(splitted[1])!
            patch = UInt(splitted[2])!
        }
        
        func compare(other: Version) -> Int {
            if major > other.major {
                return 1
            } else if major < other.major {
                return -1
            } else {
                if minor > other.minor {
                    return 1
                } else if minor < other.minor {
                    return -1
                } else {
                    if patch > other.patch {
                        return 1
                    } else if patch < other.patch {
                        return -1
                    }
                }
            }
            
            return 0
        }
        
        func toString() -> String {
            return "\(major).\(minor).\(patch)"
        }
    }
    
    var installedVersion: Version {
        get {
            return Version(fromString: storage.stringForKey("installedVersion")!)
        }
        
        set {
            storage.setObject(newValue.toString(), forKey: "installedVersion")
        }
    }
    
    var autoCheck: Bool {
        get {
            return storage.boolForKey("autoCheck")
        }
        
        set {
            storage.setBool(newValue, forKey: "autoCheck")
        }
    }
    
    var installedDate: NSDate? {
        get {
            return storage.objectForKey("installedDate") as? NSDate
        }
        
        set {
            storage.setObject(newValue, forKey: "installedDate")
        }
    }
    
}