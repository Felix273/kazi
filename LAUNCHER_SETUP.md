# Launcher Icons & Native Splash Setup

## Prerequisites
1. Create the following icon assets in `assets/images/`:
   - `kazi_logo.png` — 1024x1024 px, transparent background, bold white "K" on #1B5E20
   - `kazi_logo_foreground.png` — Adaptive icon foreground (white "K" shape)
   - `kazi_splash_logo.png` — Logo for splash screen (gold on transparent)

## Installation Commands

```bash
# Install dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Generate native splash screen
dart run flutter_native_splash:create
```

## Verification Steps
1. Check Android icons exist:
   ```
   android/app/src/main/res/mipmap-hdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png
   android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png
   ```

2. Check iOS icons exist:
   ```
   ios/Runner/Assets.xcassets/AppIcon.appiconset/
   ```

3. Check splash screen drawables:
   ```
   android/app/src/main/res/drawable/flutter_native_splash.xml
   android/app/src/main/res/drawable-v21/flutter_native_splash.xml
   ```

## Design Specs
- **Icon background**: #1B5E20 (deep green)
- **Icon foreground**: Bold "K" letter in white/gold
- **Adaptive icon**: Round foreground, square background
- **Splash screen**: #1B5E20 background, "KAZI" text in #FFD600 gold
- **Fullscreen**: true (hides status bar during splash)