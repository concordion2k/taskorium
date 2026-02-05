//
//  taskoriumApp.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData

@main
struct taskoriumApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Project.self,
            Column.self,
            Card.self,
            Subtask.self
        ])

        // Use lightweightMigration to allow schema evolution
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Migrate existing projects to have order property
            let context = container.mainContext
            let descriptor = FetchDescriptor<Project>(sortBy: [SortDescriptor(\.createdAt)])
            if let projects = try? context.fetch(descriptor) {
                // Assign order based on creation date for existing projects without order
                var needsSave = false
                for (index, project) in projects.enumerated() {
                    // Check if this project needs order assigned
                    if index > 0 && project.order == 0 {
                        project.order = index
                        needsSave = true
                    }
                }
                if needsSave {
                    try? context.save()
                }
            }

            return container
        } catch {
            // If migration fails, print helpful error
            print("Failed to create ModelContainer: \(error)")
            print("You may need to delete the SwiftData store. See MIGRATION_GUIDE.md for instructions.")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
