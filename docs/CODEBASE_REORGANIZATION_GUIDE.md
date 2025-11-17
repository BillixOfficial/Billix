# Billix iOS App - Codebase Reorganization Guide

**Date Created:** November 16, 2025
**Estimated Time:** 2-3 hours
**Risk Level:** Medium (requires Xcode project updates)
**Approach:** Option A - Manual Xcode Method (Safest)

---

## Table of Contents
1. [Overview](#overview)
2. [Before You Start](#before-you-start)
3. [Phase 1: Delete Duplicate Files](#phase-1-delete-duplicate-files)
4. [Phase 2: Create Core Folder Structure](#phase-2-create-core-folder-structure)
5. [Phase 3: Move Files to Core](#phase-3-move-files-to-core)
6. [Phase 4: Consolidate Views into Features](#phase-4-consolidate-views-into-features)
5. [Phase 5: Update Xcode Project](#phase-5-update-xcode-project)
6. [Phase 6: Clean Up Empty Folders](#phase-6-clean-up-empty-folders)
7. [Phase 7: Build & Test](#phase-7-build--test)
8. [Troubleshooting](#troubleshooting)
9. [Rollback Procedure](#rollback-procedure)

---

## Overview

### Current Problems
- **7 duplicate files** in root directory causing confusion
- Mixed organizational patterns (feature-based + type-based)
- Views scattered across multiple folders
- ViewModel separated from its feature

### Goal
Transform the codebase to follow **2024-2025 iOS best practices**:
- Feature-based organization for scalability
- Core/ folder for shared business logic
- Clean separation of concerns
- Easier navigation and maintenance

### Before & After Structure

**BEFORE:**
```
Billix/
├── App/
├── Features/
├── Models/
├── Services/
├── Utilities/
├── ViewModels/
├── Views/
└── [6 duplicate files in root]
```

**AFTER:**
```
Billix/
├── App/
├── Features/
│   └── Upload/ (consolidated)
└── Core/
    ├── Models/
    ├── Services/
    └── Utilities/
```

---

## Before You Start

### Prerequisites
✅ Xcode installed and updated
✅ Git repository with clean working directory
✅ All pending changes committed
✅ 2-3 hours of uninterrupted time
✅ Backup created (optional but recommended)

### Create a Backup Branch
```bash
cd /Users/jg_2030/Billix
git checkout -b feature/codebase-reorganization
git add .
git commit -m "Checkpoint before reorganization"
```

### Important Notes
- ⚠️ **DO NOT** rename files in Finder while Xcode is open
- ✅ **DO** work in Xcode's Project Navigator for file operations
- 💾 **Save frequently** - use Cmd+S often
- 🧪 **Test after each phase** - build and run the app

---

## Phase 1: Delete Duplicate Files

**Goal:** Remove 7 duplicate/unused files from root directory

### Files to Delete

| # | File Path | Reason | Has Duplicate In |
|---|-----------|--------|------------------|
| 1 | `Billix/APIClient.swift` | Duplicate | `Services/APIClient.swift` |
| 2 | `Billix/BillAnalysis.swift` | Duplicate | `Models/BillAnalysis.swift` |
| 3 | `Billix/Config.swift` | Duplicate | `Services/Config.swift` |
| 4 | `Billix/FileValidator.swift` | Duplicate | `Utilities/FileValidator.swift` |
| 5 | `Billix/StoredBill.swift` | Duplicate | `Models/StoredBill.swift` |
| 6 | `Billix/SupabaseService.swift` | Duplicate | `Services/SupabaseService.swift` |
| 7 | `Billix/Models/Item.swift` | Unused template | N/A |

### Steps

1. **Open Xcode**
   ```bash
   open Billix.xcodeproj
   ```

2. **In Project Navigator (left sidebar):**
   - Expand the "Billix" group (not the top-level project)
   - You should see loose files at the root level

3. **For each duplicate file (1-6):**
   - Right-click on the file → **"Delete"**
   - In the dialog, select **"Move to Trash"** (not just "Remove Reference")
   - This deletes both the Xcode reference AND the file on disk

4. **Delete Item.swift:**
   - Navigate to `Models` folder in Project Navigator
   - Right-click `Item.swift` → **"Delete"** → **"Move to Trash"**

5. **Verify in Terminal:**
   ```bash
   # These files should NOT exist anymore:
   ls Billix/APIClient.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/BillAnalysis.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/Config.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/FileValidator.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/StoredBill.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/SupabaseService.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls Billix/Models/Item.swift 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ```

6. **Build to test (Cmd+B)**
   - Should build successfully
   - If errors appear about missing files, you may have deleted the wrong version

### Checkpoint 1
✅ 7 files deleted
✅ Project builds successfully
✅ No compiler errors

---

## Phase 2: Create Core Folder Structure

**Goal:** Create the Core/ folder with subfolders

### Steps

1. **In Finder (NOT Xcode yet):**
   ```bash
   cd /Users/jg_2030/Billix
   mkdir -p Billix/Core/Models
   mkdir -p Billix/Core/Services
   mkdir -p Billix/Core/Utilities
   ```

2. **In Xcode Project Navigator:**
   - Right-click on the "Billix" group → **"New Group"**
   - Name it: `Core`

3. **Create subgroups inside Core:**
   - Right-click on "Core" → **"New Group"** → Name: `Models`
   - Right-click on "Core" → **"New Group"** → Name: `Services`
   - Right-click on "Core" → **"New Group"** → Name: `Utilities`

4. **Verify structure in Xcode:**
   ```
   Billix
   ├── App
   ├── Core
   │   ├── Models
   │   ├── Services
   │   └── Utilities
   ├── Features
   ├── Models (old - will be deleted later)
   ├── Services (old - will be deleted later)
   └── Utilities (old - will be deleted later)
   ```

### Checkpoint 2
✅ Core/ folder created in file system
✅ Core/ group created in Xcode
✅ 3 subgroups created (Models, Services, Utilities)

---

## Phase 3: Move Files to Core

**Goal:** Move shared business logic files into Core/

### Files to Move (7 total)

#### From Models/ to Core/Models/
1. `Models/BillAnalysis.swift` → `Core/Models/BillAnalysis.swift`
2. `Models/StoredBill.swift` → `Core/Models/StoredBill.swift`

#### From Services/ to Core/Services/
3. `Services/APIClient.swift` → `Core/Services/APIClient.swift`
4. `Services/Config.swift` → `Core/Services/Config.swift`
5. `Services/SupabaseService.swift` → `Core/Services/SupabaseService.swift`

#### From Utilities/ to Core/Utilities/
6. `Utilities/FileValidator.swift` → `Core/Utilities/FileValidator.swift`
7. `Utilities/ColorPalette.swift` → `Core/Utilities/ColorPalette.swift`

### Steps (Repeat for Each File)

**IMPORTANT:** Do this in Xcode, not Finder!

1. **In Xcode Project Navigator:**
   - Find the file in its current location (e.g., `Models/BillAnalysis.swift`)
   - **Drag and drop** it to the new location (e.g., `Core/Models/`)
   - Xcode will automatically update the file path

2. **Alternative method (if dragging doesn't work):**
   - Right-click file → **"Show in Finder"**
   - In Finder, drag file to new Core/* folder
   - Back in Xcode, the file will turn red (missing)
   - Right-click red file → **"Delete"** → **"Remove Reference"** (NOT "Move to Trash")
   - Right-click destination folder in Xcode → **"Add Files to Billix..."**
   - Select the file from its new location → **"Add"**

3. **Verify each move:**
   - File appears in new location in Xcode
   - File is NOT red (missing)
   - Old folder doesn't have the file anymore

### File-by-File Checklist

- [ ] BillAnalysis.swift → Core/Models/
- [ ] StoredBill.swift → Core/Models/
- [ ] APIClient.swift → Core/Services/
- [ ] Config.swift → Core/Services/
- [ ] SupabaseService.swift → Core/Services/
- [ ] FileValidator.swift → Core/Utilities/
- [ ] ColorPalette.swift → Core/Utilities/

### Checkpoint 3
✅ All 7 files moved to Core/*
✅ No red (missing) files in Xcode
✅ Old folders (Models, Services, Utilities) are now empty

---

## Phase 4: Consolidate Views into Features

**Goal:** Move all upload-related views into Features/Upload/

### Files to Move (6 total)

#### To Features/Upload/Components/
1. `Views/Camera/CameraPicker.swift` → `Features/Upload/Components/CameraPicker.swift`
2. `Views/DocumentPicker/DocumentPickerView.swift` → `Features/Upload/Components/DocumentPickerView.swift`
3. `Views/PhotoPicker/PhotoPickerView.swift` → `Features/Upload/Components/PhotoPickerView.swift`

#### To Features/Upload/ (root level)
4. `Views/Upload/ErrorView.swift` → `Features/Upload/ErrorView.swift`
5. `Views/Upload/UploadProgressView.swift` → `Features/Upload/UploadProgressView.swift`
6. `ViewModels/UploadViewModel.swift` → `Features/Upload/UploadViewModel.swift`

### Steps

1. **Ensure Components folder exists:**
   - In Xcode, navigate to `Features/Upload/`
   - Verify `Components` group exists
   - If not, create it: Right-click `Upload` → **"New Group"** → Name: `Components`

2. **Move each file using drag & drop in Xcode:**
   - Find file in current location
   - Drag to new location
   - Xcode updates paths automatically

3. **Verify structure:**
   ```
   Features/Upload/
   ├── UploadView.swift
   ├── UploadViewModel.swift (MOVED from ViewModels/)
   ├── AnalysisResultsView.swift
   ├── ErrorView.swift (MOVED from Views/Upload/)
   ├── UploadProgressView.swift (MOVED from Views/Upload/)
   └── Components/
       ├── AnimatedHeroHeader.swift
       ├── CameraPicker.swift (MOVED from Views/Camera/)
       ├── CircularProgressView.swift
       ├── ConfettiView.swift
       ├── DocumentPickerView.swift (MOVED from Views/DocumentPicker/)
       ├── DocumentScannerView.swift
       ├── DragDropZone.swift
       ├── GlassmorphicUploadButton.swift
       ├── InsightsCards.swift
       ├── KeyFactsGrid.swift
       ├── LineItemsList.swift
       ├── MarketplaceCard.swift
       └── PhotoPickerView.swift (MOVED from Views/PhotoPicker/)
   ```

### File-by-File Checklist

- [ ] CameraPicker.swift → Features/Upload/Components/
- [ ] DocumentPickerView.swift → Features/Upload/Components/
- [ ] PhotoPickerView.swift → Features/Upload/Components/
- [ ] ErrorView.swift → Features/Upload/
- [ ] UploadProgressView.swift → Features/Upload/
- [ ] UploadViewModel.swift → Features/Upload/

### Checkpoint 4
✅ All 6 files moved to Features/Upload/
✅ Components folder contains all component files
✅ Views/ and ViewModels/ folders are now empty

---

## Phase 5: Update Xcode Project

**Goal:** Ensure Xcode project file is correctly updated

### Steps

1. **The moves in Xcode should have auto-updated the project**
   - But let's verify everything is correct

2. **Build the project (Cmd+B)**
   - Look for any "file not found" errors
   - Look for any red files in Project Navigator

3. **If you see red (missing) files:**
   - Right-click red file → **"Delete"** → **"Remove Reference"**
   - Find the file in Finder (it should be in its new location)
   - Right-click the destination group in Xcode → **"Add Files to Billix..."**
   - Select the file → **"Add"**

4. **Verify target membership:**
   - Select any moved file in Project Navigator
   - Open File Inspector (right sidebar, Cmd+Opt+1)
   - Under "Target Membership", ensure "Billix" is checked

### Checkpoint 5
✅ Project builds without errors
✅ No red files in Project Navigator
✅ All files have correct target membership

---

## Phase 6: Clean Up Empty Folders

**Goal:** Remove old empty folders

### Folders to Delete (5 total)

1. `Billix/Models/` (now empty)
2. `Billix/Services/` (now empty)
3. `Billix/Utilities/` (now empty)
4. `Billix/Views/` (and all subdirectories - now empty)
5. `Billix/ViewModels/` (now empty)

### Steps

1. **In Xcode Project Navigator:**
   - Right-click `Models` group → **"Delete"** → **"Move to Trash"**
   - Right-click `Services` group → **"Delete"** → **"Move to Trash"**
   - Right-click `Utilities` group → **"Delete"** → **"Move to Trash"**
   - Right-click `Views` group → **"Delete"** → **"Move to Trash"**
   - Right-click `ViewModels` group → **"Delete"** → **"Move to Trash"**

2. **Verify in Finder:**
   ```bash
   # These folders should NOT exist:
   ls -d Billix/Models 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls -d Billix/Services 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls -d Billix/Utilities 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls -d Billix/Views 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ls -d Billix/ViewModels 2>/dev/null && echo "❌ Still exists" || echo "✅ Deleted"
   ```

### Checkpoint 6
✅ All 5 empty folders deleted
✅ Clean folder structure in Xcode
✅ No orphaned folders on disk

---

## Phase 7: Build & Test

**Goal:** Verify everything works

### Steps

1. **Clean Build Folder**
   - In Xcode: **Product → Clean Build Folder** (Cmd+Shift+K)

2. **Build the project**
   - **Product → Build** (Cmd+B)
   - Should compile with **0 errors, 0 warnings**

3. **Run in Simulator**
   ```bash
   # Or use Xcode: Product → Run (Cmd+R)
   xcrun simctl boot "iPhone 16e"
   open -a Simulator
   ```

4. **Test all features:**
   - [ ] App launches successfully
   - [ ] Login screen works
   - [ ] Navigate to all tabs (Home, Upload, Health, Explore, Profile)
   - [ ] Upload screen displays correctly
   - [ ] Try scanning a document
   - [ ] Try choosing from photos
   - [ ] Try browsing files
   - [ ] Verify upload flow works end-to-end

5. **Check for runtime errors:**
   - Monitor Xcode console for any errors
   - Test edge cases

### Checkpoint 7 (Final)
✅ Project builds successfully
✅ App runs without crashes
✅ All features work as expected
✅ No console errors

---

## Final Verification

### Verify Final Structure

Run this command to see your new structure:
```bash
cd /Users/jg_2030/Billix
tree -L 3 -I 'xcuserdata|Preview Content|Assets.xcassets|DerivedData' Billix/
```

**Expected output:**
```
Billix/
├── App
│   ├── BillixApp.swift
│   ├── ContentView.swift
│   └── MainTabView.swift
├── Core
│   ├── Models
│   │   ├── BillAnalysis.swift
│   │   └── StoredBill.swift
│   ├── Services
│   │   ├── APIClient.swift
│   │   ├── Config.swift
│   │   └── SupabaseService.swift
│   └── Utilities
│       ├── ColorPalette.swift
│       └── FileValidator.swift
└── Features
    ├── Auth
    │   └── LoginView.swift
    ├── Explore
    │   └── ExploreView.swift
    ├── Health
    │   └── HealthView.swift
    ├── Home
    │   └── HomeView.swift
    ├── Profile
    │   └── ProfileView.swift
    └── Upload
        ├── AnalysisResultsView.swift
        ├── ErrorView.swift
        ├── UploadProgressView.swift
        ├── UploadView.swift
        ├── UploadViewModel.swift
        └── Components
            ├── AnimatedHeroHeader.swift
            ├── CameraPicker.swift
            ├── CircularProgressView.swift
            ├── ConfettiView.swift
            ├── DocumentPickerView.swift
            ├── DocumentScannerView.swift
            ├── DragDropZone.swift
            ├── GlassmorphicUploadButton.swift
            ├── InsightsCards.swift
            ├── KeyFactsGrid.swift
            ├── LineItemsList.swift
            ├── MarketplaceCard.swift
            └── PhotoPickerView.swift
```

---

## Troubleshooting

### Problem: Files show as red (missing) in Xcode

**Solution:**
1. Right-click red file → **"Show in Finder"**
2. Note the actual file location
3. In Xcode, right-click red file → **"Delete"** → **"Remove Reference"**
4. Right-click destination group → **"Add Files to Billix..."**
5. Navigate to file location → Select file → **"Add"**

### Problem: Build errors about missing imports

**Solution:**
- The file paths haven't changed in imports - Swift imports by module, not file path
- If you see `import Billix`, that's fine
- Most imports should be for system frameworks (SwiftUI, SwiftData, etc.)

### Problem: Xcode groups don't match file system

**Solution:**
1. In Xcode Project Navigator, select a group
2. Open File Inspector (Cmd+Opt+1)
3. Check the "Location" path
4. If it's wrong, click the folder icon and select the correct folder

### Problem: Duplicate file errors during build

**Solution:**
- Check that you deleted all duplicates from Phase 1
- Look in Xcode's "Compile Sources" build phase:
  - Select project in Navigator
  - Select "Billix" target
  - Go to "Build Phases" tab
  - Expand "Compile Sources"
  - Look for duplicate entries
  - Remove duplicates

### Problem: App crashes on launch

**Solution:**
1. Check Xcode console for error messages
2. Look for file path issues
3. Verify all files are in the Billix target
4. Clean build folder (Cmd+Shift+K) and rebuild

---

## Rollback Procedure

If something goes wrong and you need to undo:

### Option 1: Git Reset (Easiest)
```bash
cd /Users/jg_2030/Billix
git reset --hard HEAD
git clean -fd
```

### Option 2: Restore from Backup Branch
```bash
cd /Users/jg_2030/Billix
git checkout main  # or your original branch
git branch -D feature/codebase-reorganization
```

### Option 3: Manual Xcode Project Restore
1. Close Xcode
2. In Finder, navigate to project folder
3. Right-click `Billix.xcodeproj` → **"Show Package Contents"**
4. Replace `project.pbxproj` with your backup copy
5. Reopen Xcode

---

## Commit Your Work

Once everything is working:

```bash
cd /Users/jg_2030/Billix
git add .
git status  # Review changes
git commit -m "Reorganize codebase following iOS best practices

- Delete duplicate files from root directory
- Create Core/ folder for shared business logic
- Move Models, Services, Utilities into Core/
- Consolidate Views into Features/Upload/
- Move UploadViewModel to Features/Upload/
- Clean up empty folders
- Follows feature-based organization pattern"
```

---

## Post-Reorganization Benefits

✅ **Improved Navigation** - Related files are now grouped together
✅ **Scalability** - Easier to add new features
✅ **Team Collaboration** - Fewer merge conflicts
✅ **Maintainability** - Clear separation of concerns
✅ **Industry Standard** - Follows 2024-2025 iOS best practices
✅ **Clean Architecture** - Presentation (Features) + Core (Business Logic)

---

## Next Steps (Future Enhancements)

After this reorganization, consider:

1. **Add ViewModels to other features:**
   - Create `HomeViewModel.swift` in `Features/Home/`
   - Create `HealthViewModel.swift` in `Features/Health/`
   - Create `ExploreViewModel.swift` in `Features/Explore/`
   - Create `ProfileViewModel.swift` in `Features/Profile/`

2. **Add Extensions folder:**
   - Create `Core/Extensions/`
   - Add Swift extensions for common types

3. **Add Common Components:**
   - Create `Common/Components/` for reusable UI components
   - Move truly shared components there

4. **Add Unit Tests:**
   - Follow the same structure in Tests target
   - `BillixTests/Features/Upload/`
   - `BillixTests/Core/Models/`

5. **Documentation:**
   - Add README.md files in each feature folder
   - Document architecture decisions

---

## Questions or Issues?

If you encounter problems:
1. Check the Troubleshooting section
2. Use the Rollback Procedure if needed
3. Consult the Xcode documentation
4. The reorganization can be done incrementally - you can pause after any phase

**Good luck with the reorganization tomorrow! 🚀**

---

*Generated: November 16, 2025*
*Billix iOS App v1.0*
