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
        
        let sheet = Task.runningTask()?.timesheet ?? timesheets?.first
        if sheet != nil {
            loadTimesheet(sheet!, showSelection: true)
        }
        
    }
    
    func configureTimesheetSelector() {
        
        timesheetPopupButton.removeAllItems()
        
        if let timesheets = timesheets {
            for sheet in timesheets {
                let sheetTitle = (sheet.isRunning) ? "∙ \(sheet.title)" : sheet.title
                timesheetPopupButton.addItem(withTitle: sheetTitle)
            }
        }
        
        if timesheetPopupButton.itemArray.count == 0 {
            timesheetPopupButton.addItem(withTitle: NSLocalizedString("Nothing yet...", comment: "First placeholder item title in timesheet selector"))
        }
        
    }
    
    @IBAction func timesheetSelected(_ sender: NSPopUpButton) {
        
        guard timesheets?.count != 0 else { return }
        
        log.verbose("Will select sheet '\(sender.selectedItem!.title)'")
        
        if let item = sender.selectedItem {
            if let sheetIndex = sender.itemArray.index(of: item) {
                if let sheet = timesheets?[sheetIndex] {
                    loadTimesheet(sheet)
                }
            }
            
        }
        
    }
    
    @IBAction func addTimesheet(_ sender: NSSegmentedControl) {
        
        log.verbose("Will add new timesheet...")
        
        displayTimesheetTitleModal()
        
    }
    
    func displayTimesheetTitleModal() {
        
        let a = NSAlert()
        a.messageText = NSLocalizedString("Please enter a title for the timesheet", comment: "Modal title")
        a.addButton(withTitle: NSLocalizedString("Create", comment: "Modal action create"))
        a.addButton(withTitle: NSLocalizedString("Cancel", comment: "Modal action cancel"))
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = NSLocalizedString("Title...", comment: "Timesheet title placeholder in text field")
        a.accessoryView = inputTextField
        
        a.beginSheetModal(for: self.window!, completionHandler: { [weak self] modalResponse in
            if modalResponse == NSAlertFirstButtonReturn {
                let enteredString = inputTextField.stringValue
                if enteredString.characters.count != 0 {
                    
                    let sheet = Timesheet.addTimesheet(withTitle: enteredString)
                    self?.configureTimesheetSelector()
                    
                    self?.loadTimesheet(sheet, showSelection: true)
                    
                }
            }
        })
        
        inputTextField.becomeFirstResponder()
        
    }
    
    func loadTimesheet(_ sheet: Timesheet, showSelection: Bool = false) {
        
        if showSelection == true, let sheetIndex = timesheets?.index(of: sheet) {
            timesheetPopupButton.selectItem(at: sheetIndex)
        }
        
        /* Load it */
        
        guard let sheetVC = self.contentViewController as? TimesheetViewController else { return }
        
        sheetVC.timesheet = sheet
        
    }
}

