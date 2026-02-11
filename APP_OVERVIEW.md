# MarketCoach - Complete App Overview

**Version**: 1.0.0
**Last Updated**: February 11, 2026
**Status**: Production Ready ✅

---

## 📱 App Summary

MarketCoach is a Flutter-based financial analysis mobile application providing:
- Real-time stock & cryptocurrency market data
- Educational lessons with progress tracking
- User authentication with Firebase
- Watchlist management
- Technical analysis and charting

**Platforms**: Android, iOS, macOS, Windows
**Package**: `com.finance.coach`

---

## 🏗️ Architecture

### Core Components

#### 1. **Authentication System** ✅
- Firebase Authentication (email/password)
- Anonymous guest mode with account upgrade
- Remember me functionality (SharedPreferences)
- Password reset via email
- User profile management in Firestore

**Key Files:**
- `lib/services/auth_service.dart` - Authentication logic
- `lib/providers/auth_provider.dart` - Riverpod auth providers
- `lib/screens/auth/login_screen.dart` - Login with remember me
- `lib/screens/auth/signup_screen.dart` - Account creation
- `lib/screens/auth/forgot_password_screen.dart` - Password reset
- `lib/screens/auth/account_upgrade_screen.dart` - Guest → permanent account
- `lib/models/user_profile.dart` - User data model

**Collections:**
- `users/{userId}` - User profiles
- `users/{userId}/lesson_progress/{lessonId}` - Learning progress
- `users/{userId}/bookmarks/{lessonId}` - Bookmarked lessons
- `users/{userId}/watchlist/{symbol}` - User watchlist

---

#### 2. **Lesson System** ✅
Complete educational content delivery with progress tracking.

**Features:**
- Multiple lesson screen types (intro, text, diagram, quiz, bullets, takeaways)
- Real-time progress tracking
- Bookmarking
- Search and filtering (by level, status)
- Offline support via Firestore persistence
- Quiz with answer validation

**Key Files:**
- `lib/models/lesson.dart` - Lesson metadata model
- `lib/models/lesson_screen.dart` - Individual screen model
- `lib/models/lesson_progress.dart` - Progress tracking model
- `lib/models/lesson_bookmark.dart` - Bookmark model
- `lib/providers/lesson_provider.dart` - Lesson data provider
- `lib/providers/lesson_progress_provider.dart` - Progress provider
- `lib/providers/bookmarks_provider.dart` - Bookmarks provider
- `lib/screens/learn/learn_screen.dart` - Lesson list screen
- `lib/screens/lesson_detail/lesson_detail_screen.dart` - Lesson player
- `lib/widgets/lesson_screen_widget.dart` - Screen type renderer
- `lib/data/firestore_service.dart` - Firestore operations

**Collections:**
- `lessons/{lessonId}` - Lesson metadata
- `lessons/{lessonId}/screens/{screenId}` - Lesson screens

**Scripts:**
- `scripts/import_lessons.js` - Import lessons to Firestore (Node.js)
- `beginner_lessons_seed.json` - Sample lesson data

---

#### 3. **Market Data System** ✅
Real-time and historical market data for stocks and cryptocurrencies.

**Data Sources:**
- **Stocks**: Alpha Vantage, Finnhub, Yahoo Finance (via Python backend)
- **Crypto Prices**: CoinGecko API (free, reliable)
- **Live Crypto**: Binance WebSocket (real-time BTC, ETH, SOL, etc.)
- **Historical Candles**: Binance REST API + WebSocket

**Key Files:**
- `lib/models/stock_summary.dart` - Stock data model
- `lib/models/quote.dart` - Real-time quote model
- `lib/models/candle.dart` - OHLCV candle model
- `lib/models/indicator.dart` - Technical indicators model
- `lib/models/valuation.dart` - Valuation metrics model
- `lib/services/quote_service.dart` - Quote streaming (Mock + Binance)
- `lib/services/candle_service.dart` - Binance candle service
- `lib/providers/market_data_provider.dart` - Market data providers
- `lib/providers/candle_provider.dart` - Candle data provider
- `lib/data/watchlist_repository.dart` - Watchlist management
- `lib/utils/crypto_helper.dart` - Crypto symbol utilities

**Collections:**
- `market_data/{symbol}` - Current prices and info
- `market_data/{symbol}/candles/{timestamp}` - Historical candles
- `indicators/{symbol}` - Technical indicators
- `valuations/{symbol}` - Valuation analysis

**Current Real Data:**
- **Stocks**: AAPL ($273.68), MSFT ($413.27), GOOGL ($318.58), TSLA ($425.21), NVDA ($188.54), AMZN ($206.96), META ($670.72), BHP ($45.47)
- **Crypto**: BTC ($68,953), ETH ($2,025), SOL ($83.06), ADA ($0.26), XRP ($1.40), XLM ($0.16)

