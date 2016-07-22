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
    
    private var currentVersion: Configuration.Version?

    @available(OSX 10.10, *)
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.awakeFromNib()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        installedPatch.stringValue = "Installed Patch: \(Configuration.instance.installedVersion.toString())"
        checkInstalledFiles()
        //Get the current version from the server
        Util.downloadString("http://www.lol-item-sets-generator.org/?version") { (data, res, err) in
            if err != nil {
                //TODO check this and also a bad response error
            } else {
                self.currentPatch.stringValue = "Current Patch: \(data!)"
                let fetchedVersion = Configuration.Version(fromString: data!)
                self.currentVersion = fetchedVersion
                //If version mismatch the installed, then there's an update
                if fetchedVersion.compare(Configuration.instance.installedVersion) != 0 {
                    self.installSets.enabled = true
                }
            }
        }
        
        let attrStr = NSMutableAttributedString(string: "Go to the website")
        attrStr.beginEditing()
        attrStr.addAttribute(NSLinkAttributeName, value: NSURL(string: "https://lol-item-sets-generator.org/")!, range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSForegroundColorAttributeName, value: NSColor.blueColor(), range: NSMakeRange(0, 17))
        attrStr.addAttribute(NSUnderlineStyleAttributeName, value: NSNumber(int: 1), range: NSMakeRange(0, 17))
        attrStr.endEditing()
        link_.attributedStringValue = attrStr
        
    }

    override var representedObject: AnyObject? {
        didSet {
            // Update the view, if already loaded.
        }
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
                    
                }
            } else {
                //If the folder doesn't exists, then the folder was deleted
                Configuration.instance.installedVersion = Configuration.Version(major: 0, minor: 0, patch: 0)
                installedPatch.stringValue = "Installed Patch: 0.0.0"
            }
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
        
        //Check if the selected .app "file" (it's a folder) is LoL, and can be read a written
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
        //Download the zip file
        Util.downloadUrl(NSURL(string: "http://www.lol-item-sets-generator.org/clicks/click.php?id=dl_sets_from_application")!) { (data, res, err) in
            if err != nil {
                //TODO check this and also a bad response error
                print("[installItemSets:85] \(err!)")
            } else {
                do {
                    try data!.writeToURL(tempFile!.1, options: NSDataWritingOptions(rawValue: 0))
                    //UNZIP IT
                    let lolPath = self.pathControl.URL?.URLByAppendingPathComponent("Contents/LoL/Config", isDirectory: true)
                    try Zip.unzipFile(tempFile!.1, destination: lolPath!, overwrite: true, password: nil, progress: { (progress) in
                        //TODO
                    })
                    Configuration.instance.installedVersion = self.currentVersion!
                    self.installedPatch.stringValue = "Installed Patch: \(Configuration.instance.installedVersion.toString())"
                    self.installSets.enabled = false
                } catch(let e) {
                    print("[installItemSets:96] \(e)") //TODO
                }
            }
            
            tempFile?.0.closeFile()
        }
    }

}

