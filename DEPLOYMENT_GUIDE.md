# Ahmediye KIOSK - Web Deployment Guide

## Overview

This guide walks you through deploying the Ahmediye KIOSK Flutter app as a web application hosted on **Firebase Hosting**. Firebase Hosting is free (Spark plan), uses the same project as our Realtime Database, and provides automatic SSL + CDN.

---

## Prerequisites

Make sure you have the following installed:

```bash
# Check Flutter
flutter --version
# Required: Flutter 3.10+ with web support

# Check Firebase CLI
firebase --version
# If not installed: npm install -g firebase-tools

# Check FlutterFire CLI
dart pub global activate flutterfire_cli
```

---

## Step 1: Register a Web App in Firebase

The file `lib/firebase_options.dart` currently has a **placeholder** for the web app ID. You need to generate real web credentials.

```bash
# Login to Firebase (if not already)
firebase login

# Navigate to the project root
cd /path/to/AhmediyeKIOSK

# Run FlutterFire configure and select WEB as a platform
flutterfire configure --project=ahmediye-kiosk
```

When prompted:
- Select **Web** as a platform (use spacebar to select, then enter)
- It will ask for a web app nickname — enter `ahmediye-kiosk-web`
- This will **automatically update** `lib/firebase_options.dart` with real web credentials

**Verify**: Open `lib/firebase_options.dart` and confirm the `web` constant now has a real `appId` (not `REPLACE_WITH_REAL_WEB_APP_ID`).

---

## Step 2: Get Dependencies

```bash
flutter pub get
```

If you see errors about the package name, make sure `pubspec.yaml` has `name: ahmediye_kiosk` and all imports use `package:ahmediye_kiosk/`.

---

## Step 3: Test Locally in Browser

Before deploying, test the app locally:

```bash
flutter run -d chrome
```

Verify:
- [ ] App loads without Firebase errors
- [ ] Home page shows the clock and navigation buttons
- [ ] Student list loads data from Hive/Firebase
- [ ] Entry/exit flow works (create entry, toggle status)
- [ ] Settings page reset works
- [ ] Resize the browser window to check responsive layout on small/large screens

---

## Step 4: Build for Web

```bash
flutter build web --release --web-renderer canvaskit
```

This creates the production build in the `build/web/` directory.

**Note**: We use `canvaskit` renderer for consistent rendering across all browsers. It has a larger initial download (~2MB) but renders identically everywhere. For a kiosk/internal tool, this is the right choice.

---

## Step 5: Initialize Firebase Hosting

```bash
firebase init hosting
```

When prompted:
1. **Select project**: Choose `ahmediye-kiosk`
2. **Public directory**: Enter `build/web`
3. **Configure as single-page app**: Yes
4. **Set up automatic builds with GitHub**: No (for now)
5. **Overwrite build/web/index.html**: **No** (important! don't overwrite)

This creates a `firebase.json` file with hosting configuration.

---

## Step 6: Deploy

```bash
firebase deploy --only hosting
```

After deployment, you will see output like:

```
✓ Deploy complete!

Hosting URL: https://ahmediye-kiosk.web.app
```

Your app is now live at that URL.

---

## Step 7: (Optional) Custom Domain

If you want a custom domain (e.g., `kiosk.ahmediye.org`):

1. Go to [Firebase Console](https://console.firebase.google.com) → your project → Hosting
2. Click "Add custom domain"
3. Follow the DNS verification steps
4. SSL certificate is provisioned automatically (takes ~24 hours)

---

## Redeploying After Changes

Every time you make code changes and want to update the live site:

```bash
# 1. Build
flutter build web --release --web-renderer canvaskit

# 2. Deploy
firebase deploy --only hosting
```

That's it — two commands.

---

## Project Structure (What Changed)

The following changes were made to prepare for web deployment:

### Package Rename
- `pubspec.yaml`: `name: app1` → `name: ahmediye_kiosk`
- All imports updated: `package:app1/` → `package:ahmediye_kiosk/`

### Firebase Web Config
- `lib/firebase_options.dart`: Added web platform detection using `kIsWeb` and a `web` FirebaseOptions constant
- **You must run `flutterfire configure` to fill in the real web app ID**

### Web Metadata
- `web/index.html`: Title → "Ahmediye KIOSK", added viewport meta tag
- `web/manifest.json`: Name → "Ahmediye KIOSK", orientation → "any", theme color updated

### Responsive Design
All 7 pages were updated to work on phone, tablet, and desktop screens:

| Page | What Changed |
|------|-------------|
| `home.dart` | Row→Column on small screens, buttons use `Wrap` |
| `studentList.dart` | Filter sidebar becomes collapsible `ExpansionTile` on small screens |
| `entryList.dart` | Same responsive pattern as studentList |
| `studentInfo.dart` | Added `ConstrainedBox(maxWidth: 700)`, contact buttons use `Wrap` |
| `entryInfo.dart` | Added `ConstrainedBox(maxWidth: 700)` |
| `settings.dart` | `SizedBox(width: 500)` → `ConstrainedBox(maxWidth: 500)` |
| `passwordPage.dart` | Added `ConstrainedBox(maxWidth: 400)` + `Center` |

Breakpoints used:
- **Compact** (phone): width < 600px
- **Medium/Expanded** (tablet/desktop): width >= 600px

Helper: `lib/utils/responsive.dart`

### Code Cleanup
- Removed debug buttons from `studentList.dart` and `studentInfo.dart`
- Removed `lib/utils/test.dart` (unused WebView test)
- Removed commented-out code from `database_service.dart`
- Removed `print()` debug statements
- Moved `STATEIN`/`STATEOUT` constants from `studentInfo.dart` to `database_models.dart` (fixed circular import)

---

## Troubleshooting

### "Firebase app not initialized" error on web
→ You forgot Step 1. Run `flutterfire configure` to generate web credentials.

### Blank white screen on first load
→ Check browser console (F12) for errors. Most likely a Firebase config issue.

### Data not loading
→ Check Firebase Realtime Database rules. For development, ensure read/write is allowed:
```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```
**Warning**: These rules are open. For production, restrict access.

### Build fails with "package not found"
→ Run `flutter pub get` after the package rename. Make sure all files use `package:ahmediye_kiosk/`.

### App works locally but not on Firebase Hosting
→ Make sure you selected "Yes" for single-page app during `firebase init hosting`. Check that `firebase.json` has:
```json
{
  "hosting": {
    "public": "build/web",
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## Quick Reference

| Command | What it does |
|---------|-------------|
| `flutter run -d chrome` | Run locally in Chrome |
| `flutter build web --release --web-renderer canvaskit` | Build for production |
| `firebase deploy --only hosting` | Deploy to Firebase Hosting |
| `firebase hosting:channel:deploy preview` | Deploy to a preview URL (for testing) |
| `flutterfire configure` | Generate/update Firebase platform configs |
