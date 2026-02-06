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
    // Shared drag state so all columns know when a drag is in progress
    @State private var draggedCardId: UUID?
    @State private var draggedCardHeight: CGFloat = 100
    @State private var targetedColumns: Set<UUID> = []
    @State private var expandedCardId: UUID?

    var body: some View {
        ZStack {
            ConstellationBackground(constellation: .orion)
                .opacity(0.2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if expandedCardId != nil {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedCardId = nil
                        }
                    }
                }

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 24) {
                    ForEach(project.columns.sorted(by: { $0.order < $1.order })) { column in
                        ColumnView(
                            column: column,
                            project: project,
                            draggedCardId: $draggedCardId,
                            draggedCardHeight: $draggedCardHeight,
                            expandedCardId: $expandedCardId,
                            onColumnTargetChanged: { columnId, isActive in
                                if isActive {
                                    targetedColumns.insert(columnId)
                                } else {
                                    targetedColumns.remove(columnId)
                                }
                            }
                        )
                    }

                    // Add new column button
                    AddColumnButton(project: project)
                }
                .padding(24)
            }
        }
        .navigationTitle(project.name)
        .navigationSubtitle(project.projectDescription)
        // Detect when a drag leaves all columns (drag cancelled or dropped outside)
        .onChange(of: targetedColumns) { oldValue, newValue in
            if !oldValue.isEmpty && newValue.isEmpty && draggedCardId != nil {
                let dragId = draggedCardId
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if targetedColumns.isEmpty && draggedCardId == dragId {
                        withAnimation(.easeOut(duration: 0.2)) {
                            draggedCardId = nil
                        }
                    }
                }
            }
        }
    }
}

struct ColumnView: View {
    @Bindable var column: Column
    let project: Project
    @Binding var draggedCardId: UUID?
    @Binding var draggedCardHeight: CGFloat
    @Binding var expandedCardId: UUID?
    var onColumnTargetChanged: ((UUID, Bool) -> Void)?
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var isAddingCard = false
    @State private var newCardTitle = ""
    @State private var isDropTargeted = false
    @State private var dropTargetIndex: Int?
    @State private var showDeleteConfirmation = false
    @FocusState private var isNewCardFocused: Bool

