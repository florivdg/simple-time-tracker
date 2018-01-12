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
    
    @objc dynamic var title = ""
    @objc dynamic var notes: String?
    @objc dynamic var lastUsedTimesheetNote: String?
    @objc dynamic var identifier = UUID().uuidString
    override static func primaryKey() -> String? {
        return "identifier"
    }
    var noteHistory: [String] {
        get {
            let uniqueNotes = Set( self.tasks.flatMap { $0.note } )
            return Array(uniqueNotes).sorted()
        }
    }
    
    let tasks = List<Task>()
    
    class func addTimesheet(withTitle title: String) -> Timesheet? {
        
        let predicate = NSPredicate(format: "title = %@", title)
        let realm = try! Realm()
        let results = realm.objects(Timesheet.self).filter(predicate)
        guard results.count == 0 else { return nil }
        
        let sheet = Timesheet()
        sheet.title = title
        
        try! realm.write {
            realm.add(sheet)
        }
        
        return sheet
        
    }
    
    class func timesheet(byTitle title: String) -> Timesheet? {
        
        let predicate = NSPredicate(format: "title = %@", title)
        let realm = try! Realm()
        let results = realm.objects(Timesheet.self).filter(predicate)
        
        return results.first
        
    }
    
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
    
    var duration: TimeInterval {
        get {
            return self.tasks.map({$0.duration}).reduce(0,+)
        }
    }
    
    var isRunning: Bool {
        get {
            return (self.tasks.filter("running = true").count != 0)
        }
    }
    
    func representation(_ type: Representation) -> Any {
        
        switch type {
        case .csv:
            
            /* Convert to CSV */
            return "Start Date;End Date;Duration;Notes\n"
            
        }
        
    }
    
}
