# Pawsome — Setup & Release Guide

Pawsome ships on three native front-ends that all share one Firebase project
(`pawsome--signin-ios`) and one image store (`baldbuffalo/Pawsome-assets`):

| Platform | Tech | Location |
|---|---|---|
| iOS / macOS | SwiftUI | `Pawsome/` (this repo) |
| Windows | WinUI 3 / .NET 8 | `Pawsome-Windows/` (this repo) → see its [README](Pawsome-Windows/README.md) |
| Backend rules | Firestore | `firebase/` |

---

## 1. Firestore security rules (do this first — required before publishing)

Both clients write to Firestore **directly**, so the security rules are the only
thing protecting your data. Deploy them:

```bash
cd firebase
firebase login
firebase deploy --only firestore:rules --project pawsome--signin-ios
```

The rules (`firebase/firestore.rules`) enforce:
- users can only edit their own profile,
- only a post's owner can edit/delete it (anyone signed in can like/comment),
- only a comment's author can edit/delete it.

## 2. iOS / macOS image-upload token

`GitHubUploader.swift` reads a GitHub token from `Info.plist` (`GitHubToken =
$(GITHUB_TOKEN)`), which is supplied by a **git-ignored** `Secrets.xcconfig` so
it never lands in source control.

1. Copy the example and add your token:
   ```bash
   cp Pawsome/Secrets.xcconfig.example Pawsome/Secrets.xcconfig
   # edit Pawsome/Secrets.xcconfig → GITHUB_TOKEN = ghp_yourtoken
   ```
2. In Xcode: *Project → Info → Configurations* → set the Debug/Release config
   files to `Secrets.xcconfig` (or `#include` it from your existing xcconfig).
3. Confirm `Pawsome/Secrets.xcconfig` is git-ignored (it is by default — see
   `Pawsome/.gitignore`).

Token scope: fine-grained PAT with **Contents: Read and write** on
`baldbuffalo/Pawsome-assets` (or a classic token with `repo`).

## 3. Windows

See **[Pawsome-Windows/README.md](Pawsome-Windows/README.md)** for prerequisites,
the Google desktop-OAuth client, building, and producing a `.exe` / MSIX.

## 4. Release checklist

- [ ] Firestore rules deployed (step 1).
- [ ] iOS: `Secrets.xcconfig` configured; App Check (App Attest) enabled in Firebase.
- [ ] iOS: bump build/version, archive, upload to App Store Connect.
- [ ] Windows: Google desktop OAuth client id set; build MSIX, update
      `Package.appxmanifest` publisher to your Partner Center identity.
- [ ] AdMob: production ad unit IDs verified.
- [ ] Test sign-in, post, like, comment, delete on each platform against the
      shared Firestore.
