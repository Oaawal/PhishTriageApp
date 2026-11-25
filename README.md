# PhishTriage App

Free scam checker for Nigerians, by AWAL Global Consults. Flutter app for
Android and iOS, backed by the PhishTriage Platform API.

## Features

- **Scan a message**: paste any SMS, WhatsApp message, email or link (English or Pidgin). Links are checked with Google Safe Browsing.
- **"Was this right?"** feedback after each scan, with optional anonymous sharing to help train PhishTriage's own model.
- **Check a phone number**: has it been reported by other users?
- **Check a bank account**: see if an account was reported before you pay a vendor or "agent".
- **Report** scam numbers and accounts (moderated before they appear).
- **I've been scammed**: step-by-step recovery plans and a complaint letter for your bank or the police.
- **Share to PhishTriage** (Android): share a message from WhatsApp, SMS or email, or select text in any app and tap "Check with PhishTriage". It opens straight into a scan.
- **Call protection** (Android 10+): a warning notification while a reported number is calling, optional blocking of high-risk callers, and a list of recent unknown callers to report in one tap. Checks run on the phone against an offline list (refreshed every 6 hours). Contacts and the call log are never read.
- **Is this really my bank?**: verified official numbers, SMS sender names and websites, plus a checker.
- **Scam warnings**: scams going round now, and the high-risk numbers list.
- **Right of reply**: owners of a listed number or account can request a review.

The app sends an anonymous install ID (`X-Device-Id`) so the server can rate-limit
and de-duplicate reports. It does not collect names or contacts.

## Configuration

All settings are passed at build time with `--dart-define`:

| Key | Default | Meaning |
|---|---|---|
| `API_BASE_URL` | `https://phishtriageplatform.onrender.com` | PhishTriage Platform API |
| `BOT_WHATSAPP` | empty (card hidden) | WhatsApp bot number, digits only, e.g. `2348000000000` |
| `HELP_WHATSAPP` | AWAL help line | Number for human help |

## Run

```bash
cd PhishTriageApp
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator -> local API
```

## Test

```bash
flutter analyze
flutter test
```

## iPhone

Share-to-scan and call protection are Android-only for now. On iPhone they
need a Share Extension and a Call Directory Extension, which are separate
Xcode targets added on a Mac.

## Release (Android)

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<your-api-host> \
  --dart-define=BOT_WHATSAPP=<bot number>
```

The application ID is `com.awalglobal.phishtriage`. It cannot be changed after
the first Play Store upload. Before release, set up an upload signing key
(see Flutter's "Build and release an Android app" guide) and publish a privacy
policy URL (draft in `PhishTriagePlatform/docs/PRIVACY_POLICY_DRAFT.md`).

Google Play: because the app uses Android's call-screening feature, fill in
the Play Console's app content questions accurately: it screens calls
on-device and does not request call log, contacts or SMS permissions.
