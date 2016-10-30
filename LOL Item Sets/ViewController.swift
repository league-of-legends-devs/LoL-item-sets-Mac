//
//  ViewController.swift
//  LOL Item Sets
//
//  Created by Melchor Garau Madrigal on 21/7/16.
//  Copyright © 2016 melchor629. All rights reserved.
//

import Cocoa
import Zip

class ViewController: NSViewController {
    @IBOutlet var currentPatch: NSTextField!
    @IBOutlet var installedPatch: NSTextField!
    @IBOutlet var pathControl: NSPathControl!
    @IBOutlet var installSets: NSButton!
    @IBOutlet var link_: NSTextField!
    @IBOutlet var spinIndicator: NSProgressIndicator!
    @IBOutlet var autoCheck: NSButton!
    @IBOutlet var newsText: NSTextField!
    @IBOutlet var generatedLabel: NSTextField!
    @IBOutlet var installedLabel: NSTextField!
    
    fileprivate var currentVersion: Configuration.Version?
    fileprivate var timer: Timer?
    fileprivate var awakeFromNibExecuted = false
    fileprivate let webBase = "https://lol-item-sets-generator.org"
    fileprivate let itemsPathBase = "Contents/LoL/Config/Champions"

    @available(OSX 10.10, *)
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if awakeFromNibExecuted {
            return
        }
        
        awakeFromNibExecuted = true
        installedPatch.stringValue = "Installed Patch: \(Configuration.instance.installedVersion.toString())"
        checkInstalledFiles()
        //Get the current version from the server
        checkServerVersion()
        //Get news and show it if there is
        getNews()
        
        let attrStr = NSMutableAttributedString(string: "Go to the website")
        attrStr.beginEditing()
        attrStr.addAttribute(NSLinkAttributeName, value: URL(string: "\(webBase)/")!, range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blue, range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(value: 1 as Int32), range: NSMakeRange(0, 17))
        attrStr.endEditing()
        link_.attributedStringValue = attrStr
        
