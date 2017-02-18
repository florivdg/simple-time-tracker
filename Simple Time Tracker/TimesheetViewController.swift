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
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelTotal: NSTextField!
    @IBOutlet weak var labelCurrent: NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    
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
    
    func updateUI() {
        
        guard let sheet = timesheet else {
            showEmptyUI()
            return
        }
        
        startUIUpdateTimer()
        
        labelTitle.stringValue = sheet.title
        
    }
    
    func showEmptyUI() {
        
        labelTitle.stringValue = "n/a"
        
    }
    
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
        
        log.debug(self.currentTask)
        
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
        
        log.debug("\(task),\n\ran \(task.duration) s")
        
    }

    @IBAction func exportTimesheet(_ sender: NSButton) {
        
        log.verbose("Exporting...")
        
        guard let tasks = self.timesheet?.tasks else { NSBeep(); return }
        let tasksRef = ThreadSafeReference(to: tasks)
        
        Async.userInitiated { [weak self] in
            
            let realm = try! Realm()
            guard let allTasks = realm.resolve(tasksRef) else {
                return // gone
            }
            
            guard var csvString = allTasks.first?.timesheet?.representation(.csv) as? String else { return }
            
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
}

