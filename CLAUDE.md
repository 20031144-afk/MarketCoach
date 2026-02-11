# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MarketCoach is a Flutter-based financial analysis mobile application that provides market insights, educational content, and portfolio tracking. The app integrates with Firebase for backend services (Authentication, Firestore) and displays real-time market data, news, and learning resources.

**Target Platforms**: Android, iOS, macOS, Windows
**Package**: `com.finance.coach`

## Development Commands

### Running the App
```bash
# Run on connected device/simulator
flutter run

# Run on specific device
flutter run -d <device-id>

# Run with hot reload enabled (default)
flutter run --hot

# Build and run in release mode
flutter run --release
```

### Building
```bash
# Build APK (Android)
flutter build apk

# Build App Bundle (Android - for Play Store)
flutter build appbundle

# Build iOS
flutter build ios

# Build for macOS
flutter build macos

# Build for Windows
flutter build windows
```

### Testing & Quality
```bash
# Run tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run analyzer (lint)
flutter analyze

# Format code
flutter format lib/

# Check for outdated packages
flutter pub outdated
```

### Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Clean build artifacts
flutter clean
```

### Firestore Data Import
```bash
# Import lessons to Firestore (requires serviceAccountKey.json)
npm run import-lessons

# Import custom lesson file
node scripts/import_lessons.js path/to/lesson.json
```

**Setup**: Download service account key from Firebase Console → Project Settings → Service Accounts and save as `serviceAccountKey.json` in project root.

## Architecture

### Project Structure

```
lib/
├── app/                    # Application-level widgets & shell
│   ├── market_coach_app.dart   # Root MaterialApp with theme
│   └── root_shell.dart         # Bottom navigation shell
├── data/                   # Data layer
│   ├── firestore_service.dart  # Firebase Firestore operations
│   └── mock_data.dart          # Static mock data for development
├── models/                 # Data models (plain Dart classes)
│   ├── analysis_highlight.dart
│   ├── candle.dart
│   ├── lesson.dart
│   ├── lesson_screen.dart      # Individual lesson screen content
│   ├── market_index.dart
│   ├── news_item.dart
│   ├── quote.dart
│   └── stock_summary.dart
├── providers/              # Riverpod providers for state management
│   ├── firebase_provider.dart
│   ├── firestore_service_provider.dart
│   └── lesson_provider.dart    # Lesson + screens data provider
├── screens/               # Feature screens (one directory per screen)
│   ├── analysis/
│   ├── home/
│   ├── learn/
│   ├── lesson_detail/
│   ├── market/
│   ├── news/
│   ├── profile/
│   └── stock_detail/
├── services/              # External API services
│   ├── candle_service.dart
│   └── quote_service.dart
├── utils/                 # Utility functions
│   └── crypto_helper.dart
├── widgets/               # Reusable widgets
│   ├── glass_card.dart         # Glassmorphic card widget
│   ├── lesson_screen_widget.dart  # Renders lesson screen types
│   └── live_line_chart.dart
├── firebase_options.dart  # Generated Firebase config
└── main.dart             # App entry point
```

### Navigation Architecture

The app uses a **bottom navigation bar shell** (`RootShell`) with 6 main tabs:
1. Home - Dashboard with watchlist and market overview
2. Market - Market data and indices
3. Learn - Educational lessons and resources
4. Analysis - Market analysis and insights
5. News - Financial news feed
6. Profile - User profile and settings

Navigation between detail screens uses standard `Navigator.push()` with `MaterialPageRoute`.

### Data Flow

- **Mock Data**: Static mock data from `lib/data/mock_data.dart` for UI development
- **Firebase Integration**:
  - `FirestoreService` provides methods to read/write learning content and market data
  - Supports both one-time reads (`fetchLesson`, `fetchLessonScreens`) and real-time streams via `snapshots()`
  - Collections: `lessons`, `learning`, `market_data`
  - **Lessons Structure**:
    - Lesson metadata: `lessons/{lessonId}`
    - Lesson screens: `lessons/{lessonId}/screens/{screenId}` (ordered by `order` field)
- **State Management**:
  - **Riverpod**: Used for lesson data (`lessonProvider`, `firestoreServiceProvider`)
  - **StatefulWidget/ConsumerWidget**: Mixed approach - Riverpod for complex data fetching, StatefulWidget for local UI state
  - **StreamBuilder**: Used directly in some screens (e.g., `LearnScreen`) for real-time Firestore updates

### Theme & Styling

- **Material 3**: Uses Material Design 3 with dark theme
- **Color Scheme**: Seed color `#12A28C` (teal/green accent)
- **Background**: Dark background `#0D131A` with card color `#111925`
- **Typography**: White Mountain View typography with white text

