//
//  Column.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import Foundation
import SwiftData

@Model
final class Column {
    var id: UUID
    var name: String
    var order: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var cards: [Card]

    @Relationship(inverse: \Project.columns)
    var project: Project?

    init(name: String, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.createdAt = Date()
        self.cards = []
    }
}
