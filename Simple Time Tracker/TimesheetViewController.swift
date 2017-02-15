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

class TimesheetViewController: NSViewController {
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelTotal: NSTextField!
    @IBOutlet weak var btnStart: NSButton!
    @IBOutlet weak var btnStop: NSButton!
    
    let log = XCGLogger.default
    
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
        if let totalDuration = timesheet?.duration {
            labelTotal.stringValue = totalDuration.string
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
        
        log.debug("\(task),\n\ran \(task.duration) s")
        
    }

}

