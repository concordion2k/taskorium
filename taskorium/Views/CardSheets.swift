//
//  CardSheets.swift
//  taskorium
//
//  Created by Dan Douston on 2/3/26.
//

import SwiftUI
import SwiftData

// MARK: - Reusable Planetary Field Components

struct PlanetaryFieldLabel: View {
    let text: String
    let icon: String

    init(_ text: String, icon: String = "sparkle") {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(
                    LinearGradient(colors: [.purple.opacity(0.8), .cyan.opacity(0.8)],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }
}

struct PlanetaryTextField: View {
    let label: String
    let icon: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var lineLimit: ClosedRange<Int>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            PlanetaryFieldLabel(label, icon: icon)

            Group {
                if let lineLimit = lineLimit {
                    TextField("", text: $text, axis: axis)
                        .lineLimit(lineLimit)
                } else {
                    TextField("", text: $text)
                }
            }
            .textFieldStyle(.plain)
            .font(.body)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(colors: [.purple.opacity(0.2), .cyan.opacity(0.2)],
                                       startPoint: .leading, endPoint: .trailing),
                        lineWidth: 1
                    )
            )
        }
    }
}

struct PlanetarySectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .cyan],
                                   startPoint: .leading, endPoint: .trailing)
                )
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)

            Spacer()

            // Decorative dots
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            LinearGradient(colors: [.purple.opacity(0.4), .cyan.opacity(0.4)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: 3, height: 3)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - New Card Sheet

struct NewCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let column: Column

    @State private var title = ""
    @State private var content = ""
    @State private var subtasks: [String] = []
    @State private var newSubtaskText = ""
    @FocusState private var newSubtaskFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Card Details
                    VStack(alignment: .leading, spacing: 16) {
                        PlanetarySectionHeader(title: "Card Details", icon: "doc.text.fill")

                        PlanetaryTextField(label: "Title", icon: "star.fill", text: $title)

                        PlanetaryTextField(label: "Description", icon: "text.alignleft",
                                          text: $content, axis: .vertical, lineLimit: 3...6)
                    }

                    // Subtasks
                    VStack(alignment: .leading, spacing: 12) {
                        PlanetarySectionHeader(title: "Subtasks", icon: "checklist")

                        ForEach(Array(subtasks.enumerated()), id: \.offset) { index, _ in
                            HStack(spacing: 10) {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                    .font(.title3)

                                TextField("Subtask", text: Binding(
                                    get: { subtasks[index] },
                                    set: { subtasks[index] = $0 }
                                ))
                                .textFieldStyle(.plain)

                                Button(action: { subtasks.remove(at: index) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 10)
                        }

                        // Inline add subtask row
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .foregroundColor(.secondary.opacity(0.5))
                                .font(.title3)

                            TextField("Add a subtask here", text: $newSubtaskText)
                                .textFieldStyle(.plain)
                                .italic()
                                .foregroundColor(.secondary)
                                .focused($newSubtaskFocused)
                                .onSubmit {
                                    commitNewSubtask()
                                }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                    }
                }
                .padding(24)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createCard() }
                        .disabled(title.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 550)
    }

    private func commitNewSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        subtasks.append(trimmed)
        newSubtaskText = ""
        newSubtaskFocused = true
    }

    private func createCard() {
        let card = Card(title: title, content: content, order: column.cards.count)

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

// MARK: - Edit Card Sheet

struct EditCardSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var card: Card

    @State private var title: String
    @State private var content: String
    @State private var editingSubtasks: [EditableSubtask]
    @State private var showDeleteConfirmation = false
    @State private var newSubtaskText = ""
    @FocusState private var newSubtaskFocused: Bool

    init(card: Card) {
        self.card = card
        _title = State(initialValue: card.title)
        _content = State(initialValue: card.content)
        _editingSubtasks = State(initialValue: card.subtasks.map {
            EditableSubtask(id: $0.id, title: $0.title, isCompleted: $0.isCompleted)
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cardDetailsSection
                    subtasksSection
                }
                .padding(24)
            }
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationTitle("Edit Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveCard() }
                        .disabled(title.isEmpty)
                }
            }
            .alert("Delete Card", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteCard() }
            } message: {
                Text("Are you sure you want to delete this card? This action cannot be undone.")
            }
        }
        .frame(width: 500, height: 550)
    }

    private var cardDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PlanetarySectionHeader(title: "Card Details", icon: "doc.text.fill")

            PlanetaryTextField(label: "Title", icon: "star.fill", text: $title)

            PlanetaryTextField(label: "Description", icon: "text.alignleft",
                              text: $content, axis: .vertical, lineLimit: 3...6)
        }
    }

    private var subtasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlanetarySectionHeader(title: "Subtasks", icon: "checklist")

            ForEach(0..<editingSubtasks.count, id: \.self) { index in
                existingSubtaskRow(at: index)
            }

            // Inline add subtask row
            HStack(spacing: 10) {
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.title3)

                TextField("Add a subtask here", text: $newSubtaskText)
                    .textFieldStyle(.plain)
                    .italic()
                    .foregroundColor(.secondary)
                    .focused($newSubtaskFocused)
                    .onSubmit {
                        commitNewSubtask()
                    }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 10)
        }
    }

    private func existingSubtaskRow(at index: Int) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                editingSubtasks[index].isCompleted.toggle()
            }) {
                Image(systemName: editingSubtasks[index].isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(editingSubtasks[index].isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            TextField("Subtask", text: $editingSubtasks[index].title)
                .textFieldStyle(.plain)
                .strikethrough(editingSubtasks[index].isCompleted)
                .foregroundColor(editingSubtasks[index].isCompleted ? .secondary : .primary)

            Button(action: { removeSubtask(at: index) }) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
    }

    private func commitNewSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        editingSubtasks.append(EditableSubtask(id: UUID(), title: trimmed, isCompleted: false))
        newSubtaskText = ""
        newSubtaskFocused = true
    }

    private func removeSubtask(at index: Int) {
        let subtaskId = editingSubtasks[index].id
        editingSubtasks.remove(at: index)

        if let subtaskIndex = card.subtasks.firstIndex(where: { $0.id == subtaskId }) {
            let subtask = card.subtasks[subtaskIndex]
            card.subtasks.remove(at: subtaskIndex)
            modelContext.delete(subtask)
        }
    }

    private func saveCard() {
        card.title = title
        card.content = content

        var updatedSubtasks: [Subtask] = []

        for editableSubtask in editingSubtasks where !editableSubtask.title.trimmingCharacters(in: .whitespaces).isEmpty {
            if let existingSubtask = card.subtasks.first(where: { $0.id == editableSubtask.id }) {
                existingSubtask.title = editableSubtask.title
                existingSubtask.isCompleted = editableSubtask.isCompleted
                updatedSubtasks.append(existingSubtask)
            } else {
                let newSubtask = Subtask(title: editableSubtask.title, isCompleted: editableSubtask.isCompleted)
                modelContext.insert(newSubtask)
                updatedSubtasks.append(newSubtask)
            }
        }

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
