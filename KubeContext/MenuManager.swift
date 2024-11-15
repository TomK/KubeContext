//
//  MenuManager.swift
//  KubeContext
//
//  Created by Turken, Hasan on 12.10.18.
//  Copyright © 2018 Turken, Hasan. All rights reserved.
//

import Foundation
import Cocoa

class MenuManager: NSObject, NSMenuDelegate {
    var manageController: NSWindowController?
    
    override init() {
        super.init()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        if k8s.kubeconfig == nil {
            ConstructInitMenu(menu: menu)
        } else {
            ConstructMainMenu(menu: menu)
        }
    }
    
    @objc func toggleState(_ sender: NSMenuItem) {
        let ctxMenu = sender.menu!.items
        for ctxM in ctxMenu {
            if ctxM != sender {
                ctxM.state = NSControl.StateValue.off
            }
        }
        if sender.state == NSControl.StateValue.off {
            sender.state = NSControl.StateValue.on
            do {
                try k8s.useContext(name: sender.title)
            } catch {
                NSLog ("Could not switch context: \(error)")
            }
        }
    }
    
    @objc func logClick(_ sender: NSMenuItem) {
        NSLog("Clicked on " + sender.title)
    }
    
    @objc func openManagement(_ sender: NSMenuItem) {
        if (manageController == nil) {
            let storyboard = NSStoryboard(name: NSStoryboard.Name("Manage"), bundle: nil)
            manageController = storyboard.instantiateInitialController() as? NSWindowController
        }
        
        if (manageController != nil) {
            manageController!.showWindow(sender)
            manageController!.window?.orderFrontRegardless()
        }
    }
    
    @objc func importConfig(_ sender: NSMenuItem) {
        NSLog("will import file...")
        if k8s == nil {
            alertUserWithWarning(message: "Not able to import config file, kubernetes not initialized!")
            return
        }
        var configToImportFileUrl: URL?
        if testFileToImport == nil {
            configToImportFileUrl = openFolderSelection()
        } else {
            configToImportFileUrl = testFileToImport
        }
        if configToImportFileUrl == nil {
            return
        }
        do {
            try k8s.importConfig(configToImportFileUrl: configToImportFileUrl!)
        } catch {
            alertUserWithWarning(message: "Not able to import config file \(error)")
        }
    }
    
    @objc func selectKubeconfig(_ sender: NSMenuItem) {
        do {
            try selectKubeconfigFile()
        } catch {
            alertUserWithWarning(message: "Could not parse selected kubeconfig file\n \(error)")
        }
    }
    
    func ConstructInitMenu(menu: NSMenu){
        menu.removeAllItems()
        let selectConfigMenuItem = NSMenuItem(title: "Select kubeconfig file", action:  #selector(selectKubeconfig(_:)), keyEquivalent: "c")
        selectConfigMenuItem.target = self
        menu.addItem(selectConfigMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    func ConstructMainMenu(menu: NSMenu){
        menu.removeAllItems()
        let centerParagraphStyle = NSMutableParagraphStyle.init()
        centerParagraphStyle.alignment = .center
        
        var config: Config!
        do {
            config = try k8s.getConfig()
        } catch {
            NSLog("Could not parse config file \(error)")
            alertUserWithWarning(message: "Could not parse config file \n \(error)")
            return
        }
        
        
        let currentContext = config.CurrentContext
        let ctxs = config.Contexts
        if ctxs.count < 1 {
            let noCtxMenuItem = NSMenuItem(title: "No contexts in config file", action: nil, keyEquivalent: "")
            menu.addItem(noCtxMenuItem)
        }else{
            for ctx in config.Contexts {
                let ctxMenuItem = NSMenuItem(title: ctx.Name, action: #selector(toggleState(_:)), keyEquivalent: "")
                ctxMenuItem.target = self
                if ctx.Name == currentContext {
                    ctxMenuItem.state = .on
                }
                menu.addItem(ctxMenuItem)
            }
        }
        
        // Seperator
        menu.addItem(NSMenuItem.separator())
        
        // Import Kubeconfig file
        var importAction = #selector(importConfig(_:))
        if ctxs.count >= maxNofContexts {
            importAction = #selector(openManagement(_:))
        }
        
        menu.addItem(NSMenuItem.separator())
        let importKubeconfigMenuItem = NSMenuItem(title: "Import Kubeconfig File", action: importAction, keyEquivalent: "i")
        importKubeconfigMenuItem.target = self
        menu.addItem(importKubeconfigMenuItem)
        
        let manageContextMenuItem = NSMenuItem(title: "Manage Contexts", action: #selector(openManagement(_:)), keyEquivalent: "m")
        manageContextMenuItem.target = self
        menu.addItem(manageContextMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }
    
    func alertUserWithWarning(message: String) {
        let alert = NSAlert()
        alert.icon = NSImage.init(named: NSImage.cautionName)
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}


