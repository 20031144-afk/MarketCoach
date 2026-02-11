# macOS Setup Instructions

This guide helps you run MarketCoach on macOS.

## Prerequisites

1. **Flutter SDK** installed and configured
   ```bash
   flutter doctor
   ```

2. **Xcode** (latest version recommended)
   - Install from Mac App Store
   - Install command line tools: `xcode-select --install`

## Firebase Setup for macOS

The app requires Firebase configuration for macOS:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Add a macOS app (if not already added)
4. Download `GoogleService-Info.plist`
5. Place it in: `macos/Runner/GoogleService-Info.plist`

**Note**: The iOS `GoogleService-Info.plist` won't work for macOS - you need a separate macOS configuration.

## Running on macOS

```bash
# Clean build
flutter clean
flutter pub get

# Run on macOS
flutter run -d macos

# Build for release
flutter build macos --release
```

## Network Permissions

The macOS entitlements have been configured with:
- `com.apple.security.network.client` - For Firebase and API calls
- `com.apple.security.network.server` - For local servers
- `com.apple.security.cs.allow-jit` - For Flutter JIT compilation

## Troubleshooting

### "App Sandbox" issues
If you see sandbox errors, verify the entitlements in:
- `macos/Runner/DebugProfile.entitlements`
- `macos/Runner/Release.entitlements`

### Firebase initialization fails
- Ensure `GoogleService-Info.plist` is in `macos/Runner/`
- Check that the bundle ID matches Firebase configuration
- Current bundle ID: `com.finance.coach`

### Build fails
```bash
# Clear Flutter build cache
flutter clean

# Clear macOS build
rm -rf macos/build/

# Rebuild
flutter pub get
flutter run -d macos
```

## Development

The app uses:
- **Firebase**: Authentication, Firestore (requires internet)
- **HTTP APIs**: Market data, news feeds
- **WebSockets**: Real-time price updates
- **Offline Mode**: Firestore persistence enabled for lesson caching

All network features require the network client entitlement to function properly.