## Firebase Setup

### Configuration Files
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`
- Generated options: `lib/firebase_options.dart` (via `flutterfire configure`)

### Initialization
Firebase is initialized in `main.dart` before running the app:
```dart
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
```

### Re-generating Firebase Config
If Firebase configuration changes:
```bash
# Install FlutterFire CLI if not already installed
dart pub global activate flutterfire_cli

# Regenerate config
flutterfire configure
```

## Models

All models are simple Dart classes with `fromMap` factory constructors for Firestore deserialization:

- **Lesson**: Educational content metadata (title, subtitle, duration, level, body)
- **LessonScreen**: Individual lesson screen content with type-based rendering
  - Types: `intro`, `text`, `diagram`, `quiz_single`, `bullets`, `takeaways`
  - Each type has specific content fields in the `content` map
- **StockSummary**: Represents stock/crypto with price, fundamentals, and technical highlights
- **MarketIndex**: Index ticker, name, value, and change percentage
- **NewsItem**: News article with title, source, timestamp, summary, and sentiment
- **AnalysisHighlight**: Market analysis with title, subtitle, tag, confidence, and body
- **Quote**: Real-time stock quote data
- **Candle**: OHLCV candlestick data

### Important Model Patterns

**Timestamp Handling**: Firestore returns `Timestamp` objects, not integers. Use safe parsing:
```dart
static DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
```

Models use constructors with named parameters and computed getters where appropriate (e.g., `StockSummary.isPositive`).

## Key Patterns

### Screen Organization
Each screen directory contains:
- Main screen file (e.g., `home_screen.dart`)
- Private widgets prefixed with underscore (e.g., `_LiveMarketCard`)
- Related child screens if applicable

### Navigation Pattern
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => DetailScreen(data: data)),
);
```

### Firebase Streams
```dart
// Real-time updates
_db.collection('lessons')
   .orderBy('published_at', descending: true)
   .snapshots();

// Document-specific stream
_db.collection('market_data')
   .doc(symbol)
   .snapshots();
```

### Riverpod Provider Pattern
```dart
// Service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final db = ref.watch(firebaseProvider);
  return FirestoreService(db);
});

// Data provider with family modifier for parameters
final lessonProvider = FutureProvider.family<LessonWithScreens, String>((ref, lessonId) async {
  final service = ref.watch(firestoreServiceProvider);
  // Fetch data...
  return LessonWithScreens(lesson: lesson, screens: screens);
});

// Usage in ConsumerWidget
final lessonData = ref.watch(lessonProvider(lessonId));
```

### StreamBuilder in CustomScrollView

**Critical Pattern**: When using `StreamBuilder` with `CustomScrollView`, wrap the entire `CustomScrollView` with `StreamBuilder`, not individual slivers. Build the slivers list conditionally inside the builder:

```dart
StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
  builder: (context, snapshot) {
    final List<Widget> slivers = [
      // Always include header
      SliverToBoxAdapter(child: Header()),
    ];

    // Conditionally add content slivers
    if (snapshot.hasError) {
      slivers.add(SliverToBoxAdapter(child: ErrorWidget()));
    } else if (snapshot.connectionState == ConnectionState.waiting) {
      slivers.add(SliverToBoxAdapter(child: LoadingWidget()));
    } else {
      slivers.add(SliverList(...));  // Actual data
    }

    return CustomScrollView(slivers: slivers);
  },
)
```

**Why**: Embedding `StreamBuilder` directly in the slivers list causes `RenderViewport expected RenderSliver` errors and GlobalKey conflicts.

## Platform-Specific Notes

