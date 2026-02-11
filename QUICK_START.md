# MarketCoach - Quick Start Guide

**Last Updated**: February 11, 2026

---

## 🚀 Run the App

### Prerequisites
- Flutter SDK installed
- Android emulator or physical device
- Node.js (for lesson imports)
- Python 3.11+ (for backend, optional)

### Start the App
```bash
# From project root
flutter run

# On specific device
flutter run -d emulator-5554

# Release mode
flutter run --release
```

The app will:
1. Auto-connect to Firebase
2. Sign you in anonymously as a guest
3. Load real market data from Firestore
4. Show live crypto prices via Binance WebSocket

---

## 📊 Update Market Data

### Option 1: Crypto Only (Fast)
```bash
cd python-backend
python fetch_crypto_simple.py
```
Updates: BTC, ETH, SOL, ADA, XRP, XLM (takes ~5 seconds)

### Option 2: All Data via Backend
```bash
# Start backend
cd python-backend
uvicorn app.main:app --reload

# Refresh data (in another terminal)
curl -X POST http://localhost:8000/internal/refresh-watchlist
```
Updates: All stocks + crypto via Alpha Vantage/Finnhub APIs

---

## 📚 Import Lessons

```bash
# Install dependencies (first time only)
npm install

# Import lessons
npm run import-lessons

# Or import specific file
node scripts/import_lessons.js path/to/lesson.json
```

**Lesson files**: Use `beginner_lessons_seed.json` as template

---

## 🔐 Authentication

### Test Login Flow
1. Open app → Profile tab
2. Tap "Sign Up" → Create account
3. Sign out → Tap "Sign In"
4. Check "Remember Me" → Sign in
5. Close app → Reopen → Email pre-filled ✅

### Test Password Reset
1. Tap "Forgot password?"
2. Enter email → Receive reset email
3. Follow link to reset password

---

## 🧪 Test Market Data

1. **Home Screen**:
   - Watchlist shows real prices
   - Stocks overview card
   - Crypto overview card

2. **Market Screen**:
   - Tap "Stocks" or "Crypto"
   - See real-time prices
   - Live updates for crypto (via WebSocket)

3. **Stock Detail**:
   - Tap any stock
   - View price, chart, fundamentals

---

## 📱 Key Features to Test

### ✅ Working Features
- [x] Sign up / Sign in / Sign out
- [x] Remember me checkbox
- [x] Password reset
- [x] Guest mode
- [x] Real stock prices
- [x] Real crypto prices (live updates)
- [x] Watchlist
- [x] Lesson player
- [x] Progress tracking
- [x] Bookmarking
- [x] Search & filters
- [x] Offline mode

### 🚧 Placeholder (UI only)
- [ ] News feed
- [ ] AI coach
- [ ] Technical indicators
- [ ] Valuation analysis

---

## 🐛 Troubleshooting

### App won't run
```bash
flutter clean
flutter pub get
flutter run
```

### No market data showing
```bash
cd python-backend
python scripts/populate_all_market_data.py
```

### Lessons not loading
```bash
npm run import-lessons
```

### Firebase errors
- Check `firebase_options.dart` exists
- Verify `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
- Check Firestore security rules

---

## 📝 Important Files

### Configuration
- `CLAUDE.md` - Full development guide
- `APP_OVERVIEW.md` - Complete architecture & overview
- `pubspec.yaml` - Flutter dependencies
- `firebase_options.dart` - Firebase configuration
- `python-backend/.env` - Backend API keys

### Main Screens (Production)
- `lib/screens/auth/login_screen.dart`
- `lib/screens/auth/signup_screen.dart`
- `lib/screens/home/home_screen.dart`
- `lib/screens/market/market_screen.dart`
- `lib/screens/learn/learn_screen.dart`
- `lib/screens/lesson_detail/lesson_detail_screen.dart`
- `lib/screens/profile/profile_screen.dart`

### Services
- `lib/services/auth_service.dart` - Authentication
- `lib/services/quote_service.dart` - Live quotes
- `lib/services/candle_service.dart` - Candle data
- `lib/data/firestore_service.dart` - Firestore ops

---

## 🎯 Next Steps

1. **Test everything** - Run through all features
2. **Add more lessons** - Edit `beginner_lessons_seed.json`
3. **Customize watchlist** - Add your favorite stocks
4. **Deploy backend** - Set up automated data refresh
5. **Build for release** - `flutter build apk --release`

---

## 📞 Need Help?

- Check `CLAUDE.md` for detailed dev guidelines
- Review `APP_OVERVIEW.md` for architecture
- Check Firebase Console for data issues
- Review backend logs for API errors

---

**Status**: Production Ready ✅
**Version**: 1.0.0
