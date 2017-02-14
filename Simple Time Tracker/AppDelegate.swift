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
        
        let devLogPath = "/Users/flori/Desktop/stt_dev.log"
        log.setup(level: .debug, showThreadName: true, showLevel: false, showFileNames: true, showLineNumbers: true, writeToFile: devLogPath, fileLevel: .verbose)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        mainWindowController?.window?.makeKeyAndOrderFront(self)
        return false
    }


}

