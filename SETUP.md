# Second Brain — Flutter Setup Guide

## Prerequisites on the build machine
- Flutter SDK >= 3.19 (https://flutter.dev/docs/get-started/install)
- Android Studio (for Android emulator + SDK)
- Xcode (for iOS, Mac only)

## First-time setup

```bash
# 1. Get dependencies
flutter pub get

# 2. Generate Drift database code + Riverpod providers
dart run build_runner build --delete-conflicting-outputs

# 3. Run on emulator / device
flutter run
```

## Project structure
```
lib/
├── main.dart                     # Entry point
├── app.dart                      # Root widget, theme, router
├── core/
│   ├── constants/                # App-wide constants
│   ├── extensions/               # Dart extension methods
│   ├── router/                   # GoRouter setup
│   └── theme/                    # Material 3 theme
├── data/
│   ├── database/                 # Drift DB + tables
│   └── repositories/             # Data access layer (to be built)
├── features/
│   ├── dashboard/                # Home screen
│   ├── tasks/                    # Todo & recurring tasks
│   ├── notes/                    # Notes editor
│   ├── learning/                 # Learning hub
│   ├── entertainment/            # Watchlist & tracker
│   └── knowledge/                # Knowledge vault
└── shared/
    └── widgets/                  # Reusable UI components
```

## Architecture
- **State**: Riverpod (flutter_riverpod)
- **Navigation**: GoRouter
- **Database**: Drift (type-safe SQLite wrapper)
- **Pattern**: Feature-based MVVM

## Next steps to build out
1. Run `dart run build_runner build` to generate `app_database.g.dart`
2. Add DAOs (Data Access Objects) for each table in `lib/data/database/`
3. Add Repositories in `lib/data/repositories/`
4. Wire Riverpod providers to the repositories
5. Build out each feature screen with real data
