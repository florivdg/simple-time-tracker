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

class MainWindowController: NSWindowController, SheetsDelegate {
    
    @IBOutlet weak var timesheetPopupButton: NSPopUpButton!
    let log = XCGLogger.default
    var timesheets: Results<Timesheet>?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let appDelegate = NSApplication.shared().delegate as? AppDelegate {
            appDelegate.mainWindowController = self
        }
        
        window?.titleVisibility = .hidden
        
        /* Become delegate */
        if let sheetVC = self.contentViewController as? TimesheetViewController {
            sheetVC.sheetsDelegate = self
        }
        
        performRealmMigrations()
        
        refreshSheetsList(byReloading: true)
        
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
        a.messageText = NSLocalizedString("Please enter a title", comment: "Modal title")
        a.addButton(withTitle: NSLocalizedString("Create", comment: "Modal action create"))
        a.addButton(withTitle: NSLocalizedString("Cancel", comment: "Modal action cancel"))
        
        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = NSLocalizedString("Title of timesheet...", comment: "Timesheet title placeholder in text field")
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
        
        if showSelection == true {
            select(sheet)
        }
        
        /* Load it */
        
        guard let sheetVC = self.contentViewController as? TimesheetViewController else { return }
        
        sheetVC.timesheet = sheet
        
        UserDefaults.standard.set(sheet.title, forKey: Constant.userDefaultsLastTimesheetName)
        
    }
    
    func select(_ sheet: Timesheet) {
        
        if let sheetIndex = timesheets?.index(of: sheet) {
            timesheetPopupButton.selectItem(at: sheetIndex)
        }
        
    }
    
    func refreshSheetsList(byReloading reloading: Bool) {
        
        let realm = try! Realm()
        timesheets = realm.objects(Timesheet.self).sorted(byKeyPath: "title", ascending: true)
        
        configureTimesheetSelector()
        
        /* Active sheet */
        var lastUsedSheet: Timesheet? = nil
        if let lastUsedTitle = UserDefaults.standard.string(forKey: Constant.userDefaultsLastTimesheetName) {
            lastUsedSheet = timesheets?.filter("title = %@", lastUsedTitle).first
        }
        let sheet = Task.runningTask()?.timesheet ?? lastUsedSheet ?? timesheets?.first
        
        if let sheet = sheet {
            if reloading {
                loadTimesheet(sheet, showSelection: true)
            } else {
                select(sheet)
            }
        }
        
    }
    
    
    /* Realm migrations */
    
    func performRealmMigrations() {
        
        let config = Realm.Configuration(
            schemaVersion: 1,
            
            migrationBlock: { migration, oldSchemaVersion in
                
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        Realm.Configuration.defaultConfiguration = config
        
    }
    
}

