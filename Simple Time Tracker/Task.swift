//
//  Task.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftDate

enum Representation {
    case csv
}

class Task: Object {
    
    @objc dynamic var start = Date()
    @objc dynamic var end: Date?
    @objc dynamic var running: Bool = true
    @objc dynamic var note: String?
    
    /* Inverse relationship to Timesheet */
    fileprivate let _timesheets = LinkingObjects(fromType: Timesheet.self, property: "tasks")
    var timesheet: Timesheet? { return _timesheets.first }
    
    /* Computed properties */
    
    var duration: TimeInterval {
        get {
            let startDate = start
            let endDate = end ?? Date() // end not set when still running
            
            return endDate - startDate
        }
    }
    
    class func runningTask() -> Task? {
        
        let realm = try! Realm()
        let tasks = realm.objects(Task.self).filter("running = true")
        return tasks.first
        
    }
    
    fileprivate var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = false
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()
    
    func representation(_ type: Representation) -> Any {
        
        switch type {
        case .csv:
            
            /* Convert to CSV */
            let startDate = dateFormatter.string(from: start)
            var endDate = ""
            if let end = end { endDate = dateFormatter.string(from: end) }
            return "\(startDate);\(endDate);\(end != nil ? duration.string : "");\(note ?? "")\n"
            
        }
        
    }
    
}
