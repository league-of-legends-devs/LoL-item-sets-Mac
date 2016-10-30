//
//  Configuration.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Foundation

class Configuration {
    fileprivate static var _instance: Configuration?
    fileprivate let storage: UserDefaults

    fileprivate init() {
        storage = UserDefaults.standard
        storage.register(defaults: [
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
        
        init?(fromString string: String) {
            let splitted = string.components(separatedBy: ".")
            if splitted.count != 3 {
                return nil
            }
            
            let major = UInt(splitted[0])
            let minor = UInt(splitted[1])
            let patch = UInt(splitted[2])
            
            if major == nil || minor == nil || patch == nil {
                return nil
            } else {
                self.major = major!
                self.minor = minor!
                self.patch = patch!
            }
        }
        
        func compare(_ other: Version) -> Int {
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
            return Version(fromString: storage.string(forKey: "installedVersion")!)!
        }
        
        set {
            storage.set(newValue.toString(), forKey: "installedVersion")
        }
    }
    
    var autoCheck: Bool {
        get {
            return storage.bool(forKey: "autoCheck")
        }
        
        set {
            storage.set(newValue, forKey: "autoCheck")
        }
    }
    
    var installedDate: Date? {
        get {
            return storage.object(forKey: "installedDate") as? Date
        }
        
        set {
            storage.set(newValue, forKey: "installedDate")
        }
    }
    
    var lastInstalledVersion: Version {
        get {
            return Version(fromString: storage.string(forKey: "lastInstalledVersion")!)!
        }
        
        set {
            storage.set(newValue.toString(), forKey: "lastInstalledVersion")
        }
    }
    
}
