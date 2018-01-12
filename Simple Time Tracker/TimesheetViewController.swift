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

class TimesheetViewController: NSViewController, NSTextFieldDelegate {
    
    // MARK: - Outlets
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelTotal: NSTextField!
    @IBOutlet weak var labelCurrent: NSTextField!
    @IBOutlet weak var textFieldNotes: NSTextField! {
        didSet {
            textFieldNotes.delegate = self
        }
    }
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
    var updateTimerDelegate: UpdateTimerDelegate?

    var timesheetEditWindowController: NSWindowController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateUI()
    }
    
    
    //  MARK: - User Interface
    
    func updateUI() {
        
        guard let sheet = timesheet, sheet.isInvalidated == false else {
            showEmptyUI()
            labelTitle.isEnabled = false
            if let editWC = self.timesheetEditWindowController { editWC.close(); self.timesheetEditWindowController = nil }
            return
        }
        
        startUIUpdateTimer()
        
        labelTitle.stringValue = sheet.title
        
        labelTitle.isEnabled = true
        
        textFieldNotes.isEnabled = (currentTask == nil)
        
        textFieldNotes.stringValue = sheet.lastUsedTimesheetNote ?? ""
        
        if let editVC = self.timesheetEditWindowController?.contentViewController as? TimesheetEditViewController {
            editVC.timesheet = timesheet
        }
        
    }
    
    func showEmptyUI() {
        
        labelTitle.stringValue = NSLocalizedString("No timesheet", comment: "Title label main window for empty state")
        labelTotal.stringValue = ""
        labelCurrent.stringValue = ""
        textFieldNotes.stringValue = ""
        
    }
    
    func startUIUpdateTimer() {
        
        updateDurationDisplay()
        
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
            if self?.currentTask == nil {
                self?.updateTimer?.invalidate()
            } else {
                self?.updateDurationDisplay()
                self?.updateTimerDelegate?.timerDidUpdate()
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
            NSSound.beep()
            return
        }
        
        let task = Task()
        
        /* Have a note? */
        let note = textFieldNotes.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.count > 0 {
            task.note = note
        }
        
        let realm = try! Realm()
        try! realm.write {
            sheet.tasks.append(task)
            task.timesheet?.lastUsedTimesheetNote = note
        }
        
        startUIUpdateTimer()
        
        NSApp.dockTile.badgeLabel = " "
        
        // Disable notes textfield
        textFieldNotes.isEnabled = false
        
        self.sheetsDelegate?.refreshSheetsList(byReloading: false)
        
        log.debug(self.currentTask)
        
    }
    
    @IBAction func stopTimer(_ sender: NSButton) {
        
        guard let task = currentTask else {
            log.error("Task not running!")
            NSSound.beep()
            return }
        
        guard currentTask?.timesheet == self.timesheet else {
            log.error("Trying to stop a task that is not shown currently!")
            NSSound.beep()
            return
        }
        
        let realm = try! Realm()
        try! realm.write {
            task.end = Date()
            task.running = false
        }
        
        // Disable notes textfield
        textFieldNotes.isEnabled = true
        
        NSApp.dockTile.badgeLabel = nil
        
        self.sheetsDelegate?.refreshSheetsList(byReloading: false)
        
        log.debug("\(task),\n\ran \(task.duration) s")
        
    }

    @IBAction func exportTimesheet(_ button: NSButton) {
        
        log.verbose("Exporting...")
        
        guard let tasks = self.timesheet?.tasks, tasks.count != 0 else { NSSound.beep(); return }
        let tasksRef = ThreadSafeReference(to: tasks)
        
        let sender = self.btnExport
        sender?.isEnabled = false
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            
            let realm = try! Realm()
            guard let allTasks = realm.resolve(tasksRef) else {
                DispatchQueue.main.async { sender?.isEnabled = true }
                return // gone
            }
            
            guard var csvString = allTasks.first?.timesheet?.representation(.csv) as? String else {
                DispatchQueue.main.async { sender?.isEnabled = true }
                return
            }
            
            /* Convert CSV */
            for task in allTasks {
                csvString.append(task.representation(.csv) as! String)
            }
            
            self?.log.verbose(csvString)
            
            /* Show save panel */
            
            let fileName = allTasks.first?.timesheet?.title ?? "Export"
            
            DispatchQueue.main.async {
                
                let savePanel = NSSavePanel()
                savePanel.nameFieldStringValue = fileName
                savePanel.isExtensionHidden = false
                savePanel.canSelectHiddenExtension = true
                savePanel.allowedFileTypes = ["csv"]
                savePanel.begin(completionHandler: { (result) in
                    
                    sender?.isEnabled = true
                    
                    if result == NSApplication.ModalResponse.OK, let saveURL = savePanel.url {
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
        
        guard let timesheet = self.timesheet else { NSSound.beep(); return }
        
        let delButton = self.btnDelete
        delButton?.isEnabled = false
        
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = NSLocalizedString("Do you want to delete this timesheet?", comment: "Title delete confirm")
        alert.informativeText = NSLocalizedString("All associated tasks and tracked time spans will be removed, too.", comment: "Subtitle delete confirm")
        alert.addButton(withTitle: NSLocalizedString("Delete", comment: "Modal action delete timesheet"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Modal action cancel"))
        
        alert.beginSheetModal(for: NSApp.mainWindow!) { [weak self] (response) in
            
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                
                /* Delete */
                
                let realm = try! Realm()
                
                try! realm.write {
                    realm.delete(timesheet.tasks)
                    realm.delete(timesheet)
                }
                
                self?.timesheet = nil
                
                self?.sheetsDelegate?.refreshSheetsList(byReloading: true)
                
            }
            
            delButton?.isEnabled = true
            
        }
        
    }
    
    @IBAction func copyTimeSpan(_ sender: Any) {
        
        guard let duration = self.timesheet?.duration else { return }
        
        let pasteboard = NSPasteboard.general
        let hours = duration / 3600.0
        let durationString = String(format: "%.2f", hours)
        pasteboard.declareTypes([NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text")], owner: self)
        pasteboard.setString(durationString, forType: NSPasteboard.PasteboardType(rawValue: "public.utf8-plain-text"))
        
    }
    
    @IBAction func editTimesheet(_ sender: Any) {
        
        if self.timesheetEditWindowController == nil {
            let timesheetStoryboard = NSStoryboard(name: .init("Timesheet"), bundle: nil)
            if let timesheetWindowController = timesheetStoryboard.instantiateInitialController() as? NSWindowController {
                self.timesheetEditWindowController = timesheetWindowController
                if let editVC = self.timesheetEditWindowController?.contentViewController as? TimesheetEditViewController {
                    editVC.timesheet = self.timesheet
                    self.updateTimerDelegate = editVC
                }
            }
        }
        
        self.timesheetEditWindowController?.showWindow(self)
        self.timesheetEditWindowController?.window?.makeKeyAndOrderFront(self)
        
    }
    
    
    // MARK: - NSTextFieldDelegate
    
    var isAutocompleting = false
    var isCommandHandling = false
    
    override func controlTextDidChange(_ obj: Notification) {
        guard let textView = obj.userInfo?.values.first as? NSTextView else { return }
        
        if !isAutocompleting && !isCommandHandling {
            isAutocompleting = true
            textView.complete(nil)
            isAutocompleting = false
        }
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        
        var didPerformSelectedRequestorOnTextView = false
        
        if textView.responds(to: commandSelector) {
            isCommandHandling = true
            
            textView.perform(commandSelector)
            didPerformSelectedRequestorOnTextView = true
            
            isCommandHandling = false
        }
        
        return didPerformSelectedRequestorOnTextView
        
    }
    
    func control(_ control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        let typedChars = textView.string
        let prevNotes = self.timesheet?.noteHistory
        
        index.pointee = -1
        
        if typedChars.count > 0 {
            return prevNotes?.filter { $0.contains(typedChars) } ?? []
        } else {
            return prevNotes ?? []
        }
    }
    
}


// MARK: - Protocols and Extensions

protocol SheetsDelegate {
    func refreshSheetsList(byReloading reloading: Bool)
}

protocol UpdateTimerDelegate {
    func timerDidUpdate()
}
