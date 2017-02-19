//
//  TimesheetViewController.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa
import XCGLogger
import RealmSwift
import Async

class TimesheetViewController: NSViewController {
    
    // MARK: - Outlets
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelTotal: NSTextField!
    @IBOutlet weak var labelCurrent: NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    @IBOutlet weak var btnExport: NSButton!
    @IBOutlet weak var btnDelete: NSButton!
    
    
    // MARK: - Properties
    
    var sheetsDelegate: SheetsDelegate?
    
    let log = XCGLogger.default
    
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    var timesheet: Timesheet? {
        didSet {
            updateUI()
        }
    }
    var currentTask: Task? {
        get {
            return Task.runningTask()
        }
    }
    var updateTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        
    }
    
    
    //  MARK: - User Interface
    
    func updateUI() {
        
        guard let sheet = timesheet else {
            showEmptyUI()
            return
        }
        
        startUIUpdateTimer()
        
        labelTitle.stringValue = sheet.title
        
    }
    
    func showEmptyUI() {
        
        labelTitle.stringValue = "---"
        
    }
    
    func startUIUpdateTimer() {
        
        updateDurationDisplay()
        
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            if self?.currentTask == nil {
                self?.updateTimer?.invalidate()
            } else {
                self?.updateDurationDisplay()
            }
        })
        
    }
    
    func updateDurationDisplay() {
        
        /* Labels */
        
        if let totalDuration = timesheet?.duration {
            labelTotal.stringValue = totalDuration.string
        }
        if currentTask?.timesheet == timesheet, let currentDuration = currentTask?.duration {
            labelCurrent.stringValue = currentDuration.string
        } else {
            labelCurrent.stringValue = "---"
        }
        
    }
    
    
    // MARK: - User Actions
    
    @IBAction func startTimer(_ sender: NSButton) {
        
        guard let sheet = timesheet, currentTask == nil else {
            log.error("Time sheet not loaded or a task is already running!")
            NSBeep()
            return
        }
        
        let task = Task()
        let realm = try! Realm()
        try! realm.write {
            sheet.tasks.append(task)
        }
        
        startUIUpdateTimer()
        
        NSApp.dockTile.badgeLabel = " "
        
        self.sheetsDelegate?.refreshSheetsList(byReloading: false)
        
        log.debug(self.currentTask)
        
    }
    
    @IBAction func stopTimer(_ sender: NSButton) {
        
        guard let task = currentTask else {
            log.error("Task not running!")
            NSBeep()
            return }
        
        guard currentTask?.timesheet == self.timesheet else {
            log.error("Trying to stop a task that is not shown currently!")
            NSBeep()
            return
        }
        
        let realm = try! Realm()
        try! realm.write {
            task.end = Date()
            task.running = false
        }
        
        NSApp.dockTile.badgeLabel = nil
        
        self.sheetsDelegate?.refreshSheetsList(byReloading: false)
        
        log.debug("\(task),\n\ran \(task.duration) s")
        
    }

    @IBAction func exportTimesheet(_ button: NSButton) {
        
        log.verbose("Exporting...")
        
        guard let tasks = self.timesheet?.tasks else { NSBeep(); return }
        let tasksRef = ThreadSafeReference(to: tasks)
        
        let sender = self.btnExport
        sender?.isEnabled = false
        
        Async.userInitiated { [weak self] in
            
            let realm = try! Realm()
            guard let allTasks = realm.resolve(tasksRef) else {
                Async.main { sender?.isEnabled = true }
                return // gone
            }
            
            guard var csvString = allTasks.first?.timesheet?.representation(.csv) as? String else {
                Async.main { sender?.isEnabled = true }
                return
            }
            
            /* Convert CSV */
            for task in allTasks {
                csvString.append(task.representation(.csv) as! String)
            }
            
            self?.log.verbose(csvString)
            
            /* Show save panel */
            
            let fileName = allTasks.first?.timesheet?.title ?? "Export"
            
            Async.main {
                
                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = fileName
                savePanel.isExtensionHidden = false
                savePanel.canSelectHiddenExtension = true
                savePanel.allowedFileTypes = ["csv"]
                savePanel.begin(completionHandler: { (result) in
                    
                    sender?.isEnabled = true
                    
                    if result == NSFileHandlingPanelOKButton, let saveURL = savePanel.url {
                        do {
                            try csvString.write(to: saveURL, atomically: true, encoding: .utf8)
                        } catch let error {
                            XCGLogger.default.error(error)
                        }
                    }
                    
                })
                
            }
            
        }
        
    }
    
    @IBAction func deleteTimesheet(_ sender: NSButton) {
        
        guard let timesheet = self.timesheet else { NSBeep(); return }
        
        let delButton = self.btnDelete
        delButton?.isEnabled = false
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = NSLocalizedString("Do you want to delete this timesheet?", comment: "Title delete confirm")
        alert.informativeText = NSLocalizedString("All associated tasks and tracked time spans will be removed, too.", comment: "Subtitle delete confirm")
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: "Modal action delete timesheet"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Modal action cancel"))
        
        alert.beginSheetModal(for: NSApp.mainWindow!) { [weak self] (response) in
            
            if response == NSAlertFirstButtonReturn {
                
                /* Delete */
                
                let realm = try! Realm()
                
                try! realm.write {
                    realm.delete(timesheet.tasks)
                    realm.delete(timesheet)
                }
                
                self?.sheetsDelegate?.refreshSheetsList(byReloading: true)
                
            }
            
            delButton?.isEnabled = true
            
        }
        
    }
    
    @IBAction func copyTimeSpan(_ sender: Any) {
        
        guard let duration = self.timesheet?.duration else { return }
        
        let pasteboard = NSPasteboard.general()
        let hours = duration / 3600.0
        let durationString = String(format: "%.2f", hours)
        pasteboard.declareTypes(["public.utf8-plain-text"], owner: self)
        pasteboard.setString(durationString, forType: "public.utf8-plain-text")
        
    }
    
}


// MARK: - Protocols and Extensions

protocol SheetsDelegate {
    func refreshSheetsList(byReloading reloading: Bool)
}

