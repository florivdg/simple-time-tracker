//
//  MainWindowController.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa
import XCGLogger
import RealmSwift

class MainWindowController: NSWindowController {
    
    @IBOutlet weak var timesheetPopupButton: NSPopUpButton!
    let log = XCGLogger.default
    var timesheets: Results<Timesheet>?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            appDelegate.mainWindowController = self
        }
        
        window?.titleVisibility = .hidden
        
        let realm = try! Realm()
        timesheets = realm.objects(Timesheet.self).sorted(byKeyPath: "title", ascending: true)
        
        configureTimesheetSelector()

    }
    
    func configureTimesheetSelector() {
        
        timesheetPopupButton.removeAllItems()
        
        timesheetPopupButton.addItem(withTitle: NSLocalizedString("Timesheets...", comment: "First placeholder item title in timesheet selector"))

        if let timesheets = timesheets {
            for sheet in timesheets {
                timesheetPopupButton.addItem(withTitle: sheet.title)
            }
        }
        
        timesheetPopupButton.sizeToFit()
        
    }
    
    @IBAction func timesheetSelected(_ sender: NSPopUpButton) {
        
        log.verbose("Will select sheet '\(sender.selectedItem!.title)'")
        
    }
    
    @IBAction func addTimesheet(_ sender: NSSegmentedControl) {
        
    }
}

