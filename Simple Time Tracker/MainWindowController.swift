//
//  MainWindowController.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            appDelegate.mainWindowController = self
        }

    }
    
}