---

#### 4. **Navigation Structure**
Bottom navigation with 6 tabs:

1. **Home** (`lib/screens/home/home_screen.dart`)
   - User watchlist with real-time prices
   - Market overview (stocks vs crypto)
   - Lesson recommendations
   - Uses: BinanceQuoteService, MockQuoteService, WatchlistRepository

2. **Market** (`lib/screens/market/market_screen.dart`)
   - Stock and crypto categories
   - Market indices
   - Top movers
   - Uses: BinanceQuoteService for crypto

3. **Learn** (`lib/screens/learn/learn_screen.dart`)
   - Lesson library with real-time updates
   - Search and filters
   - Progress indicators
   - Uses: StreamBuilder + Firestore

4. **Analysis** (`lib/screens/analysis/analysis_screen.dart`)
   - Market analysis highlights
   - AI-powered insights (placeholder)

5. **News** (`lib/screens/news/news_screen.dart`)
   - Financial news feed
   - Sentiment analysis (placeholder)

6. **Profile** (`lib/screens/profile/profile_screen.dart`)
   - User info and stats
   - Sign in/Sign up for guests
   - Learning plan
   - Settings
   - Sign out

**Detail Screens:**
- `lib/screens/stock_detail/stock_detail_screen.dart` - Stock details
- `lib/screens/lesson_detail/lesson_detail_screen.dart` - Lesson player
- `lib/screens/market/market_category_screen.dart` - Market category view

---

#### 5. **State Management**
Mixed approach using Riverpod and StatefulWidget:

- **Riverpod Providers**: Data fetching, Firebase streams, auth state
- **StatefulWidget**: Local UI state, forms, animations
- **StreamBuilder**: Real-time Firestore updates

**Key Providers:**
- `firebaseProvider` - Firestore instance
- `firebaseAuthProvider` - Firebase Auth instance
- `authStateProvider` - Auth state stream
- `userIdProvider` - Current user ID
- `isGuestProvider` - Guest mode check
- `userProfileProvider` - User profile stream
- `firestoreServiceProvider` - Firestore service
- `lessonProvider` - Lesson data fetcher
- `lessonProgressProvider` - Progress stream
- `bookmarksProvider` - Bookmarks stream
- `marketDataStreamProvider` - Market data stream
- `watchlistProvider` - Watchlist stream
- `authServiceProvider` - Auth service

---

#### 6. **Theming**
- Material Design 3 dark theme
- Seed color: `#12A28C` (teal/green)
- Background: `#0D131A`
- Card color: `#111925`
- Glass card widget for modern UI

**Key Files:**
- `lib/app/market_coach_app.dart` - Theme configuration
- `lib/widgets/glass_card.dart` - Glassmorphic card widget

---

## 🔧 Python Backend

FastAPI backend service for market data aggregation.

**Location**: `python-backend/`

**Features:**
- Multi-source data fetching (Alpha Vantage, Finnhub, yfinance)
- Technical indicator calculation (TA-Lib)
- Firestore integration
- Rate limiting and caching
- RESTful API endpoints

**Key Scripts:**
- `app/main.py` - FastAPI app
- `app/services/data_fetcher.py` - Market data fetcher
- `app/services/indicator_service.py` - Technical indicators
- `app/services/firestore_writer.py` - Firestore writer
- `scripts/populate_all_market_data.py` - Sample data populator

**API Endpoints:**
- `GET /api/market/quote/{symbol}` - Get quote
- `POST /internal/refresh-watchlist` - Refresh all data

**Configuration:**
- `.env` - API keys and settings
- `serviceAccountKey.json` - Firebase credentials

---

## 📦 Dependencies

### Flutter
```yaml
firebase_core: ^4.4.0
firebase_auth: ^6.1.4
cloud_firestore: ^6.1.2
flutter_riverpod: ^2.0.6
shared_preferences: ^2.3.3
http: ^1.2.2
web_socket_channel: ^3.0.1
syncfusion_flutter_charts: ^28.1.33
```

### Python Backend
```
fastapi
uvicorn
yfinance
google-cloud-firestore
ta-lib
requests
```

---

## 🚀 Running the App

### Flutter App
```bash
# Run on emulator/device
flutter run

# Run on specific device
flutter run -d emulator-5554

# Build APK
flutter build apk

# Build for release
flutter run --release
```

### Python Backend
```bash
cd python-backend

# Install dependencies
pip install -r requirements.txt

# Start server
uvicorn app.main:app --reload

# Refresh market data
curl -X POST http://localhost:8000/internal/refresh-watchlist
```

