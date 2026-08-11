//
//  Int+CragCount.swift
//  CragWeather
//

import Foundation

extension Int {
    /// User-facing count label, e.g. "1 crag" or "12 crags".
    var formattedCragCount: String {
        self == 1 ? "1 crag" : "\(self) crags"
    }
}
