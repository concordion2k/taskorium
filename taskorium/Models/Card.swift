//
//  Card.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import Foundation
import SwiftData

@Model
final class Card {
    var id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var order: Int

    @Relationship(deleteRule: .cascade)
    var subtasks: [Subtask]

    @Relationship(inverse: \Column.cards)
    var column: Column?

    init(title: String, content: String = "", order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.createdAt = Date()
        self.order = order
        self.subtasks = []
    }
}
