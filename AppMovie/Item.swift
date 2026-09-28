//
//  Item.swift
//  AppMovie
//
//  Created by Facultad de Contaduría y Administración on 28/09/26.
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
