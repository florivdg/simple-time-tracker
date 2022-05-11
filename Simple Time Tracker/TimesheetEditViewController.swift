//
//  TimesheetEditViewController.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 23.10.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa
import RealmSwift

class TimesheetEditViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, UpdateTimerDelegate {

    // MARK: - Properties
    
    var timesheet: Timesheet? {
        didSet {
            self.labelTitle.stringValue = timesheet?.title ?? "n/a"
            self.tableView.reloadData()
            if timesheet != nil {
                updateDuration()
            }
        }
    }
    
    var userIsEditing = false

    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDuration: NSTextField!
    @IBOutlet weak var tableView: NSTableView!
    
    
    // MARK: - VC lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.tableView.reloadData()
        
        self.updateDuration()
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
        
        if timesheet?.isRunning == true && userIsEditing == false {
            self.tableView.reloadData()
        }
        
    }
    
    func timerDidUpdate() {
        if let _ = NSApp.mainWindow?.firstResponder as? NSTextView { return }
        if timesheet == nil { return }
        updateDuration()
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
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textView = obj.userInfo?["NSFieldEditor"] as? NSTextView {
            let selectedRow = self.tableView.selectedRow
            if selectedRow != -1 {
                let newNote = textView.string
                let realm = try! Realm()
                let task = timesheet?.tasks[selectedRow]
                try! realm.write {
                    task?.note = newNote
                }
            }
        }
        userIsEditing = false
    }
    
    
    // MARK: - User actions
    
    @IBAction func copyTimeSpan(_ sender: Any) {
        
        var duration = 0.0
        
        if tableView.selectedRow == -1 {
            duration = self.timesheet?.duration ?? 0.0
        } else {
            let selectedIndexes = tableView.selectedRowIndexes
            if let timesheet = self.timesheet {
                let selectedTasks = selectedIndexes.map { timesheet.tasks[$0] }
                let selectedDuration = selectedTasks.reduce(0.0, { (result, task) -> TimeInterval in
                    return result + task.duration
                })
                duration = selectedDuration
            }
        }
        
        let pasteboard = NSPasteboard.general
        let hours = duration / 3600.0
        let durationString = String(format: "%.2f", hours)
        pasteboard.declareTypes([NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")], owner: self)
        pasteboard.setString(durationString, forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"))
        
    }
    
}