        timer = Timer(timeInterval: 60 * 60, target: self, selector: #selector(ViewController.timerFires), userInfo: self, repeats: true)
        autoCheck.integerValue = Configuration.instance.autoCheck ? 1 : 0
        
        if let date = Configuration.instance.installedDate {
            installedLabel.stringValue = "Installed \(date.dateStr)"
        } else {
            installedLabel.isHidden = true
        }
        
        if #available(OSX 10.10, *) {} else {
            (NSApplication.shared().delegate as! AppDelegate).mainViewController = self
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func timerFires() {
        if autoCheck.integerValue == 1 {
            checkServerVersion();
        }
        getNews()
    }
    
    func deleteInstalledFiles() {
        Configuration.instance.lastInstalledVersion = Configuration.instance.installedVersion
        deleteOldItems(Configuration.instance.installedVersion)
        Configuration.instance.installedDate = nil
        Configuration.instance.installedVersion = Configuration.Version(major: 0, minor: 0, patch: 0)
        installedPatch.stringValue = "Installed Patch: 0.0.0"
        installSets.isEnabled = true
        Util.showDialog("Item sets", text: "Installed items sets have been deleted", buttons: ["Ok"], icon: .informational)
    }
    
    fileprivate func checkInstalledFiles() {
        let path = pathControl.url!.path
        if Configuration.instance.installedVersion.toString() != "0.0.0" {
            //If we know there's something installed, then we check if the
            //item sets are in the same version that we have installed before
            if Util.exists("\(path)/\(itemsPathBase)") && Util.exists("\(path)/\(itemsPathBase)/Aatrox/Recommended/") {
                do {
                    let files = try FileManager.default.contentsOfDirectory(atPath: "\(path)/\(itemsPathBase)/Aatrox/Recommended")
                    for file in files {
                        let splitted = file.components(separatedBy: " ")
                        let versionDetected = Configuration.Version(fromString: splitted[0])
                        if versionDetected != nil && versionDetected!.compare(Configuration.instance.installedVersion) != 0 {
                            let p = Util.showDialog(withOptions: "Installed versions mismatch", text: "You have installed another version of the items " +
                                " that mismatch the installed with the app. Is that version correct? \(splitted[0])" +
                                ".\nIf it not, then the app will overwrite the contents of the item sets with the current", buttons: ["Yes", "No"], icon: NSAlertStyle.warning)
                            if p == 2 {
                                Configuration.instance.installedVersion = Configuration.Version(fromString: splitted[0])!
                                installItemSets(installSets)
                            }
                            return
                        } else if versionDetected != nil && versionDetected!.compare(Configuration.instance.installedVersion) == 0 {
                            return
                        }
                    }
                } catch {
                    Util.showDialog("Error when reading", text: "Could not read LoL contents. Check if you have permissions to read the game.", buttons: ["Ok"]);
                }
            }

            //Path of item sets doesn't exist, or we couldn't found files for the item sets
            Configuration.instance.installedVersion = Configuration.Version(major: 0, minor: 0, patch: 0)
            installedPatch.stringValue = "Installed Patch: 0.0.0"
            installedLabel.isHidden = true
            Configuration.instance.installedDate = nil
        }

        if Util.exists("\(path)/\(itemsPathBase)") && (!Util.canBeRead("\(path)/\(itemsPathBase)") || !Util.canBeWritten("\(path)/\(itemsPathBase)")) {
            let p = Util.showDialog(withOptions: "Ensure permissions", text: "Could not read or write LoL Champions item sets. Check for permissions", buttons: ["Ok", "See more"])
            if p == 2 {
                NSWorkspace.shared().open(URL(string: "https://github.com/Ilshidur/LoL-item-sets-Mac/wiki/Fix-permissions-in-the-Item-Sets-folders-of-the-League-of-Legends-game")!)
            }
        }
    }
    
    fileprivate func checkServerVersion() {
        Util.downloadString("\(webBase)/api/patch") { (data, res, err) in
            if err != nil {
                let e = (err as? URLError);
                Util.showDialog("Error getting latest version", text: "There was an internal error while we were getting"
                    + " the latest version.\n\(e!.localizedDescription)", buttons: ["Ok"])
            } else if(res!.statusCode / 100 >= 4) {
                Util.showDialog("Error getting latest version", text: "The server responded with an error when we were "
                    + "getting the latest version", buttons: ["Ok"])
            } else {
                //Deserialize JSON
                let obj = Util.fromJSON(data!)
                if obj != nil && obj!["version"] != nil {
                    let versionStr = obj!["version"]! as! String
                    self.currentPatch.stringValue = "Current Patch: \(versionStr)"
                    let fetchedVersion = Configuration.Version(fromString: versionStr)
                    self.currentVersion = fetchedVersion

                    //If version mismatch the installed, then there's an update
                    if fetchedVersion?.compare(Configuration.instance.installedVersion) != 0 {
                        self.installSets.isEnabled = true
                        NSApplication.shared().dockTile.showsApplicationBadge = true
                        NSApplication.shared().dockTile.badgeLabel = "New Set"
                    } else if fetchedVersion == nil {
                        Util.showDialog("Error getting latest version", text: "The server responded with invalid information", buttons: ["Ok"])
                    }
                    
                    //Generation date
                    let genDate = Util.fromJSONDate(obj!["generationDate"]! as! String)
                    self.generatedLabel.stringValue = "Generated \(genDate!.dateStr)"
                } else {
                    Util.showDialog("Error getting latest version", text: "The server responded with an invalid data", buttons: ["Ok"])
                }
            }
        }
    }
    
    fileprivate func getNews() {
        Util.downloadString("\(webBase)/api/news") { (data, res, err) in
            if err != nil {
                let e = (err as? URLError);
                Util.showDialog("Cannot retrieve news", text: "There was an internal error while we were getting that news\n\(e!.localizedDescription)", buttons: ["Ok"])
            } else if(res!.statusCode / 100 >= 4) {
                Util.showDialog("Cannot retrieve news", text: "The server responded with an error while we were getting the news", buttons: ["Ok"])
            } else {
                //Deserialize JSON
                let obj = Util.fromJSON(data!)
                if obj != nil && obj!["text"] != nil {
                    let text = obj!["text"]! as! String
                    if text != "" {
                        self.newsText.stringValue = text
                        self.newsText.isHidden = false
                    } else {
                        self.newsText.isHidden = true
                    }
                } else {
                    self.newsText.isHidden = true
                }
            }
        }
    }
    
    fileprivate func deleteOldItems(_ version: Configuration.Version) {
        do {
            print("Removing old items, version \(version.toString())")
            let path = pathControl.url!.path
            let verStr = version.toString()
            let champs = try FileManager.default.contentsOfDirectory(atPath: "\(path)/\(itemsPathBase)/")
            for champ in champs {
                if champ != "ItemSets" {
                    let items = try FileManager.default.contentsOfDirectory(atPath: "\(path)/\(itemsPathBase)/\(champ)/Recommended/")
                    for item in items {
                        if item.contains(verStr) {
                            _ = try? FileManager.default.removeItem(atPath: "\(path)/\(itemsPathBase)/\(champ)/Recommended/\(item)")
                            print("Removed \(path)/\(itemsPathBase)/\(champ)/Recommended/\(item)")
                        }
                    }
                }
            }
        } catch {
            Util.showDialog("Error when removing", text: "Could not remove old items. Check if you have permissions to read and write the app.", buttons: ["Ok"]);
        }
    }

    @IBAction func changeLolPath(_ sender: AnyObject) {
        let fileDialog = NSOpenPanel()
        fileDialog.prompt = "Select League of Legends app"
        fileDialog.allowsMultipleSelection = false
        fileDialog.canChooseFiles = true
        fileDialog.canChooseDirectories = false
        fileDialog.allowedFileTypes = ["app"]
        fileDialog.runModal()
        
        //Check if the selected .app "file" (it's a folder) is LoL, and can be read and written
        let url = fileDialog.url
        if url != nil {
            let path = fileDialog.url!.path
            if Util.canBeRead(path) {
                if Util.exists("\(path)/\(itemsPathBase)/../") {
                    if Util.canBeRead("\(path)/\(itemsPathBase)/../") && Util.canBeWritten("\(path)/\(itemsPathBase)/../") {
                        pathControl.url = url
                    } else {
                        Util.showDialog("League Of Legends contents cannot be written", text: "We need (and also you) write permissions to the LoL contents to write" +
                            " inside and put the builds for you", buttons: ["Ok"])
                    }
                } else {
                    if Util.showDialog(withOptions: "App is not League Of Legends", text: "The app seems not to be League of Legends. Select another app") == 1 {
                        changeLolPath(sender)
                    }
                }
            } else {
                Util.showDialog("App is not readable", text: "The app content's cannot be read nor write", buttons: ["Ok"])
            }
        }
    }

    @IBAction func installItemSets(_ sender: NSButton) {
        //Create a temporary file to store the zip file
        let tempFile = Util.createTempFile("items.zip")
        spinIndicator.startAnimation(self)
        self.installSets.isEnabled = false
        //Download the zip file
        Util.downloadUrl(URL(string: "\(webBase)/downloads/sets-from-app")!) { (data, res, err) in
            if err != nil {
                let e = (err as? URLError);
                Util.showDialog("Error getting items", text: "There was an internal error while we were getting"
                    + " the items.\n\(e!.localizedDescription)", buttons: ["Ok"])
                self.installSets.isEnabled = true
            } else if res!.statusCode / 100 >= 4 {
                Util.showDialog("Error getting latest version", text: "The server responded with an error while "
                    + "we were getting the items.", buttons: ["Ok"]);
                self.installSets.isEnabled = true
            } else {
                do {
                    try data!.write(to: tempFile!.1, options: NSData.WritingOptions(rawValue: 0))
                    //UNZIP IT
                    let lolPath = self.pathControl.url?.appendingPathComponent(self.itemsPathBase, isDirectory: true)
                    try Zip.unzipFile(tempFile!.1, destination: lolPath!, overwrite: true, password: nil, progress: { (progress) in
                        //TODO
                    })
                    
                    var hadErrors = false //moving files
                    //Move items to its correct place
                    //Permissions are set to octal 0777 (aka u+rwx g+rwx a+rwx) in hex 0x1FF
                    do {
                        let fs = FileManager.default
                        let path = self.pathControl.url!.path
                        let champs = try FileManager.default.contentsOfDirectory(atPath: "\(path)/\(self.itemsPathBase)/ItemSets/")
                        for champ in champs {
                            let origin = "\(path)/\(self.itemsPathBase)/ItemSets/\(champ)/Recommended"
                            let destination = "\(path)/\(self.itemsPathBase)/\(champ)/Recommended"
                            let files = try FileManager.default.contentsOfDirectory(atPath: "\(origin)")

                            if !Util.exists(destination) {
                                //If the destination folder (or any intermediate) doesn't exist, we need to create it
                                try FileManager.default.createDirectory(atPath: destination, withIntermediateDirectories: true, attributes: [FileAttributeKey.posixPermissions.rawValue: 0x1FF])
                                print("Created directory \(destination)")
                            } else {
                                //Ensure that the destination folders has the correct permissions
                                do {
                                    try fs.setAttributes([FileAttributeKey.posixPermissions: 0x1FF], ofItemAtPath: "\(path)/\(self.itemsPathBase)/\(champ)")
                                    try fs.setAttributes([FileAttributeKey.posixPermissions: 0x1FF], ofItemAtPath: destination)
                                } catch let e {
                                    print("Could not set permissions for folder \(destination), this could lead into an error")
                                    print(e)
                                }
                            }

                            for file in files {
                                do {
                                    //Movement is done file by file, to avoid deleting other files in the destination folder
                                    //or at least try it
                                    try fs.moveItem(atPath: "\(origin)/\(file)", toPath: "\(destination)/\(file)")
                                    print("Moved '\(origin)/\(file)' to '\(destination)/\(file)'")
                                    try fs.setAttributes([FileAttributeKey.posixPermissions: 0x1FF], ofItemAtPath: "\(destination)/\(file)")
                                } catch let e {
                                    print("Could not move '\(origin)/\(file)' to '\(destination)/\(file)'")
                                    print(e)
                                    hadErrors = true
                                }
                            }
                        }
                        
                        //Here we remove the temporary folder, to avoid problems with LoL game
                        try FileManager.default.removeItem(atPath: "\(path)/\(self.itemsPathBase)/ItemSets/")
                        print("Deleted temporary folder \(path)/\(self.itemsPathBase)/ItemSets/")
                    } catch {
                        print("this shouldn't have occurred, we checked permissions")
                    }

                    NSApplication.shared().dockTile.showsApplicationBadge = false
                    Configuration.instance.lastInstalledVersion = Configuration.instance.installedVersion
                    Configuration.instance.installedVersion = self.currentVersion!
                    self.installedPatch.stringValue = "Installed Patch: \(Configuration.instance.installedVersion.toString())"
                    self.deleteOldItems(Configuration.instance.lastInstalledVersion)

                    Configuration.instance.installedDate = Date()
                    self.installedLabel.stringValue = "Installed \(Date().dateStr)"
                    self.installedLabel.isHidden = false
                    
                    if hadErrors {
                        let p = Util.showDialog(withOptions: "Installing item sets had errors", text: "When installing the item sets, we found some" +
                            " errors, probably due to invalid permissions. Check the permissions on \"\(self.pathControl.url!.path)" +
                            "/\(self.itemsPathBase)\" and its subfolders, delete all items installed using the app's menu option " +
                            "and reinstall the sets.\nSee https://github.com/Ilshidur/LoL-item-sets-Mac/wiki/Fix-permissions-in-" +
                            "the-Item-Sets-folders-of-the-League-of-Legends-game for more help.", buttons: ["Ok", "See more"])
                        if p == 2 {
                            NSWorkspace.shared().open(URL(string: "https://github.com/Ilshidur/LoL-item-sets-Mac/wiki/Fix-permissions-in-the-Item-Sets-folders-of-the-League-of-Legends-game")!)
                        }
                    }
                } catch(let e) {
                    Util.showDialog("Error getting items", text: "There was an internal error while we were extracting"
                        + " the items.\n\(e)", buttons: ["Ok"])
                    print("[installItemSets:96] \(e)")
                    self.installSets.isEnabled = true
                }
            }
            
            tempFile?.0.closeFile()
            self.spinIndicator.stopAnimation(self)
        }
    }

    @IBAction func autoCheckChanged(_ sender: NSButton) {
        Configuration.instance.autoCheck = sender.integerValue == 1 ? true : false
    }
}

