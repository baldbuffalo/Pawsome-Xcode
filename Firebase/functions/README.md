# Pawsome Cloud Functions

This folder contains the server-side part of Pawsome.

## What this fixes

The mobile apps should contain the **code/schema**, while Firestore contains the **current values**. You should not need to edit Swift/Kotlin code every time a cat, profile, announcement, or app setting changes.

The deployed functions provide three admin-only operations:

- `adminSetDocument` — create/update a Firestore document from an admin tool.
- `adminDeleteDocument` — delete a Firestore document from an admin tool.
- `adminSetAppConfig` — update `config/app`, which existing app versions can listen to for settings such as `adsEnabled` and `maintenanceMode`.

All three require a Firebase Authentication custom claim named `admin` to be `true`.

## Deploy

From the repository root:

```bash
npm install -g firebase-tools
cd Firebase/functions
npm install
npm run build
cd ../..
firebase login
firebase deploy --only functions
```

The repository is configured for Firebase project `pawsome--signin-ios` and Node.js 22.

## Admin authentication

Do **not** put an admin secret in the iOS or Android app.

Set the `admin` custom claim on your own Firebase Auth user using a trusted server/admin environment, then sign out and back in on the app so the refreshed ID token contains the claim.

Example server-side code:

```js
await getAuth().setCustomUserClaims("YOUR_FIREBASE_UID", { admin: true });
```

## Calling the admin writer

Once an authenticated admin client/admin panel is built, call the callable function with:

```json
{
  "path": "posts/POST_ID",
  "fields": {
    "CatName": "Milo",
    "status": "FOUND",
    "location": "Dubai"
  },
  "merge": true
}
```

That changes Firestore directly. Existing app versions that listen to that document/query can receive the new values without an App Store or Play Store update.

## Important

Cloud Functions code is server-side and uses the Firebase Admin SDK. Client Firestore access still needs proper production Security Rules. Do not use `allow read, write: if true` in production.
