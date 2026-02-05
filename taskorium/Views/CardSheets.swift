//
//  CardSheets.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData

struct NewCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let column: Column

    @State private var title = ""
    @State private var content = ""
    @State private var subtasks: [String] = [""]

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Title", text: $title)
                    TextField("Description (Optional)", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Subtasks") {
                    ForEach(Array(subtasks.enumerated()), id: \.offset) { index, subtask in
                        HStack {
                            TextField("Subtask \(index + 1)", text: Binding(
                                get: { subtasks[index] },
                                set: { subtasks[index] = $0 }
                            ))

                            if subtasks.count > 1 {
                                Button(action: { removeSubtask(at: index) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Button(action: addSubtask) {
                        Label("Add Subtask", systemImage: "plus.circle")
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createCard()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 600)
    }

    private func addSubtask() {
        subtasks.append("")
    }

    private func removeSubtask(at index: Int) {
        subtasks.remove(at: index)
    }

    private func createCard() {
        let card = Card(title: title, content: content, order: column.cards.count)

        // Add non-empty subtasks
        for subtaskTitle in subtasks where !subtaskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            let subtask = Subtask(title: subtaskTitle)
            card.subtasks.append(subtask)
            modelContext.insert(subtask)
        }

        column.cards.append(card)
        modelContext.insert(card)

        dismiss()
    }
}

struct EditCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: Card

    @State private var title: String
    @State private var content: String
    @State private var editingSubtasks: [EditableSubtask]
    @State private var showDeleteConfirmation = false

    init(card: Card) {
        self.card = card
        _title = State(initialValue: card.title)
        _content = State(initialValue: card.content)
        _editingSubtasks = State(initialValue: card.subtasks.map { EditableSubtask(id: $0.id, title: $0.title, isCompleted: $0.isCompleted) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Title", text: $title)
                    TextField("Description (Optional)", text: $content, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Subtasks") {
                    ForEach(0..<editingSubtasks.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            Button(action: {
                                editingSubtasks[index].isCompleted.toggle()
                            }) {
                                Image(systemName: editingSubtasks[index].isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(editingSubtasks[index].isCompleted ? .green : .secondary)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)

                            TextField("Subtask", text: $editingSubtasks[index].title)
                                .strikethrough(editingSubtasks[index].isCompleted)
                                .foregroundColor(editingSubtasks[index].isCompleted ? .secondary : .primary)

                            Button(action: { removeSubtask(at: index) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }

                    Button(action: addSubtask) {
                        Label("Add Subtask", systemImage: "plus.circle")
                    }
                    .padding(.vertical, 4)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .alert("Delete Card", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteCard()
                }
            } message: {
                Text("Are you sure you want to delete this card? This action cannot be undone.")
            }
        }
        .frame(width: 500, height: 600)
    }

    private func addSubtask() {
        editingSubtasks.append(EditableSubtask(id: UUID(), title: "", isCompleted: false))
    }

    private func removeSubtask(at index: Int) {
        let subtaskId = editingSubtasks[index].id
        editingSubtasks.remove(at: index)

        // Remove from the actual card
        if let subtaskIndex = card.subtasks.firstIndex(where: { $0.id == subtaskId }) {
            let subtask = card.subtasks[subtaskIndex]
            card.subtasks.remove(at: subtaskIndex)
            modelContext.delete(subtask)
        }
    }

    private func saveCard() {
        card.title = title
        card.content = content

        // Update existing subtasks and create new ones
        var updatedSubtasks: [Subtask] = []

        for editableSubtask in editingSubtasks where !editableSubtask.title.trimmingCharacters(in: .whitespaces).isEmpty {
            if let existingSubtask = card.subtasks.first(where: { $0.id == editableSubtask.id }) {
                // Update existing subtask
                existingSubtask.title = editableSubtask.title
                existingSubtask.isCompleted = editableSubtask.isCompleted
                updatedSubtasks.append(existingSubtask)
            } else {
                // Create new subtask
                let newSubtask = Subtask(title: editableSubtask.title, isCompleted: editableSubtask.isCompleted)
                modelContext.insert(newSubtask)
                updatedSubtasks.append(newSubtask)
            }
        }

        // Remove deleted subtasks
        for subtask in card.subtasks {
            if !updatedSubtasks.contains(where: { $0.id == subtask.id }) {
                modelContext.delete(subtask)
            }
        }

        card.subtasks = updatedSubtasks

        dismiss()
    }

    private func deleteCard() {
        if let column = card.column {
            if let index = column.cards.firstIndex(where: { $0.id == card.id }) {
                column.cards.remove(at: index)
            }
        }
        modelContext.delete(card)
        dismiss()
    }
}

struct EditableSubtask: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Column.self, Card.self, Subtask.self, configurations: config)

    let column = Column(name: "To Do")
    container.mainContext.insert(column)

    return NewCardSheet(column: column)
        .modelContainer(container)
}
