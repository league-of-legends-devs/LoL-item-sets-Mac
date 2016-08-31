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
    
    private var currentVersion: Configuration.Version?
    private var timer: NSTimer?
    private var awakeFromNibExecuted = false
    private let webBase = "https://lol-item-sets-generator.org"

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
        attrStr.addAttribute(NSLinkAttributeName, value: NSURL(string: "\(webBase)/")!, range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blueColor(), range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(int: 1), range: NSMakeRange(0, 17))
        attrStr.endEditing()
        link_.attributedStringValue = attrStr
        
        timer = NSTimer(timeInterval: 60 * 60, target: self, selector: #selector(ViewController.timerFires), userInfo: self, repeats: true)
        autoCheck.integerValue = Configuration.instance.autoCheck ? 1 : 0
        
        if let date = Configuration.instance.installedDate {
            installedLabel.stringValue = "Installed \(date.dateStr)"
        } else {
            installedLabel.hidden = true
        }
    }

    override var representedObject: AnyObject? {
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
    
    private func checkInstalledFiles() {
        if Configuration.instance.installedVersion.toString() != "0.0.0" {
            //If we know there's something installed, then we check if the
            //item sets are in the same version that we have installed before
            let path = pathControl.URL!.path!
            if Util.exists("\(path)/Contents/LoL/Config/ItemSets") {
                do {
                    let files = try NSFileManager.defaultManager().contentsOfDirectoryAtPath("\(path)/Contents/LoL/Config/ItemSets/Aatrox/Recommended")
                    let splitted = files[0].componentsSeparatedByString(" ")
                    let versionDetected = Configuration.Version(fromString: splitted[0])
                    if versionDetected.compare(Configuration.instance.installedVersion) != 0 {
                        let p = Util.showDialog("Installed versions mismatch", text: "You have installed another version of the items " +
                            " that mismatch the installed with the app. Is that version correct? \(splitted[0])" +
                            ".\nIf it not, then the app will overwrite the contents of the item sets with the current", buttons: ["Yes", "No"], icon: NSAlertStyle.WarningAlertStyle)
                        if p == 2 {
                            installItemSets(installSets)
                        }
                    }
                } catch {
                    Util.showDialog("Error when reading", text: "Could not read LoL contents. Check if you have permissions to read the app.");
                }
            } else {
                //If the folder doesn't exists, then the folder was deleted
                Configuration.instance.installedVersion = Configuration.Version(major: 0, minor: 0, patch: 0)
                installedPatch.stringValue = "Installed Patch: 0.0.0"
            }
        }
    }
    
    private func checkServerVersion() {
        Util.downloadString("\(webBase)/api/patch") { (data, res, err) in
            if err != nil {
                Util.showDialog("Error getting latest version", text: "There was an internal error while we were getting"
                    + " the latest version.\n\(err!.description)")
            } else if(res!.statusCode / 100 >= 4) {
                Util.showDialog("Error getting latest version", text: "The server responded with an error when we were "
                    + "getting the latest version")
            } else {
                //Deserialize JSON
                let obj = Util.fromJSON(data!)
                if obj != nil && obj!["version"] != nil {
                    let versionStr = obj!["version"]! as! String
                    self.currentPatch.stringValue = "Current Patch: \(versionStr)"
                    let fetchedVersion = Configuration.Version(fromString: versionStr)
                    self.currentVersion = fetchedVersion

                    //If version mismatch the installed, then there's an update
                    if fetchedVersion.compare(Configuration.instance.installedVersion) != 0 {
                        self.installSets.enabled = true
                        NSApplication.sharedApplication().dockTile.showsApplicationBadge = true
                        NSApplication.sharedApplication().dockTile.badgeLabel = "New Set"
                    }
                    
                    //Generation date
                    let genDate = Util.fromJSONDate(obj!["generationDate"]! as! String)
                    self.generatedLabel.stringValue = "Generated \(genDate!.dateStr)"
                } else {
                    Util.showDialog("Error getting latest version", text: "The server responded with an invalid data")
                }
            }
        }
    }
    
    private func getNews() {
        Util.downloadString("\(webBase)/api/news") { (data, res, err) in
            if err != nil {
                Util.showDialog("Cannot retrieve news", text: "There was an internal error while we were getting that news")
            } else if(res!.statusCode / 100 >= 4) {
                Util.showDialog("Cannot retrieve news", text: "The server responded with an error while we were getting the news")
            } else {
                //Deserialize JSON
                let obj = Util.fromJSON(data!)
                if obj != nil && obj!["text"] != nil {
                    let text = obj!["text"]! as! String
                    if text != "" {
                        self.newsText.stringValue = text
                        self.newsText.hidden = false
                    } else {
                        self.newsText.hidden = true
                    }
                } else {
                    self.newsText.hidden = true
                }
            }
        }
    }
    
    private func deleteOldItems(version: Configuration.Version) {
        do {
            print("Removing old items")
            let path = pathControl.URL!.path!
            let verStr = version.toString()
            let champs = try NSFileManager.defaultManager().contentsOfDirectoryAtPath("\(path)/Contents/LoL/Config/ItemSets/");
            for champ in champs {
                let items = try NSFileManager.defaultManager().contentsOfDirectoryAtPath("\(path)/Contents/LoL/Config/ItemSets/\(champ)/Recommended/")
                for item in items {
                    if !item.containsString(verStr) {
                        _ = try? NSFileManager.defaultManager().removeItemAtPath("\(path)/Contents/LoL/Config/ItemSets/\(champ)/Recommended/\(item)")
                        print("Removed \(path)/Contents/LoL/Config/ItemSets/\(champ)/Recommended/\(item)")
                    }
                }
            }
        } catch {
            Util.showDialog("Error when removing", text: "Could not remove old items. Check if you have permissions to read and write the app.");
        }
    }

    @IBAction func changeLolPath(sender: AnyObject) {
        let fileDialog = NSOpenPanel()
        fileDialog.prompt = "Select League of Legends app"
        fileDialog.allowsMultipleSelection = false
        fileDialog.canChooseFiles = true
        fileDialog.canChooseDirectories = false
        fileDialog.allowedFileTypes = ["app"]
        fileDialog.runModal()
        
        //Check if the selected .app "file" (it's a folder) is LoL, and can be read and written
        let url = fileDialog.URL
        if url != nil {
            let path = fileDialog.URL!.path!
            if Util.canBeRead(path) {
                if Util.exists("\(path)/Contents/LoL/Config") {
                    if Util.canBeRead("\(path)/Contents/LoL/Config") && Util.canBeWritten("\(path)/Contents/LoL/Config") {
                        pathControl.URL = url
                    } else {
                        Util.showDialog("League Of Legends contents cannot be written", text: "We need (and also you) write permissions to the LoL contents to write" +
                            " inside and put the builds for you", buttons: ["Ok"])
                    }
                } else {
                    if Util.showDialog("App is not League Of Legends", text: "The app seems not to be League of Legends. Select another app") == 1 {
                        changeLolPath(sender)
                    }
                }
            } else {
                Util.showDialog("App is not readable", text: "The app content's cannot be read nor write", buttons: ["Ok"])
            }
        }
    }

    @IBAction func installItemSets(sender: NSButton) {
        //Create a temporary file to store the zip file
        let tempFile = Util.createTempFile("items.zip")
        spinIndicator.startAnimation(self)
        self.installSets.enabled = false
        //Download the zip file
        Util.downloadUrl(NSURL(string: "\(webBase)/downloads/sets-from-app")!) { (data, res, err) in
            if err != nil {
                Util.showDialog("Error getting items", text: "There was an internal error while we were getting"
                    + " the items.\n\(err!.description)")
                print("[installItemSets:85] \(err!)")
                self.installSets.enabled = true
            } else if res!.statusCode / 100 >= 4 {
                Util.showDialog("Error getting latest version", text: "The server responded with an error while "
                    + "we were getting the items.");
                self.installSets.enabled = true
            } else {
                do {
                    try data!.writeToURL(tempFile!.1, options: NSDataWritingOptions(rawValue: 0))
                    //UNZIP IT
                    let lolPath = self.pathControl.URL?.URLByAppendingPathComponent("Contents/LoL/Config", isDirectory: true)
                    try Zip.unzipFile(tempFile!.1, destination: lolPath!, overwrite: true, password: nil, progress: { (progress) in
                        //TODO
                    })
                    NSApplication.sharedApplication().dockTile.showsApplicationBadge = false
                    Configuration.instance.installedVersion = self.currentVersion!
                    self.installedPatch.stringValue = "Installed Patch: \(Configuration.instance.installedVersion.toString())"
                    self.deleteOldItems(self.currentVersion!)

                    Configuration.instance.installedDate = NSDate()
                    self.installedLabel.stringValue = "Installed \(NSDate().dateStr)"
                    self.installedLabel.hidden = false
                } catch(let e) {
                    Util.showDialog("Error getting items", text: "There was an internal error while we were erxtracting"
                        + " the items.\n\(e)")
                    print("[installItemSets:96] \(e)")
                    self.installSets.enabled = true
                }
            }
            
            tempFile?.0.closeFile()
            self.spinIndicator.stopAnimation(self)
        }
    }

    @IBAction func autoCheckChanged(sender: NSButton) {
        Configuration.instance.autoCheck = sender.integerValue == 1 ? true : false
    }
}

