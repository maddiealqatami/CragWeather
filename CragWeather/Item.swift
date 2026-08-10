//
//  Item.swift
//  CragWeather
//
//  Created by Maddie AlQatami on 8/10/26.
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
