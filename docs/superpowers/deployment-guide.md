# PureCheck — Android & iOS Deployment Guide

This guide provides step-by-step instructions on configuring, signing, and building the **PureCheck** Flutter application for Android and iOS release.

---

## 1. Prerequisites

Before starting, ensure you have:
* **Flutter SDK** installed and configured (`flutter doctor` reports no issues).
* **For Android:** Android Studio, JDK 17+, and Android SDK command-line tools.
* **For iOS:** A macOS machine, Xcode 15+, CocoaPods, and a paid Apple Developer Account.

---

## 2. Supabase Setup (Before Building)

Before deploying the app, you must set up the database tables and authentication rules:

1. Open your **Supabase Dashboard** (`https://supabase.com`).
2. Navigate to the **SQL Editor** tab.
3. Open the file `docs/superpowers/specs/supabase-migration.sql`.
4. Copy the entire SQL contents, paste it into the Supabase SQL editor, and click **Run**.
5. Go to **Authentication** -> **Providers** -> **Email**:
   * Ensure **Enable Email Signup** is toggled **ON**.
   * Turn **Confirm Email** **OFF** if you want users to log in instantly after registration without email validation, or keep it **ON** to require confirmation.

---

## 3. Environment Configuration

The app loads credentials at runtime from `.env` or during compilation via `--dart-define`.

### Local Build using `.env`
Ensure a `.env` file exists at the root of the project (copied from `.env.example`) with your production keys:
```env
SUPABASE_URL=https://your-production.supabase.co
SUPABASE_ANON_KEY=your_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

### Production Build using `--dart-define` (Recommended for CI/CD)
To compile keys directly into the binary instead of bundling a `.env` asset, use:
```bash
flutter build appbundle --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=GEMINI_API_KEY=...
```

---

## 4. Android Build & Signing

### Step 4.1: Generate an Upload Keystore
Run this command in terminal/PowerShell to create a secure keystore file. Replace the password placeholder:

```powershell
keytool -genkey -v -keystore D:\AppPureCheck\upload-keystore.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
*Note: Save this keystore in a safe backup location (not committed to Git!).*

### Step 4.2: Reference the Keystore in the Android Project
1. Create a file named `android/key.properties` (this is ignored by Git in `.gitignore`):
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_keystore_password
   keyAlias=upload
   storeFile=D:\\AppPureCheck\\upload-keystore.jks
   ```

2. Update `android/app/build.gradle.kts` to wire up the signing configuration (already configured in the default scaffold, but verify it matches):
   ```kotlin
   val keystorePropertiesFile = rootProject.file("key.properties")
   val keystoreProperties = Properties()
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

### Step 4.3: Build the Android App Bundle (AAB)
The App Bundle is the required format for publishing to Google Play:
```bash
flutter build appbundle --release
```
* The generated file will be saved at:  
  `[project_root]/build/app/outputs/bundle/release/app-release.aab`

### Step 4.4: Test the Release Version Locally
To test how the app behaves in release mode on a connected device:
```bash
flutter run --release
```

---

## 5. iOS Build & Signing

iOS deployment requires code signing configured in Xcode.

### Step 5.1: Install CocoaPods Dependencies
Before opening Xcode, install dependencies:
```bash
cd ios
pod install
cd ..
```

### Step 5.2: Configure Xcode Signing
1. Open the `ios/Runner.xcworkspace` file in Xcode.
2. Select the **Runner** project in the left sidebar.
3. Select the **Runner** target, then click the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. Select your Apple Developer **Team**.
6. Set a unique **Bundle Identifier** (e.g., `com.purecheck.app`).
7. Select an **App Groups** capability if needed, or leave defaults.

### Step 5.3: Add Camera Usage Description
Since Journey B requires camera access to scan barcodes, check that the camera permission message is defined in `ios/Runner/Info.plist` (already set up in scaffold, but verify):
```xml
<key>NSCameraUsageDescription</key>
<string>แอปพลิเคชันต้องการเข้าถึงกล้องถ่ายภาพของคุณ เพื่อใช้สแกนบาร์โค้ดของผลิตภัณฑ์สกินแคร์</string>
```

### Step 5.4: Build and Archive the IPA
Run the Flutter build command to compile the iOS app:
```bash
flutter build ipa --release
```
* Xcode Organizer will open. You can click **Distribute App** to upload the archive directly to App Store Connect for TestFlight or App Store Release.

---

## 6. Play Store / App Store Submission Checklist

| Check | Description |
|---|---|
| **Privacy Policy** | Required for both stores. Must state that the app accesses the camera (for scanning) and shares ingredients with Gemini AI anonymously. |
| **Gemini Quota Limits** | Production keys should have a paid tier (billing enabled on Google AI Studio) to avoid rate limits when multiple users scan simultaneously. |
| **Lottie Animations** | Production builds should load locally stored Lottie JSONs (in assets) rather than remote URLs to prevent network issues from breaking loading pages. |
