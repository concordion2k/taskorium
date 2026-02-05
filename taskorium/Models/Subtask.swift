//
//  Subtask.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import Foundation
import SwiftData

@Model
final class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date

    @Relationship(inverse: \Card.subtasks)
    var card: Card?

    init(title: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = Date()
    }
}
