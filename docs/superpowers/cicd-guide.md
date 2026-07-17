# PureCheck — Cloud CI/CD Build Guide (GitHub Actions)

Since your project is hosted on GitHub, you can compile and build Android (`.apk`/`.aab`) and iOS (`.ipa`) binaries in the cloud without using your local PC's resources by setting up **GitHub Actions**.

---

## 🚀 How It Works
GitHub provides cloud runners (servers) to compile your code.
1. You commit your code to GitHub.
2. GitHub Actions fires a workflow on a runner (Ubuntu for Android, macOS for iOS).
3. The runner builds the application.
4. The compiled binaries are uploaded as downloadable "Artifacts" or published directly to the Play Store/App Store.

---

## 1. Creating the Build Workflow

Create a file in your project at `.github/workflows/build.yml` with the following configuration:

```yaml
name: Flutter Build Cloud CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.1'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Generate Localizations
        run: flutter gen-l10n

      # Setup production environment variables
      - name: Create .env file
        run: |
          echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
          echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
          echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env

      # Optional: Set up signing credentials (if keystore secrets are added)
      # - name: Setup Android Keystore
      #   run: ... (see Keystore signing setup below)

      - name: Build Android APK
        run: flutter build apk --release

      - name: Build Android App Bundle (AAB)
        run: flutter build appbundle --release

      - name: Upload Android Binaries
        uses: actions/upload-artifact@v4
        with:
          name: android-release
          path: |
            build/app/outputs/flutter-apk/app-release.apk
            build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.44.1'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: |
          flutter pub get
          cd ios && pod install

      - name: Generate Localizations
        run: flutter gen-l10n

      - name: Create .env file
        run: |
          echo "SUPABASE_URL=${{ secrets.SUPABASE_URL }}" >> .env
          echo "SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}" >> .env
          echo "GEMINI_API_KEY=${{ secrets.GEMINI_API_KEY }}" >> .env

      # Build unsigned iOS IPA (For Ad-Hoc/App Store testing, you need provisioning certificates)
      - name: Build iOS IPA
        run: flutter build ipa --release --no-codesign

      - name: Upload iOS Binaries
        uses: actions/upload-artifact@v4
        with:
          name: ios-release
          path: build/ios/archive/Runner.xcarchive
```

---

## 2. Setting Up GitHub Secrets

To make the build work without committing your keys to public git history:

1. Open your repository on GitHub.
2. Go to **Settings** -> **Secrets and variables** -> **Actions**.
3. Click **New repository secret** and add the following keys:
   * `SUPABASE_URL`
   * `SUPABASE_ANON_KEY`
   * `GEMINI_API_KEY`

---

## 3. Configuring Keystore Signing on GitHub (Android)

If you want the AAB/APK to be signed automatically in the cloud so it is ready for Google Play:

1. Convert your keystore file `upload-keystore.jks` to a **Base64 string**:
   * On Windows PowerShell:
     ```powershell
     [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Out-File -FilePath keystore_base64.txt
     ```
   * Copy the content of `keystore_base64.txt`.
2. Save this Base64 string in GitHub Secrets as `ANDROID_KEYSTORE_BASE64`.
3. Add these signing credentials as secrets:
   * `ANDROID_KEYSTORE_PASSWORD`
   * `ANDROID_KEY_ALIAS` (e.g., `upload`)
   * `ANDROID_KEY_PASSWORD`
4. Add these steps in your workflow file before `Build Android APK`:
   ```yaml
      - name: Decode Keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE_BASE64 }}" | base64 --decode > android/app/upload-keystore.jks

      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.ANDROID_KEYSTORE_PASSWORD }}" >> android/key.properties
          echo "keyPassword=${{ secrets.ANDROID_KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.ANDROID_KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=upload-keystore.jks" >> android/key.properties
   ```

---

## 4. Alternative Platform: Codemagic

If you prefer a visual dashboard instead of writing YAML files:
1. Sign up for **Codemagic** (`https://codemagic.io`) using your GitHub account.
2. Select your `app-pure-check` repository.
3. Choose **Flutter App** as the project type.
4. Under build settings, toggle Android and iOS targets.
5. Upload your Keystore/Apple Certificates directly to the Web UI dashboard.
6. Click **Start New Build**. Codemagic will build it in the cloud and email you the final `.apk`/`.ipa` downloads.
