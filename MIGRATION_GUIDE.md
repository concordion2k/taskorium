# SwiftData Migration Guide

If you're experiencing a schema migration error when running the app, you have two options:

## Option 1: Delete the SwiftData Store (Quick Fix)

This will clear all existing data and start fresh with the new schema:

1. Quit the app if it's running
2. Open Finder
3. Press `Cmd + Shift + G` to open "Go to Folder"
4. Paste this path: `~/Library/Containers/com.yourname.taskorium/Data/Library/Application Support/`
5. Delete the `default.store` file (or any `.store` files you see)
6. Relaunch the app

## Option 2: Manual Migration (Preserve Data)

If you have existing data you want to keep:

The app now includes automatic migration code that should handle the new `order` property on Projects. If you're still seeing errors:

1. The issue is that SwiftData detected a schema change (we added the `order` property to Project)
2. For development, it's easiest to just delete the store (Option 1)
3. For production apps, you'd want to implement proper VersionedSchema and MigrationPlan

## What Changed

We added an `order: Int` property to the `Project` model to support drag-and-drop reordering in the sidebar. This is a non-destructive change (it has a default value of 0), so the automatic migration should work in most cases.

## Finding Your App's Container

If the path above doesn't work, you can find your app's container by:

1. Running the app
2. Adding this temporary code somewhere:
   ```swift
   print(FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!)
   ```
3. Check the console output for the actual path
4. Delete the `.store` files from that location
