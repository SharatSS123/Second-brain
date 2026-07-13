# CORTEX — Project Features Documentation

Cortex is an intelligent personal assistant and "second brain" application built with Flutter, Riverpod, and Drift SQLite for local-first database persistence.

---

## 🚀 Core MVP Features

### 1. Security & Authentication (`auth`)
*   **Secure Access**: Lock screen setup using PIN authentication.
*   **Biometrics**: Support for face/fingerprint authentication via `local_auth`.
*   **Profile Setup**: Initial onboarding and profile configuration.

### 2. Dashboard (`dashboard`)
*   **Unified View**: Displays current active activity, total progress indicators, focus metrics, and today's tasks.
*   **Quick Add**: Easy triggers to add notes or planner items.

### 3. Day Planner (`day`)
*   **Timeline Row**: Hour-by-hour planner timeline displaying routines, activities, categories, and times.
*   **Current Focus**: Highlighted "Now Card" showing progress on the current time-blocked activity.
*   **Day Log**: Quick daily checklists/to-dos.

### 4. Planner & Templates (`planner` / `templates`)
*   **Time Blocking**: Pre-define category blocks throughout the day.
*   **Routines**: Create routine templates (e.g., Morning Routine, Work Routine) and apply them to any day with a single tap.

### 5. Notes Engine (`notes`)
*   **Rich Cards**: Grid/list notes view.
*   **Pinning**: Pin notes to the top of the board.
*   **Search & Sort**: Real-time filtering and sorting (newest, oldest, alphabetical).

### 6. Tasks Management (`tasks`)
*   **Categorized Lists**: Organize tasks by Priority (High, Medium, Low), Due Dates, and status.
*   **Recurrence**: Support recurring task patterns.

### 7. Learning Tracker (`learning`)
*   **Topic Boards**: Define topics and log resources (books, videos, docs) under each subject with progress indicators.

### 8. Entertainment Backlog (`entertainment`)
*   **Media watchlists**: Separate sub-categories to track Movies, TV Series, Anime, and Video Games.

### 9. Books Tracker (`books`)
*   **Personal Library**: Add books and log reading progress (Not Started, Reading, Completed).

### 10. Knowledge Vault (`knowledge`)
*   **Web Resource Saver**: Save references, URLs, articles, and bookmarks with category tags.

---

## 🛠️ Newly Implemented Features & Enhancements

### 11. Lists & Checklists
*   **Dynamic Checklists**: Dedicated space to create checklists (e.g. Packing lists, Grocery Shopping) separate from day logs.
*   **Auto-Seeding**: Automatically pre-populates two checklists ("Shopping 🛒" and "Travel ✈️") with sample items when the database is first initialized.
*   **Full CRUD**: Add, edit, check off, rename, and delete checklists and items.

### 12. Checklist-to-To-Do Integration
*   **Database Linking**: Day To-Dos can associate directly with any custom checklist.
*   **Expandable Cards**: Tapping a Day To-Do card expands it inline, revealing all sub-items with checkboxes.
*   **Inline Progress Toggles**: Tick off sub-items directly on the Day Planner. Progress stats (e.g., `📋 1 of 2 completed`) update instantly in real time using Riverpod streams.

### 13. Smart Carry-Forward
*   **Carry-Forward Queue**: Uncompleted To-Dos from past days are carried forward automatically to the current day's list, ensuring tasks are never forgotten.
*   **Relative Overdue Badges**:
    *   **1 or 2 Days Overdue**: The task card displays an **Amber** border and a `X DAY DUE` pill.
    *   **3+ Days Overdue**: The card displays a **Red** border and a `X DAYS DUE` pill.
*   **Instant Dismiss**: Ticking off an overdue task completes it, moving it out of the active carry-forward view back to its original date's completed log history.

