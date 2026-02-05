//
//  ContentView.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ProjectListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Column.self, Card.self, Subtask.self], inMemory: true)
}
