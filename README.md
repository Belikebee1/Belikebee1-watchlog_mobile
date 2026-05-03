# watchlog mobile

**Tap-to-fix server alerts on your phone.**

Native Flutter companion app for [watchlog](https://github.com/Belikebee1/watchlog) – the open-source server health and security monitor. Same dashboard, same actions (Apply security updates, Snooze, Ignore, Run now), but living in your pocket as a real native app.

🌐 watchlog: [watchlog.pl](https://watchlog.pl) · [GitHub](https://github.com/Belikebee1/watchlog)

## What it does

- 🔐 Sign in with your watchlog API URL + Bearer token (stored in iOS Keychain / Android Keystore)
- 📊 Severity banner with live status from your server
- 🔄 Pull-to-refresh + auto-refresh every 60 s
- ✅ Tap "Apply security updates" → server runs `unattended-upgrade -v` → output drawer
- ⏰ Snooze / Ignore / Clear silencing per check
- 🎯 Output drawer with copy-to-clipboard for every command result
- 📱 Push notifications **(coming in v0.2)** – instant alerts when watchlog finds something

## Tech stack

- **Flutter 3.27+ / Dart 3** – single codebase for iOS + Android
- **Riverpod 2** – state management
- **Dio** – HTTP client with auth interceptor
- **flutter_secure_storage** – platform-native secrets storage
- **Material 3** – dark theme matched to the watchlog dashboard

## Develop locally

```bash
git clone https://github.com/Belikebee1/Belikebee1-watchlog_mobile.git
cd Belikebee1-watchlog_mobile

flutter pub get
flutter doctor          # confirm iOS/Android toolchains are happy

# Run on a connected device or emulator
flutter run

# Or pick a specific device:
flutter devices
flutter run -d <device-id>
```

## Build for release

```bash
# Android (APK + AAB for Play Store)
flutter build appbundle --release

# iOS (open in Xcode and Archive)
flutter build ios --release
open ios/Runner.xcworkspace
```

## Configuration

The app stores nothing in plaintext. On first launch:

1. Enter your watchlog API base URL (e.g. `https://api.watchlog.pl`)
2. Paste your Bearer token (run `sudo watchlog api setup` on the server to generate one)
3. The app verifies via `GET /api/v1/status` then writes both into platform secure storage

Logout clears both. To reset: Settings → Sign out, or delete the app.

## App identity

| Platform | Bundle ID / Application ID | Display name |
|---|---|---|
| iOS | `com.belikebee.watchlog` | watchlog |
| Android | `com.belikebee.watchlog` | watchlog |

## Roadmap

- ✅ **v0.1** – sign in, status banner, action buttons, snooze/ignore, output drawer
- 🔔 **v0.2** – push notifications via Firebase Cloud Messaging (background alerts)
- 🌐 **v0.3** – multiple servers, switch between them in one app
- 🎨 **v0.4** – store screenshots, splash polish, App Store + Play Store submission

## License

MIT – see [LICENSE](LICENSE).