### Update Market Data
```bash
cd python-backend

# Update all stock data (via FastAPI backend)
curl -X POST http://localhost:8000/internal/refresh-watchlist

# Update crypto prices (CoinGecko)
python fetch_crypto_simple.py

# Alternative: Populate sample data
python scripts/populate_all_market_data.py
```

### Import Lessons
```bash
# Import lessons to Firestore
npm run import-lessons

# Or directly
node scripts/import_lessons.js beginner_lessons_seed.json
```

---

## 📁 Project Structure

```
market_coach/
├── lib/
│   ├── app/                          # App shell & theme
│   │   ├── market_coach_app.dart     # Root MaterialApp
│   │   └── root_shell.dart           # Bottom navigation
│   ├── data/                         # Data layer
│   │   ├── firestore_service.dart    # Firestore operations
│   │   ├── mock_data.dart            # Mock data
│   │   └── watchlist_repository.dart # Watchlist management
│   ├── models/                       # Data models
│   │   ├── lesson.dart
│   │   ├── lesson_screen.dart
│   │   ├── lesson_progress.dart
│   │   ├── lesson_bookmark.dart
│   │   ├── stock_summary.dart
│   │   ├── quote.dart
│   │   ├── candle.dart
│   │   ├── indicator.dart
│   │   ├── valuation.dart
│   │   ├── user_profile.dart
│   │   └── ...
│   ├── providers/                    # Riverpod providers
│   │   ├── auth_provider.dart
│   │   ├── firebase_provider.dart
│   │   ├── lesson_provider.dart
│   │   ├── lesson_progress_provider.dart
│   │   ├── bookmarks_provider.dart
│   │   ├── market_data_provider.dart
│   │   └── ...
│   ├── screens/                      # Feature screens
│   │   ├── auth/                     # Authentication
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   ├── forgot_password_screen.dart
│   │   │   └── account_upgrade_screen.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── market/
│   │   │   ├── market_screen.dart
│   │   │   └── market_category_screen.dart
│   │   ├── learn/
│   │   │   └── learn_screen.dart
│   │   ├── lesson_detail/
│   │   │   └── lesson_detail_screen.dart
│   │   ├── stock_detail/
│   │   │   └── stock_detail_screen.dart
│   │   ├── analysis/
│   │   │   └── analysis_screen.dart
│   │   ├── news/
│   │   │   └── news_screen.dart
│   │   └── profile/
│   │       └── profile_screen.dart
│   ├── services/                     # External services
│   │   ├── auth_service.dart
│   │   ├── quote_service.dart
│   │   └── candle_service.dart
│   ├── utils/                        # Utilities
│   │   └── crypto_helper.dart
│   ├── widgets/                      # Reusable widgets
│   │   ├── glass_card.dart
│   │   ├── lesson_screen_widget.dart
│   │   ├── live_line_chart.dart
│   │   └── ...
│   ├── firebase_options.dart         # Firebase config
│   └── main.dart                     # Entry point
├── android/                          # Android config
│   └── app/google-services.json      # Firebase Android config
├── ios/                              # iOS config
│   └── Runner/GoogleService-Info.plist # Firebase iOS config
├── python-backend/                   # Python backend
│   ├── app/                          # FastAPI app
│   ├── scripts/                      # Utility scripts
│   ├── .env                          # Environment config
│   ├── serviceAccountKey.json        # Firebase admin key
│   └── requirements.txt              # Python dependencies
├── scripts/                          # Node.js scripts
│   ├── import_lessons.js             # Lesson importer
│   └── fix_screen_order.js           # Screen order fixer
├── test/                             # Tests
├── CLAUDE.md                         # Development guide
├── APP_OVERVIEW.md                   # This file
├── pubspec.yaml                      # Flutter dependencies
├── package.json                      # Node.js dependencies
└── firestore.rules                   # Firestore security rules
```

---

## 🔐 Firebase Collections

### Authentication & Users
```
users/{userId}
  ├── uid: string
  ├── email: string
  ├── display_name: string
  ├── is_anonymous: boolean
  ├── created_at: Timestamp
  ├── last_login_at: Timestamp
  └── subcollections:
      ├── lesson_progress/{lessonId}
      ├── bookmarks/{lessonId}
      └── watchlist/{symbol}
```

### Lessons
```
lessons/{lessonId}
  ├── title: string
  ├── subtitle: string
  ├── level: string (Beginner/Intermediate/Advanced)
  ├── minutes: int
  ├── body: string
  ├── published_at: Timestamp
  └── subcollections:
      └── screens/{screenId}
          ├── type: string (intro|text|diagram|quiz_single|bullets|takeaways)
          ├── order: int
          ├── title: string
          ├── subtitle: string
          └── content: map (type-specific fields)
```

