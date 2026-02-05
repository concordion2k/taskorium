//
//  ProjectListView.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.order) private var projects: [Project]
    @State private var showingNewProjectSheet = false
    @State private var selectedProject: Project?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedProject) {
                ForEach(projects) { project in
                    NavigationLink(value: project) {
                        HStack(spacing: 12) {
                            PlanetView(planetType: project.planetType, size: 32)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name)
                                    .font(.headline)

                                if !project.projectDescription.isEmpty {
                                    Text(project.projectDescription)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .draggable(project.id.uuidString)
                }
                .onMove { source, destination in
                    moveProjects(from: source, to: destination)
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingNewProjectSheet = true }) {
                        Label("New Project", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewProjectSheet) {
                NewProjectSheet(projectCount: projects.count)
            }
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            } else {
                ZStack {
                    ConstellationBackground(constellation: .cassiopeia)
                        .opacity(0.3)

                    VStack(spacing: 20) {
                        PlanetView(planetType: .earth, size: 120)
                        Text("Select a project to get started")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func moveProjects(from source: IndexSet, to destination: Int) {
        var updatedProjects = projects.map { $0 }
        updatedProjects.move(fromOffsets: source, toOffset: destination)

        // Update the order of all projects
        for (index, project) in updatedProjects.enumerated() {
            project.order = index
        }
    }
}

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlanetView(planetType: project.planetType, size: 80)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .lineLimit(1)

                if !project.projectDescription.isEmpty {
                    Text(project.projectDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Label("\(project.columns.count)", systemImage: "rectangle.3.group")
                    Spacer()
                    let totalCards = project.columns.reduce(0) { $0 + $1.cards.count }
                    Label("\(totalCards)", systemImage: "doc.text")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let projectCount: Int

    @State private var name = ""
    @State private var description = ""
    @State private var selectedPlanet: PlanetType = .earth

    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Choose a Planet") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 80), spacing: 20)
                    ], spacing: 20) {
                        ForEach(PlanetType.allCases, id: \.self) { planet in
                            VStack {
                                PlanetView(planetType: planet, size: 60)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 30)
                                            .stroke(selectedPlanet == planet ? Color.accentColor : Color.clear, lineWidth: 3)
                                    )
                                Text(planet.displayName)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedPlanet = planet
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 600)
    }

    private func createProject() {
        let project = Project(name: name, projectDescription: description, planetType: selectedPlanet, order: projectCount)
        modelContext.insert(project)
        dismiss()
    }
}

#Preview {
    NewProjectSheet(projectCount: 0)
        .modelContainer(for: [Project.self, Column.self, Card.self, Subtask.self], inMemory: true)
}

#Preview {
    ProjectListView()
        .modelContainer(for: [Project.self, Column.self, Card.self, Subtask.self], inMemory: true)
}
