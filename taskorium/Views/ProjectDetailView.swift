//
//  ProjectDetailView.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData
internal import UniformTypeIdentifiers

struct ProjectDetailView: View {
    @Bindable var project: Project
    @State private var showingNewCardSheet = false
    @State private var selectedColumn: Column?

    var body: some View {
        ZStack {
            ConstellationBackground(constellation: .orion)
                .opacity(0.2)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    ForEach(project.columns.sorted(by: { $0.order < $1.order })) { column in
                        ColumnView(column: column, project: project)
                    }

                    // Add new column button
                    AddColumnButton(project: project)
                }
                .padding(24)
            }
        }
        .navigationTitle(project.name)
        .navigationSubtitle(project.projectDescription)
    }
}

struct ColumnView: View {
    @Bindable var column: Column
    let project: Project
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var isAddingCard = false
    @State private var newCardTitle = ""
    @State private var isDropTargeted = false
    @FocusState private var isNewCardFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Column header
            HStack(spacing: 12) {
                if isEditing {
                    TextField("Column name", text: $editedName, onCommit: {
                        if !editedName.isEmpty {
                            column.name = editedName
                        }
                        isEditing = false
                    })
                    .textFieldStyle(.roundedBorder)
                } else {
                    Text(column.name)
                        .font(.headline)

                    Text("\(column.cards.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.2))
                        )

                    Spacer()

                    Menu {
                        Button("Rename") {
                            editedName = column.name
                            isEditing = true
                        }
                        Divider()
                        Button("Delete Column", role: .destructive) {
                            deleteColumn()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)

            Divider()
                .padding(.bottom, 8)

            // Cards and Add Card button in ScrollView
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(column.cards.sorted(by: { $0.order < $1.order })) { card in
                        DraggableCardView(card: card, column: column, project: project)
                    }

                    // Inline Add Card
                    if isAddingCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Card title", text: $newCardTitle)
                                .textFieldStyle(.plain)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .focused($isNewCardFocused)
                                .onSubmit {
                                    createCard()
                                }

                            HStack {
                                Button("Add Card") {
                                    createCard()
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(newCardTitle.isEmpty)

                                Button("Cancel") {
                                    isAddingCard = false
                                    newCardTitle = ""
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                    } else {
                        Button(action: {
                            isAddingCard = true
                            isNewCardFocused = true
                        }) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Add Card")
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .frame(maxHeight: .infinity)
            .onDrop(of: [.text], isTargeted: $isDropTargeted) { providers in
                handleDrop(providers: providers)
            }
        }
        .frame(width: 320)
        .frame(minHeight: 500)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTargeted ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.2), lineWidth: isDropTargeted ? 3 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isDropTargeted)
    }

    private func createCard() {
        guard !newCardTitle.isEmpty else { return }
        let card = Card(title: newCardTitle, order: column.cards.count)
        column.cards.append(card)
        modelContext.insert(card)
        newCardTitle = ""
        isAddingCard = false
    }

    private func deleteColumn() {
        if let index = project.columns.firstIndex(where: { $0.id == column.id }) {
            project.columns.remove(at: index)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }

        // Get the card ID synchronously from the item provider
        let semaphore = DispatchSemaphore(value: 0)
        var cardId: UUID?

        provider.loadItem(forTypeIdentifier: "public.text", options: nil) { item, error in
            if let data = item as? Data,
               let cardIdString = String(data: data, encoding: .utf8) {
                cardId = UUID(uuidString: cardIdString)
            }
            semaphore.signal()
        }

        // Wait briefly for the load to complete
        _ = semaphore.wait(timeout: .now() + 0.1)

        guard let id = cardId else { return false }

        // Move the card immediately on the main thread
        // Find the card in all columns
        for projectColumn in project.columns {
            if let cardIndex = projectColumn.cards.firstIndex(where: { $0.id == id }) {
                let card = projectColumn.cards[cardIndex]

                // Remove from old column
                projectColumn.cards.remove(at: cardIndex)

                // Add to new column
                card.order = column.cards.count
                column.cards.append(card)

                return true
            }
        }

        return false
    }
}

struct DraggableCardView: View {
    @Bindable var card: Card
    let column: Column
    let project: Project
    @State private var showingEditSheet = false
    @State private var isHovering = false

    var completedSubtasks: Int {
        card.subtasks.filter { $0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(card.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            if !card.content.isEmpty {
                Text(card.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }

            if !card.subtasks.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(completedSubtasks == card.subtasks.count ? .green : .secondary)
                    Text("\(completedSubtasks)/\(card.subtasks.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHovering ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.1), lineWidth: isHovering ? 2 : 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            showingEditSheet = true
        }
        .onDrag {
            NSItemProvider(object: card.id.uuidString as NSString)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCardSheet(card: card)
        }
    }
}

struct AddColumnButton: View {
    let project: Project
    @State private var showingNewColumnSheet = false
    @State private var isHovering = false

    var body: some View {
        Button(action: { showingNewColumnSheet = true }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("Add Column")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .frame(width: 320)
            .frame(minHeight: 500)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(isHovering ? 0.7 : 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                    .foregroundColor(isHovering ? Color.accentColor.opacity(0.5) : Color.white.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .sheet(isPresented: $showingNewColumnSheet) {
            NewColumnSheet(project: project)
        }
    }
}

struct NewColumnSheet: View {
    @Environment(\.dismiss) private var dismiss
    let project: Project
    @State private var columnName = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Column Name", text: $columnName)
            }
            .formStyle(.grouped)
            .navigationTitle("New Column")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createColumn()
                    }
                    .disabled(columnName.isEmpty)
                }
            }
        }
        .frame(width: 400, height: 200)
    }

    private func createColumn() {
        let newColumn = Column(name: columnName, order: project.columns.count)
        project.columns.append(newColumn)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Project.self, Column.self, Card.self, Subtask.self, configurations: config)

    let project = Project(name: "Sample Project", projectDescription: "A sample project", planetType: .earth)
    container.mainContext.insert(project)

    return NavigationStack {
        ProjectDetailView(project: project)
    }
    .modelContainer(container)
}
