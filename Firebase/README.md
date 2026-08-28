# Firebase

Shared Firebase backend definition and platform adapters for Pawsome.

## Shared data contract

- `firestore.data.json` — single source of truth for Firestore collections, document IDs, fields, types, defaults, and allowed values.
- `firestore.indexes.json` — Firestore index configuration.

## Platform configuration and adapters

- `Android/google-services.json` — Android Firebase application configuration.
- `Android/Firestore.kt` — Android-native Firestore adapter using the Firebase Android SDK.
- `Android/FirebaseAuth.kt` — Android-native Firebase Authentication adapter using the Firebase Android SDK.
- `iOS/GoogleService-Info.plist` — Apple Firebase application configuration.
- `iOS/Firestore.swift` — Apple-native Firestore adapter for iOS and macOS using `FirebaseFirestore`.
- `iOS/FirebaseAuth.swift` — Apple-native Firebase Authentication adapter for iOS and macOS using `FirebaseAuth`.
- `Windows/README.md` — notes on the Windows/.NET Firebase SDK limitation.

## Backend

- `functions/` — Firebase Cloud Functions.

`firestore.rules` is intentionally not documented here as a source of truth for the application's schema; production rules are maintained in the Firebase console as requested.
