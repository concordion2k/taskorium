//
//  Project.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import Foundation
import SwiftData

enum PlanetType: String, Codable, CaseIterable {
    case mercury
    case venus
    case earth
    case mars
    case jupiter
    case saturn
    case uranus
    case neptune

    var displayName: String {
        rawValue.capitalized
    }
}

@Model
final class Project {
    var id: UUID
    var name: String
    var projectDescription: String
    var planetType: PlanetType
    var createdAt: Date
    var order: Int

    @Relationship(deleteRule: .cascade)
    var columns: [Column]

    init(name: String, projectDescription: String = "", planetType: PlanetType = .earth, order: Int = 0) {
        self.id = UUID()
        self.name = name
        self.projectDescription = projectDescription
        self.planetType = planetType
        self.createdAt = Date()
        self.order = order
        self.columns = []

        // Create default columns
        createDefaultColumns()
    }

    private func createDefaultColumns() {
        let todoColumn = Column(name: "To Do", order: 0)
        let inProgressColumn = Column(name: "In Progress", order: 1)
        let doneColumn = Column(name: "Done", order: 2)

        self.columns = [todoColumn, inProgressColumn, doneColumn]
    }
}
