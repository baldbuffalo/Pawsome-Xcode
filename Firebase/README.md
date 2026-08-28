# Firebase

Shared Firebase backend definitions and platform configuration for Pawsome.

## Shared data definition

- `firestore.data.json` is the single source of truth for the Firestore document model used by the Pawsome clients.
- It currently describes `users`, `counter/users`, `posts`, and `posts/{postId}/comments` using the fields already present in the Android and Windows code.
- Dynamic document IDs are represented as `<firebaseAuthUid>` for users and `<firestoreGeneratedId>` for posts/comments.

## Firebase CLI configuration

- `firebase.json` contains the Firebase CLI Firestore configuration and points at `firestore.indexes.json`.
- `firestore.rules` is intentionally kept separate from this shared data definition and is not treated as the application schema.

## Platform SDKs

The shared definition does not replace platform SDK code. Each client uses the Firebase SDK appropriate to its platform while following the same `firestore.data.json` contract:

- `Android/` — Android Firebase configuration and the Android Firebase SDK
- `iOS/` — Apple Firebase configuration and the Firebase Apple SDK
- Windows — Windows Firebase integration following the same Firestore contract
- macOS — Apple Firebase configuration and the Firebase Apple SDK

## Current database contract

### `users/{uid}`

- `username`: string, default `User`
- `profilePic`: string, default empty
- `userNumber`: integer
- `createdAt`: server timestamp

### `counter/users`

- `lastUserNumber`: integer

### `posts/{postId}`

- `catName`: string
- `description`: string
- `age`: string
- `imageURL`: string
- `ownerUID`: string
- `ownerUsername`: string
- `ownerProfilePic`: string
- `timestamp`: server timestamp
- `likes`: array of strings
- `commentCount`: integer
- `status`: `LOST`, `FOUND`, or `REUNITED`
- `location`: string

### `posts/{postId}/comments/{commentId}`

- `text`: string
- `ownerUID`: string
- `ownerUsername`: string
- `ownerProfilePic`: string
- `timestamp`: server timestamp

The existing platform implementations remain in their native source trees until they are migrated to consume this shared contract; no `Http.kt` changes are part of this setup.
