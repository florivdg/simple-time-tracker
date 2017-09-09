//
//  AppDelegate.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa
import XCGLogger

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let log = XCGLogger.default
    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        log.setup(level: .error, showThreadName: true, showLevel: false, showFileNames: true, showLineNumbers: true)
        
        if Task.runningTask() != nil {
            NSApp.dockTile.badgeLabel = " "
        }
        
    }
    
    @IBAction func stayInFront(_ sender: NSMenuItem) {
        
        guard let window = mainWindowController?.window else { return }
        
        window.level = NSWindow.Level(rawValue: ( window.level.rawValue == Int(CGWindowLevelForKey(.floatingWindow)) ) ? Int(CGWindowLevelForKey(.normalWindow)) : Int(CGWindowLevelForKey(.floatingWindow)))
        sender.state = ( sender.state == .on ) ? .off : .on
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController?.window?.makeKeyAndOrderFront(self)
        return false
    }
    
    @IBAction func showMainWindow(_ sender: Any) {
        mainWindowController?.window?.makeKeyAndOrderFront(sender)
    }

}