### 14. UI & Form Flow Polish
*   **Responsive "More" Grid**: Redesigned the "More" bottom sheet from a single cramped row to a wrapping grid with exactly 4 icons per row, resolving hidden/truncated text label issues.
*   **Real-Time Button States**: Fixed form button states inside the To-Do creation sheet. The button now dynamically enables and turns green in real time as the user types (no keyboard dismiss required).
*   **Simplified Home Dashboard**: Cleaned up the home dashboard screen by removing the "Later Today" timeline preview, focusing the workspace purely on the Progress Card, active "Now" task, "Up Next" preview, and active "To-Dos" list.
*   **Draggable To-Dos Bottom Sheet**: Replaced the static bottom To-Dos panel with a sliding `DraggableScrollableSheet` overlay. By default, it stays collapsed (occupying only ~75dp at the bottom) showing a clean summary card: "To Do (5) • 3 Remaining • 2 Completed". Dragging it up expands the sheet to reveal a list of tasks with custom checkboxes and drag-to-reorder handles, allowing the timeline to take up 75–80% of the screen.
*   **Swipe Actions & Inline Input**: Swipe left on any task to instantly delete, and swipe right to toggle its completion state. Includes an inline Quick Add text input with a '+' button for adding tasks continuously without leaving focus or changing views.
*   **Header "+" Action Button**: Removed the Floating Action Button (FAB) completely and replaced it with a clean purple "+" button in the App Bar next to the profile avatar to match the lists screen style.
*   **Timeline Auto-Scrolling**: Added automatic context scrolling on loading the Day tab or changing dates. The timeline smoothly scrolls to center the current ongoing activity.
*   **Distraction-Free Focus Mode**: Added an immersive, distraction-free focus session screen for the active activity. The screen is simplified to present only the session title, category label, a giant glowing countdown circular progress timer, and a large "Complete Activity" button at the bottom, removing any checklist or badge distractions.

### 15. Advanced List Manager (Redesigned)
*   **Search & Status Filters**: Filter checklists by "All", "My Lists", and "Shared" categories. Tapping "Shared" displays a "Shared lists coming soon" notification. Search instantly across checklist names in real time.
*   **Categorized List Cards**: Checklists now support selection of custom type categories and icons (Work, Shopping, Travel, Books, Gifts, Home) with rich color styling and automatic icon-mapping.
*   **Quick Add at Top**: Items can be added instantly at the very top of the list via a text field and button placed at the top of the detail screen.
*   **Drag & Drop Reordering**: Uses a custom `ReorderableListView` integration with a dedicated reorder drag handle to easily rearrange list items.
*   **Options Dropdown Menu**: A popup menu button on each item card provides choices to Edit title/notes/priority/dueDate, Mark as done/incomplete, Move to top, Move to bottom, or Delete.
*   **Item Metadata (Priority, Notes, Due Date)**: Items support adding optional descriptive notes, due dates (with date picker), and priority tags (Low, Medium, High) with colored badges.
*   **Completion Footer**: Footer count displays active progress (e.g. `5 of 12 completed`) and a "Clear completed" option to purge ticked items.

### 16. Recurring Activities for Cortex
*   **Recurring Patterns**: Setup activities to repeat in the Day module. Supports Daily, Weekdays, Weekly, Monthly, and Custom repeat intervals (e.g. repeat every X weeks on selected weekdays Mon-Sun) with ends conditions (Never, on Date, or after X occurrences).
*   **Scoped Recurrence Edits & Deletions**: Prompts users with calendar recurrence scopes when editing or deleting recurring activities:
    *   **This activity only**: Creates or deletes a single occurrence exception override for that date.
    *   **This and future activities**: Truncates the current recurrence end date and initiates a new recurrence series starting from that date forward.
    *   **Entire series**: Modifies the properties of the original master series template directly.
*   **Timeline Recurrence Badge**: Timeline rows display a subtle recurrence indicator (e.g., *"Daily"*, *"Every weekday"*, *"Weekly on Mon, Wed"*) underneath the time range.
*   **Virtual Evaluation Engine**: Computes and expands repeating occurrences in memory on streams, dynamically filtering out deleted exceptions and overlaying modified single occurrences.
