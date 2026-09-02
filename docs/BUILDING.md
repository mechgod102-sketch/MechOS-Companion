# Building MechOS Companion

## Application identity

- App name: **MechOS Companion**
- Android application ID: `com.mechos.companion`
- iOS bundle ID: `com.mechos.companion`

## GitHub Actions

Two workflows are included:

- **Android Build** creates an installable APK and an AAB.
- **iOS Build** creates an unsigned iPhone application package for build verification.

Open **Actions** in GitHub and select a workflow to run it manually, or push to `main` to trigger both.

### Android

The `MechOS-Companion.apk` artifact can be downloaded from a successful Android workflow run and sideloaded onto an Android phone.

The generated AAB is not intended for production Play Store submission until release signing is configured with a private Android keystore stored in GitHub Actions secrets.

### iPhone / iOS

Apple requires code signing for installation on a physical iPhone and for TestFlight/App Store distribution. The default GitHub workflow deliberately uses `--no-codesign`, so no Apple private keys or certificates are committed to this repository.

A later signed workflow should use an Apple Developer certificate, provisioning profile, and App Store Connect credentials stored only as encrypted GitHub Actions secrets.

## Local build

Generate the host projects:

```bash
./scripts/bootstrap-platforms.sh
```

Then build Android:

```bash
flutter build apk --release
flutter build appbundle --release
```

On macOS, build iOS:

```bash
flutter build ios --release
```
