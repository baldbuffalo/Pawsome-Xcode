# Pawsome Admin Console

This is the platform-independent Pawsome administration console. It is a static web app, so it can be opened from iOS, Android, Windows, macOS, Linux, or any modern browser.

## What it manages

- Dashboard counts for posts and users
- Search, create, edit, and delete Pawsome posts
- Search and edit user profiles
- Grant or remove administrator access through Firebase Auth custom claims
- App-wide settings in `config/app`: maintenance mode, ads enabled, and announcement text

All writes go through the admin-only callable Cloud Functions in `Firebase/functions/src/index.ts`. The Firebase project is `pawsome-90cb3`.

## Hosting

The console is static and does not require `firebase.json` or Firebase Hosting. The repository can serve `/admin/` through GitHub Pages. The native apps use:

`https://baldbuffalo.github.io/Pawsome-Xcode/admin/`

Enable GitHub Pages for the repository using GitHub Actions, and add that Pages hostname to Firebase Authentication's authorized domains. Google sign-in must also be enabled in Firebase Authentication.

## First administrator

The first administrator must be assigned from a trusted environment that can set Firebase Auth custom claims. After the claim is set, sign out and back in so the ID token contains `admin: true`. The console then lets administrators manage subsequent administrator accounts.
