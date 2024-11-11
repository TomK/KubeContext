//
//  Utils.swift
//  KubeContext
//
//  Created by Turken, Hasan on 07.10.18.
//  Copyright © 2018 Turken, Hasan. All rights reserved.
//

import Foundation
import Cocoa
import os
import Yams

let bookmarks = Bookmarks.restore() ?? Bookmarks(data: [:])

var configPathProperty = "config_path"

func openFolderSelection() -> URL?
{
    let dialog = NSOpenPanel();
    
    //dialog.title                   = "Choose kubeconfig file";
    dialog.message                 = "Choose kubeconfig file";
    dialog.showsResizeIndicator    = true;
    dialog.showsHiddenFiles        = true;
    dialog.canChooseDirectories    = false;
    dialog.canCreateDirectories    = false;
    dialog.allowsMultipleSelection = false;
    
    //let launcherLogPathWithTilde = "~/.kube" as NSString
    //let expandedLauncherLogPath = launcherLogPathWithTilde.expandingTildeInPath
    //dialog.directoryURL = NSURL.fileURL(withPath: expandedLauncherLogPath, isDirectory: true)
    
    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
        let result = dialog.url // Pathname of the file
        
        if (result != nil) {
            let path = result!.path
            NSLog(path)
        }
        return result
    } else {
        // User clicked on "Cancel"
        return nil
    }
}

func getConfigFileUrl() -> URL?
{
    if bookmarks.data.count>0 {
        if let first = bookmarks.data.first {
            return first.key
        }
    }
    return nil
}

func saveFolderSelection() -> URL?
{
    let dialog = NSSavePanel();
    
    dialog.title                   = "Export kubeconfig file";
    dialog.showsResizeIndicator    = true;
    dialog.showsHiddenFiles        = true;
    dialog.canCreateDirectories    = true;
    
    if (dialog.runModal() == NSApplication.ModalResponse.OK) {
        let result = dialog.url // Pathname of the file
        
        if (result != nil) {
            let path = result!.path
            NSLog(path)
        }
        return result
    } else {
        // User clicked on "Cancel"
        return nil
    }
}

func selectKubeconfigFile() throws {
    NSLog("will select kubeconfig file...")
    var kubeconfigFileUrl: URL?
    if testFileAsConfig == nil {
        kubeconfigFileUrl = openFolderSelection()
    } else {
        kubeconfigFileUrl = testFileAsConfig
    }
    if kubeconfigFileUrl == nil {
        NSLog("Error: Could not get selected file!")
        return
    }
    
    // Try to initialize Kubernetes with new kubeconfig file, if possible.
    let _ = try k8s.setKubeconfig(configFile: kubeconfigFileUrl!)
}

extension String {
    enum TruncationPosition {
        case head
        case middle
        case tail
    }
    
    func truncated(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
        guard self.count > limit else { return self }
        
        switch position {
        case .head:
            return leader + self.suffix(limit)
        case .middle:
            let headCharactersCount = Int(ceil(Float(limit - leader.count) / 2.0))
            
            let tailCharactersCount = Int(floor(Float(limit - leader.count) / 2.0))
            
            return "\(self.prefix(headCharactersCount))\(leader)\(self.suffix(tailCharactersCount))"
        case .tail:
            return self.prefix(limit) + leader
        }
    }
    
    func wrapSmart(limit: Int, position: TruncationPosition = .tail, leader: String = "...") -> String {
        guard self.count > limit else { return self }
        
        var newStr = self
        newStr.insert("\n", at: newStr.index(newStr.startIndex, offsetBy: limit))
        
        let regex = try! NSRegularExpression(pattern: "(.{1,24})(\\_+|$)")
        let range = NSRange(self.startIndex..., in: self)
        let results = regex.matches(in: self, options: .anchored, range: range)
            .map { match -> Substring in
                let range = Range(match.range(at: 1), in: self)!
                return self[range]
            }
        
        return results.joined(separator: "\n")
    }
    
    func wrap(limit: Int) -> String {
        guard self.count > limit else { return self }
        
        var newText = String()
        for (index, character) in self.enumerated() {
            if index != 0 && index % limit == 0 {
                newText.append("\n")
            }
            newText.append(String(character))
        }
        
        return newText
    }
}

func saveConfigToFile(config: Config, file:URL?) throws {
    let encoder = YAMLEncoder()
    let configContent = try encoder.encode(config)
    try configContent.write(to: file!, atomically: false, encoding: .utf8)
    
    for ctx in config.Contexts {
        if let c = ctx.IconColor {
            if #available(OSX 10.13, *) {
                UserDefaults.standard.set(c, forKey: keyIconColorPrefix + ctx.Name)
            }
        } else {
            UserDefaults.standard.removeObject(forKey: keyIconColorPrefix + ctx.Name)
        }
    }
}

extension UserDefaults {
    
    @available(OSX 10.13, *)
    func color(forKey key: String) -> NSColor? {
        
        guard let colorData = data(forKey: key) else { return nil }
        
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
        } catch let error {
            print("color error \(error.localizedDescription)")
            return nil
        }
        
    }
    
    @available(OSX 10.13, *)
    func set(_ value: NSColor?, forKey key: String) {
        
        guard let color = value else { return }
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch let error {
            print("error color key data not saved \(error.localizedDescription)")
        }
        
    }
    
}
