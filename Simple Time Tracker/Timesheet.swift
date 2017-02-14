//
//  Timesheet.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 14.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Foundation
import RealmSwift

class Timesheet: Object {
    
    dynamic var title = ""
    dynamic var notes: String?
    
    let tasks = List<Task>()
    
    class func createDefault() -> Bool {
        
        let realm = try! Realm()
        if realm.objects(Timesheet.self).count == 0 {
            
            /* Create default */
            let sheet = Timesheet()
            sheet.title = NSLocalizedString("Default", comment: "Title of default timesheet")
            
            try! realm.write {
                realm.add(sheet)
            }
            
            return true
        }
        
        return false
        
    }
    
}
