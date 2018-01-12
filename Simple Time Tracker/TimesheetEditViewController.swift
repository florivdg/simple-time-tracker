//
//  TimesheetEditViewController.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 23.10.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa

class TimesheetEditViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    // MARK: - Properties
    
    var timesheet: Timesheet? {
        didSet {
            self.labelTitle.stringValue = timesheet?.title ?? "n/a"
            self.tableView.reloadData()
        }
    }

    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDuration: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    var updateTimer: Timer?
    
    
    // MARK: - VC lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.tableView.reloadData()
        
        self.startUIUpdateTimer()
    }

    
    // MARK: - User Interface
    
    func updateDuration() {
        
        if tableView.selectedRow == -1 {
            self.labelDuration.stringValue = self.timesheet?.duration.string ?? ""
        } else {
            let selectedIndexes = tableView.selectedRowIndexes
            if let timesheet = self.timesheet {
                let selectedTasks = selectedIndexes.map { timesheet.tasks[$0] }
                let duration = selectedTasks.reduce(0.0, { (result, task) -> TimeInterval in
                    return result + task.duration
                })
                labelDuration.stringValue = duration.string
            }
        }
        
    }
    
    func startUIUpdateTimer() {
        
        self.updateDuration()
        
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            if self?.timesheet == nil {
                self?.updateTimer?.invalidate()
            } else {
                self?.updateDuration()
            }
        })
        
    }
    
    
    // MARK: - NSTableViewDelegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.timesheet?.tasks.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        
        guard let colID = tableColumn?.identifier.rawValue else {
            return nil
        }
        
        switch colID {
        case "start":
            return self.timesheet?.tasks[row].start
        case "end":
            return self.timesheet?.tasks[row].end ?? NSLocalizedString("running now", comment: "TimesheetEditVC table view cell end date when task is currently running")
        case "duration":
            if let task = self.timesheet?.tasks[row] {
                return task.duration.string
            } else {
                return "0"
            }
        case "notes":
            return self.timesheet?.tasks[row].note
        default:
            return nil
        }
        
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        updateDuration()
        
    }
    
}
