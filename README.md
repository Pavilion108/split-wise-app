# Split Wise

Offline-first trip expense splitting app built with Flutter.

## Features

- **Offline-first**: Full functionality without internet. Local SQLite storage.
- **Multi-currency**: Foreign currency entry with RBI reference rates. Auto-convert to base currency.
- **Expense splitting**: Equal split (all members) or custom split (chosen subset).
- **Balance tracking**: Real-time per-member balance with settlement suggestions.
- **Partial payments**: Support partial settlement of balances.
- **UPI integration**: Deep-link to UPI apps with pre-filled amounts.
- **CRDT sync**: Conflict-free replicated data types for multi-device sync.
- **Notifications**: Local notifications for new expenses and corrections.

## Architecture

```
lib/
├── core/           # Database, sync, theme, constants
├── models/         # Pure Dart data classes
├── services/       # Business logic (balance engine, split calculator)
├── repositories/   # Data access layer
├── providers/      # Riverpod dependency injection
└── ui/             # Screens and widgets
```

## Tech Stack

- **Flutter** (cross-platform)
- **Drift** (SQLite ORM)
- **Riverpod** (state management)
- **CRDT** (conflict-free sync)

## Getting Started

```bash
flutter pub get
flutter pub run build_runner build
flutter test
flutter run
```

## Testing

```bash
flutter test
```

12 unit tests covering balance engine, split calculator, and settlement suggestions.