### Market Data
```
market_data/{symbol}
  ├── ticker: string
  ├── name: string
  ├── price: number
  ├── changePercent: number
  ├── sector: string
  ├── industry: string
  ├── isCrypto: boolean
  ├── updated_at: Timestamp
  └── subcollections:
      └── candles/{timestamp}
          ├── timestamp: Timestamp
          ├── open: number
          ├── high: number
          ├── low: number
          ├── close: number
          └── volume: int

indicators/{symbol}
  ├── rsi: number
  ├── macd: map
  ├── bollinger_bands: map
  └── moving_averages: map

valuations/{symbol}
  ├── pe_ratio: number
  ├── dcf_value: number
  └── ...
```

---

## 🎯 Features Implemented

### ✅ Core Features
- [x] Firebase Authentication (email/password)
- [x] Anonymous guest mode
- [x] Remember me functionality
- [x] Password reset
- [x] Account upgrade (guest → permanent)
- [x] User profile management
- [x] Real-time market data (stocks & crypto)
- [x] Live crypto prices via Binance WebSocket
- [x] Historical candlestick charts
- [x] Watchlist management
- [x] Educational lesson system
- [x] Lesson progress tracking
- [x] Lesson bookmarking
- [x] Search and filters
- [x] Offline support (Firestore persistence)
- [x] Quiz screens with validation
- [x] Bottom navigation
- [x] Dark theme (Material 3)
- [x] Glass card widgets

### 🚧 Placeholder Features (UI only)
- [ ] News feed integration
- [ ] AI coach recommendations
- [ ] Technical indicator calculations
- [ ] Valuation analysis
- [ ] Portfolio tracking
- [ ] Broker integration
- [ ] Price alerts
- [ ] 2FA

---

## 🔑 API Keys & Configuration

### Firebase
- Project ID: `marketcoach-db8f4`
- Configured in: `firebase_options.dart`
- Admin key: `python-backend/serviceAccountKey.json`

### Market Data APIs
- **Alpha Vantage**: Configured in `python-backend/.env`
- **Finnhub**: Configured in `python-backend/.env`
- **CoinGecko**: Free, no API key needed
- **Binance**: Free WebSocket, no API key needed

---

## 📊 Current Data Status

### Real Market Data ✅
- **8 Stocks**: AAPL, MSFT, GOOGL, TSLA, NVDA, AMZN, META, BHP
- **6 Cryptocurrencies**: BTC, ETH, SOL, ADA, XRP, XLM
- **Last Updated**: February 11, 2026
- **Sources**: Alpha Vantage, Finnhub, CoinGecko
- **Live Updates**: Binance WebSocket for crypto

### Lesson Content ✅
- Sample beginner lessons available
- Import via `npm run import-lessons`
- Real-time progress tracking
- Bookmarking enabled

---

## 🧪 Testing

### Run Tests
```bash
# All tests
flutter test

# Specific tests
flutter test test/models/
flutter test test/services/
flutter test test/widgets/
```

### Test Coverage
```bash
flutter test --coverage
```

---

## 🚀 Deployment

### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Backend (Google Cloud Run)
```bash
cd python-backend
gcloud builds submit --tag gcr.io/marketcoach-db8f4/backend
gcloud run deploy --image gcr.io/marketcoach-db8f4/backend
```

---

## 📝 Development Notes

### Authentication Flow
1. App launches → Auto sign-in anonymously if no user
2. User can browse as guest with limited features
3. Guest can sign up or sign in from Profile screen
4. Remember me saves email for next login
5. Account upgrade converts guest → permanent account

### Data Flow
1. **Real-time crypto**: Binance WebSocket → UI (HomeScreen, MarketScreen)
2. **Stock data**: Firestore → StreamProvider → UI
3. **Lessons**: Firestore snapshots() → StreamBuilder → UI
4. **Progress**: Firestore subcollection → StreamProvider → UI

### State Management Pattern
- Use Riverpod for: Data providers, Firebase streams, auth state
- Use StatefulWidget for: Forms, local UI state, animations
- Use StreamBuilder for: Real-time Firestore updates in lists

---

## 🔧 Maintenance

### Update Market Data
Run these scripts regularly (every 5-15 minutes):

```bash
# Crypto prices (fast, free)
cd python-backend
python fetch_crypto_simple.py

# Stock prices (requires API keys)
curl -X POST http://localhost:8000/internal/refresh-watchlist
```

### Update Lessons
```bash
# Edit beginner_lessons_seed.json
# Then import
npm run import-lessons
```

### Clean Build
```bash
flutter clean
flutter pub get
flutter run
```

---

## 📞 Support

For issues or questions:
- Check `CLAUDE.md` for development guidelines
- Review this file for architecture overview
- Check Firebase Console for data issues
- Review Python backend logs for API issues

---

**Last Updated**: February 11, 2026
**Status**: Production Ready ✅
**Next Steps**: Deploy to app stores, set up automated data refresh