    // Column is "active" when EITHER the background is targeted OR a card within is targeted
    private var isColumnActive: Bool {
        isDropTargeted || (dropTargetIndex != nil && draggedCardId != nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            columnHeader
            Divider().padding(.bottom, 8)
            cardScrollArea
        }
        .frame(width: 320)
        .frame(minHeight: 500)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isColumnActive ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.2),
                        lineWidth: isColumnActive ? 3 : 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isColumnActive)
        .onChange(of: isDropTargeted) { _, _ in
            onColumnTargetChanged?(column.id, isColumnActive)
        }
        .onChange(of: dropTargetIndex) { _, _ in
            onColumnTargetChanged?(column.id, isColumnActive)
        }
        .alert("Delete Column", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteColumn() }
        } message: {
            Text("Are you sure you want to delete column \(column.name)?")
        }
    }

    private var columnHeader: some View {
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
                        showDeleteConfirmation = true
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
    }

    private var cardScrollArea: some View {
        ScrollView {
            VStack(spacing: 0) {
                cardList
                endDropZone
                addCardSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
        .frame(maxHeight: .infinity)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onDrop(of: [.text], isTargeted: $isDropTargeted) { _ in
                    handleCardDrop(at: column.cards.count)
                }
        )
    }

    private var cardList: some View {
        ForEach(Array(column.cards.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { index, card in
            if draggedCardId != card.id {
                cardDropTarget(for: card, at: index)
            }
        }
    }

    private func cardDropTarget(for card: Card, at index: Int) -> some View {
        let isCardDropTarget = Binding<Bool>(
            get: { dropTargetIndex == index },
            set: { isTargeted in
                if isTargeted {
                    dropTargetIndex = index
                } else if dropTargetIndex == index {
                    dropTargetIndex = nil
                }
            }
        )

        return DraggableCardView(
            card: card,
            column: column,
            project: project,
            draggedCardId: $draggedCardId,
            draggedCardHeight: $draggedCardHeight,
            expandedCardId: $expandedCardId
        )
        .padding(.bottom, 16)
        .contentShape(Rectangle())
        .onDrop(of: [.text], isTargeted: isCardDropTarget) { _ in
            handleCardDrop(at: index)
        }
        .overlay(alignment: .top) {
            if dropTargetIndex == index && draggedCardId != nil {
                DropIndicatorLine()
                    .offset(y: -10)
            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private var endDropZone: some View {
        if draggedCardId != nil {
            let isEndDropTarget = Binding<Bool>(
                get: { dropTargetIndex == column.cards.count },
                set: { isTargeted in
                    if isTargeted {
                        dropTargetIndex = column.cards.count
                    } else if dropTargetIndex == column.cards.count {
                        dropTargetIndex = nil
                    }
                }
            )

            Rectangle()
                .fill(Color.clear)
                .frame(height: 60)
                .contentShape(Rectangle())
                .onDrop(of: [.text], isTargeted: isEndDropTarget) { _ in
                    handleCardDrop(at: column.cards.count)
                }
                .overlay(alignment: .top) {
                    if dropTargetIndex == column.cards.count {
                        DropIndicatorLine()
                            .offset(y: -4)
                    }
                }
        }
    }

    @ViewBuilder
    private var addCardSection: some View {
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

    private func createCard() {
        guard !newCardTitle.isEmpty else { return }
        let card = Card(title: newCardTitle, order: column.cards.count)
        column.cards.append(card)
        modelContext.insert(card)
        newCardTitle = ""
        isAddingCard = false
    }

    private func deleteColumn() {
        // Move cards to the first (leftmost) column if one exists
        let sortedColumns = project.columns.sorted(by: { $0.order < $1.order })
        let firstColumn = sortedColumns.first(where: { $0.id != column.id })

        if let target = firstColumn {
            for card in column.cards {
                card.order = target.cards.count
                target.cards.append(card)
            }
            // Reorder target column
            for (index, c) in target.cards.enumerated() {
                c.order = index
            }
        }

        if let index = project.columns.firstIndex(where: { $0.id == column.id }) {
            project.columns.remove(at: index)
        }
    }

    private func handleCardDrop(at targetIndex: Int) -> Bool {
        guard let cardId = draggedCardId else { return false }

        for projectColumn in project.columns {
            if let cardIndex = projectColumn.cards.firstIndex(where: { $0.id == cardId }) {
                let card = projectColumn.cards[cardIndex]

                // Remove from old column
                projectColumn.cards.remove(at: cardIndex)

                // If same column, adjust target index if needed
                var adjustedIndex = targetIndex
                if projectColumn.id == column.id && cardIndex < targetIndex {
                    adjustedIndex -= 1
                }

                // Insert at target position (clamped to valid range)
                let safeIndex = min(adjustedIndex, column.cards.count)
                card.order = safeIndex
                column.cards.insert(card, at: safeIndex)

                // Reorder all cards in both columns
                for (index, c) in projectColumn.cards.enumerated() {
                    c.order = index
                }
                for (index, c) in column.cards.enumerated() {
                    c.order = index
                }

                dropTargetIndex = nil
                draggedCardId = nil

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
    @Binding var draggedCardId: UUID?
    @Binding var draggedCardHeight: CGFloat
    @Binding var expandedCardId: UUID?
    @State private var showingEditSheet = false
    @State private var isHovering = false
    @State private var cardHeight: CGFloat = 100

    // Inline editing state
    @State private var isEditingTitle = false
    @State private var isEditingContent = false
    @State private var editedTitle = ""
    @State private var editedContent = ""
    @FocusState private var titleFocused: Bool
    @FocusState private var contentFocused: Bool

    // Inline subtask adding
    @State private var isAddingSubtask = false
    @State private var newSubtaskText = ""
    @FocusState private var subtaskFieldFocused: Bool
    @Environment(\.modelContext) private var modelContext

    var completedSubtasks: Int {
        card.subtasks.filter { $0.isCompleted }.count
    }

    private var isExpanded: Bool {
        expandedCardId == card.id
    }

    var body: some View {
        cardContent
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(nsColor: .controlBackgroundColor))
                        .onAppear { cardHeight = geometry.size.height }
                        .onChange(of: geometry.size.height) { _, newValue in
                            cardHeight = newValue
                        }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isHovering ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.1),
                            lineWidth: isHovering ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            .onHover { isHovering = $0 }
            .onTapGesture {
                if expandedCardId != nil || isAddingSubtask {
                    dismissCardEditing()
                }
            }
            .onDrag {
                draggedCardId = card.id
                draggedCardHeight = cardHeight
                let provider = NSItemProvider(object: card.id.uuidString as NSString)
                provider.suggestedName = card.title
                return provider
            }
            .sheet(isPresented: $showingEditSheet) {
                EditCardSheet(card: card)
            }
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
            .animation(.easeInOut(duration: 0.2), value: isAddingSubtask)
            .onChange(of: expandedCardId) { _, newValue in
                if newValue != card.id {
                    isAddingSubtask = false
                    newSubtaskText = ""
                    isEditingTitle = false
                    isEditingContent = false
                }
            }
            .onChange(of: titleFocused) { _, focused in
                if !focused && isEditingTitle { commitTitleEdit() }
            }
            .onChange(of: contentFocused) { _, focused in
                if !focused && isEditingContent { commitContentEdit() }
            }
            .onChange(of: subtaskFieldFocused) { _, focused in
                if !focused && isAddingSubtask {
                    // Commit any in-progress text before dismissing
                    let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty {
                        let subtask = Subtask(title: trimmed)
                        card.subtasks.append(subtask)
                        modelContext.insert(subtask)
                        newSubtaskText = ""
                    }
                    dismissCardEditing()
                }
            }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with edit button
            HStack(alignment: .top, spacing: 8) {
                titleView
                Spacer()
                Button { showingEditSheet = true } label: {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(isHovering ? 1 : 0.5))
                }
                .buttonStyle(.plain)
            }

            descriptionView
            subtasksView
        }
    }

    @ViewBuilder
    private var subtasksView: some View {
        if isExpanded || isAddingSubtask {
            expandedSubtasksView
            addSubtaskField
        } else if !card.subtasks.isEmpty {
            subtaskSummary
        } else {
            Button {
                isAddingSubtask = true
                subtaskFieldFocused = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.caption2)
                    Text("Add subtasks")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if isEditingTitle {
            TextField("Title", text: $editedTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .textFieldStyle(.plain)
                .focused($titleFocused)
                .onSubmit { commitTitleEdit() }
                .onExitCommand { dismissCardEditing() }
        } else {
            Text(card.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)
                .contentShape(Rectangle())
                .onTapGesture { startEditingTitle() }
        }
    }

    @ViewBuilder
    private var descriptionView: some View {
        if isEditingContent {
            TextField("Description", text: $editedContent)
                .font(.caption)
                .textFieldStyle(.plain)
                .focused($contentFocused)
                .onSubmit { commitContentEdit() }
                .onExitCommand { dismissCardEditing() }
        } else if !card.content.isEmpty {
            Text(card.content)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .contentShape(Rectangle())
                .onTapGesture { startEditingContent() }
        }
    }

    private var subtaskSummary: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(completedSubtasks == card.subtasks.count ? .green : .secondary)
            Text("\(completedSubtasks)/\(card.subtasks.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            expandedCardId = card.id
            isAddingSubtask = true
            subtaskFieldFocused = true
        }
    }

    private var expandedSubtasksView: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(card.subtasks) { subtask in
                HStack(spacing: 8) {
                    Button {
                        subtask.isCompleted.toggle()
                    } label: {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundColor(subtask.isCompleted ? .green : .secondary)
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .font(.caption)
                        .strikethrough(subtask.isCompleted)
                        .foregroundColor(subtask.isCompleted ? .secondary : .primary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var addSubtaskField: some View {
        HStack(spacing: 8) {
            Image(systemName: "circle")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.5))

            TextField("Add a subtask", text: $newSubtaskText)
                .font(.caption)
                .textFieldStyle(.plain)
                .italic()
                .foregroundColor(.secondary)
                .focused($subtaskFieldFocused)
                .onSubmit { commitNewSubtask() }
                .onExitCommand { dismissCardEditing() }
        }
    }

    private func commitNewSubtask() {
        let trimmed = newSubtaskText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            isAddingSubtask = false
            return
        }
        let subtask = Subtask(title: trimmed)
        card.subtasks.append(subtask)
        modelContext.insert(subtask)
        newSubtaskText = ""
        subtaskFieldFocused = true
    }

    private func dismissCardEditing() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isAddingSubtask = false
            expandedCardId = nil
        }
        newSubtaskText = ""
        isEditingTitle = false
        isEditingContent = false
    }

    // MARK: - Inline Editing

    private func startEditingTitle() {
        editedTitle = card.title
        isEditingTitle = true
        titleFocused = true
    }

    private func commitTitleEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            card.title = trimmed
        }
        isEditingTitle = false
    }

    private func cancelTitleEdit() {
        isEditingTitle = false
    }

    private func startEditingContent() {
        editedContent = card.content
        isEditingContent = true
        contentFocused = true
    }

    private func commitContentEdit() {
        card.content = editedContent.trimmingCharacters(in: .whitespaces)
        isEditingContent = false
    }

    private func cancelContentEdit() {
        isEditingContent = false
    }
}

struct DropIndicatorLine: View {
    var body: some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
            Color.accentColor
                .frame(height: 3)
            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 4)
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
            VStack(alignment: .leading, spacing: 24) {
                PlanetarySectionHeader(title: "Column Details", icon: "rectangle.3.group.fill")

                PlanetaryTextField(label: "Name", icon: "tag.fill", text: $columnName)

                Spacer()
            }
            .padding(24)
            .background(Color(nsColor: .windowBackgroundColor))
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
