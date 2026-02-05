# Taskorium

A lightweight, planetarium-themed project management app for macOS built with SwiftUI and SwiftData.

## Features

### Projects
- Create projects with custom names and descriptions
- Choose from 8 planet types (Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune)
- Each planet has a unique Material Design-inspired color scheme
- Beautiful planet visualizations with gradient effects

### Kanban Board
- Default columns: "To Do", "In Progress", "Done"
- Create custom columns and rename them as needed
- Delete columns when no longer needed
- Drag and drop cards between columns
- Inline card creation - no modals needed for quick task entry

### Cards
- Quick-add cards with just a title using inline creation
- Click cards to edit full details including descriptions
- Add unlimited subtasks to each card
- Check off and edit subtasks directly
- Subtasks get crossed out when completed
- Visual progress indicator showing completed/total subtasks (turns green when all done)
- Edit or delete cards at any time
- Hover effects for better interactivity

### Visual Design
- Planetarium-inspired theme with constellation backgrounds
- Simple, flat constellation designs (Orion, Ursa Major, Cassiopeia, Leo)
- Dark space-themed backgrounds with subtle star fields
- Frosted glass (ultra-thin material) UI elements
- Smooth animations and transitions

## Architecture

### SwiftData Models
- `Project`: Top-level container with name, description, and planet type
- `Column`: Organizing structure within projects
- `Card`: Individual task items with title and content
- `Subtask`: Checkable items within cards

All models use proper relationships with cascade delete rules for data integrity.

### Views
- `ProjectListView`: Grid display of all projects
- `ProjectDetailView`: Kanban board view with columns
- `NewProjectSheet`/`NewCardSheet`/`EditCardSheet`: Modal forms for data entry
- `PlanetView`: Reusable component for planet visualizations
- `ConstellationBackground`: Procedural constellation patterns

## Getting Started

1. Open `taskorium.xcodeproj` in Xcode
2. Build and run the project (⌘R)
3. Create your first project by clicking the "+" button
4. Start organizing your tasks with the kanban board!

## Requirements

- macOS 14.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later
