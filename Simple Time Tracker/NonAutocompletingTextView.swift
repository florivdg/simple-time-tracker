//
//  NonAutocompletingTextView.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 23.10.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Cocoa

class NonAutocompletingTextView: NSTextView {

    override func insertCompletion(_ word: String, forPartialWordRange charRange: NSRange, movement: Int, isFinal flag: Bool) {
        
        // Don't autocomplete on space bar
        if movement == NSRightTextMovement { return }
        
        var range = charRange
        
        // show full replacements
        if (charRange.location != 0) {
            range = charRange
            range.length = charRange.location
            range.location = 0
        }
        
        super.insertCompletion(word, forPartialWordRange: range, movement: movement, isFinal: flag)
        
    }
    
}