### Android
- Min SDK: 24 (Android 7.0)
- Target SDK: 34
- Application ID: `com.finance.coach`
- Multidex enabled

### Dependencies
- **firebase_core** `^4.4.0`: Firebase initialization
- **firebase_auth** `^6.1.4`: Authentication (ready for future use)
- **cloud_firestore** `^6.1.2`: Firestore database
- **flutter_riverpod** `^2.0.6`: State management for data providers
- **provider** `^6.0.5`: Alternative state management (legacy, prefer Riverpod)
- **http** `^1.2.2`: HTTP client for REST APIs
- **web_socket_channel** `^3.0.1`: WebSocket connections
- **syncfusion_flutter_charts** `^28.1.33`: Charting library
- **shared_preferences** `^2.3.3`: Local key-value storage

## Lesson System Architecture

The app has a complete lesson delivery system with interactive content:

### Lesson Flow
1. **LearnScreen** (`lib/screens/learn/learn_screen.dart`):
   - Displays list of lessons from Firestore using `StreamBuilder`
   - Real-time updates when new lessons are added
   - Tapping a lesson navigates to `LessonDetailScreen`

2. **LessonDetailScreen** (`lib/screens/lesson_detail/lesson_detail_screen.dart`):
   - Uses Riverpod `lessonProvider` to fetch lesson + screens
   - Renders screens in a `PageView` with navigation controls
   - Each screen type rendered by `LessonScreenWidget`

3. **LessonScreenWidget** (`lib/widgets/lesson_screen_widget.dart`):
   - Type-based rendering: intro, text, diagram, quiz_single, bullets, takeaways
   - Stateful quiz screens with answer checking
   - Extracts content from `content` map based on screen type

### Lesson Data Structure

**Firestore Schema**:
```
lessons/{lessonId}
  - title: string
  - subtitle: string
  - level: string (Beginner/Intermediate/Advanced)
  - minutes: int
  - body: string
  - published_at: Timestamp
  - type: string (optional)

lessons/{lessonId}/screens/{screenId}
  - type: string (intro|text|diagram|quiz_single|bullets|takeaways)
  - order: int (determines display order)
  - title: string (optional)
  - subtitle: string (optional)
  - content: map (type-specific fields)
```

### Screen Type Content Fields

- **intro**: `icon` (string)
- **text**: `body` (string)
- **diagram**: `imageUrl` (string), `caption` (string)
- **quiz_single**: `question` (string), `options` (array), `correctIndex` (int), `explanation` (string)
- **bullets**: `items` (array of strings)
- **takeaways**: `items` (array of strings)

## Lesson Progress Tracking

The app tracks user progress through lessons using Firestore with real-time updates.

### Firestore Schema

```
users/{userId}/lesson_progress/{lessonId}
  - lesson_id: string
  - user_id: string
  - current_screen: int (0-indexed, last viewed screen)
  - total_screens: int
  - completed: bool
  - last_accessed_at: Timestamp
  - completed_at: Timestamp | null

users/{userId}/bookmarks/{lessonId}
  - lesson_id: string
  - user_id: string
  - created_at: Timestamp
```

### Providers

- **`lessonProgressProvider(lessonId)`**: StreamProvider for real-time progress updates on a single lesson
- **`allProgressProvider`**: StreamProvider for all lesson progress records for the current user
- **`bookmarksProvider`**: StreamProvider for bookmarked lesson IDs

### Progress States

- **Not Started**: `current_screen == 0 && !completed`
- **In Progress**: `current_screen > 0 && !completed`
- **Completed**: `completed == true`

### User Features

- **Progress Tracking**: Automatically saves progress as users navigate through lesson screens
- **Bookmarking**: Users can bookmark lessons for quick access via the bookmark icon in LessonDetailScreen
- **Search**: Search lessons by title or subtitle
- **Filters**:
  - **Status**: All, Bookmarked, Completed, In Progress, Not Started
  - **Level**: All, Beginner, Intermediate, Advanced
- **Offline Support**: Firestore persistence enabled - lessons cached automatically for offline viewing
- **Visual Indicators**:
  - Green checkmark on completed lessons
  - Circular progress indicator on in-progress lessons
  - Progress percentage shown in lesson card
  - Offline banner when no network connection

