//
//  Item.swift
//  cyclingplus
//
//  Created by Julian Cooper on 2025/11/7.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
