//
//  Date+Formatting.swift
//  Simple Time Tracker
//
//  Created by Florian Weich on 15.02.17.
//  Copyright © 2017 Florian Weich. All rights reserved.
//

import Foundation

extension TimeInterval {
    var string: String {
        get {
            
            let ti = Int(self)
            
            let seconds = ti % 60
            let minutes = (ti / 60) % 60
            let hours = (ti / 3600)
            
            return String(format: "%0.2dh %0.2dm %0.2ds",hours,minutes,seconds)
        }
    }
}