### Adding New Screen Types

To add a new lesson screen type:

1. Add type constant to `LessonScreen` model (lib/models/lesson_screen.dart)
2. Create new widget method in `lesson_screen_widget.dart` (e.g., `_buildVideoScreen`)
3. Add case to switch statement in `LessonScreenWidget.build()`
4. Document content structure in method comment
5. Add to seed data JSON schema for import script

Example:
```dart
case 'video':
  return _buildVideoScreen(screen);

Widget _buildVideoScreen(LessonScreen screen) {
  final videoUrl = screen.content['video_url'] as String?;
  final caption = screen.content['caption'] as String?;

  return Column(
    children: [
      VideoPlayer(url: videoUrl),
      if (caption != null) Text(caption),
    ],
  );
}
```

### Testing Guidelines

#### Running Tests
```bash
flutter test                    # All tests
flutter test test/models/       # Model tests only
flutter test test/widgets/      # Widget tests only
flutter test --coverage         # With coverage report
```

#### Mock Firestore
Use `fake_cloud_firestore` for testing Firestore operations:
```dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

final firestore = FakeFirebaseFirestore();
final service = FirestoreService(firestore);

// Seed test data
await firestore.collection('lessons').doc('test-lesson').set({
  'title': 'Test Lesson',
  'subtitle': 'Test subtitle',
  // ...
});

// Test methods
final lesson = await service.fetchLesson('test-lesson');
expect(lesson?.title, 'Test Lesson');
```

## Development Notes

- **Lesson System**: Fully integrated with Firestore with progress tracking and bookmarking - use `npm run import-lessons` to add content
- **Mixed State Management**: Riverpod for data providers, StatefulWidget for local UI state, StreamBuilder for real-time updates
- **Mock Data**: Still used in some screens (Home, Market, News, Analysis) - migrating to Firestore gradually
- **Authentication**: Firebase Auth included but no login flow implemented yet - currently uses hardcoded `guest_user` ID
- **Offline First**: Firestore persistence enabled in main.dart with unlimited cache size

## MarketCoach Working Rules (Token Saver)

### Prime directive
Ship working code in small vertical slices. Do not redesign UI unless explicitly asked.

### Output rules (to reduce token usage)
- When implementing features: return ONLY:
  1) a short plan (max 8 bullets)
  2) a git-style diff
  3) a brief explanation (max 5 bullets)
  4) how to run/test
- Do NOT paste entire files unless asked.
- Prefer minimal diffs over full rewrites.

### Architecture rules
- Respect existing structure: lib/app, lib/data, lib/models, lib/providers, lib/screens, lib/services, lib/utils, lib/widgets
- **State Management**: Use Riverpod for new data providers, StatefulWidget for local UI state
- UI layout and styling must not be changed unless requested
- When working with Firestore timestamps, always use safe parsing (see Models section)

### Safety rules
- Never hardcode API keys
- Use env vars or dart-define for secrets
- Add TODO comments instead of guessing

### Done criteria
A feature is done only if:
1) App builds
2) No navigation crashes
3) Feature works end-to-end

## Common Pitfalls & Solutions

### 1. Firestore Timestamp Casting
**Problem**: `type 'Timestamp' is not a subtype of type 'int'`

**Solution**: Firestore returns `Timestamp` objects, not integers. Always use safe parsing in `fromMap`:
```dart
publishedAt: _parseDateTime(map['published_at'])

static DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
```

### 2. StreamBuilder in CustomScrollView
**Problem**: `RenderViewport expected RenderSliver` errors, GlobalKey conflicts

**Solution**: Wrap entire `CustomScrollView` with `StreamBuilder`, not individual slivers. Build slivers list conditionally inside the builder function (see StreamBuilder in CustomScrollView pattern above).

### 3. Field Name Mismatches
**Problem**: Reading wrong Firestore field names (e.g., `duration_minutes` vs `minutes`)

**Solution**: Check the actual Firestore schema before implementing `fromMap`. Use the exact field names from the database. The lesson schema uses `minutes`, not `duration_minutes`.
