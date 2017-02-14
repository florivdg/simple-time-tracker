//
//  Task.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Foundation
import RealmSwift

class Task: Object {
    
    dynamic var start: Date?
    dynamic var end: Date?
    dynamic var running: Bool = false
    dynamic var note: String?
    
    /* Inverse relationship to Timesheet */
    fileprivate let _timesheets = LinkingObjects(fromType: Timesheet.self, property: "tasks")
    var timesheet: Timesheet? { return _timesheets.first }
    
}
