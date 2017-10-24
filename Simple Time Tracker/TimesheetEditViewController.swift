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
    @IBOutlet weak var tableView: NSTableView!
    
    
    // MARK: - VC lifecycle
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.tableView.reloadData()
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
            return self.timesheet?.tasks[row].end
        case "notes":
            return self.timesheet?.tasks[row].note
        default:
            return nil
        }
        
    }
    
}
