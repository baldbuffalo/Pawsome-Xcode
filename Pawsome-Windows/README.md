# Pawsome for Windows 🐾

A **native Windows** client for Pawsome, built with **WinUI 3 / Windows App SDK
and .NET 8** — a real `.exe`, no cross-platform UI layer. It talks to the **same
Firebase project** (`pawsome--signin-ios`) and the **same GitHub image store**
(`baldbuffalo/Pawsome-assets`) as the iOS/macOS app, so posts, comments, likes
and profiles are shared across every platform in real time.

## What's inside

| Project | Target | Purpose |
|---|---|---|
| `Pawsome.Core` | `net8.0` | Models + Firebase REST client + Google sign-in + GitHub uploader. **No UI** — unit-tested on CI. |
| `Pawsome.App` | `net8.0-windows` (WinUI 3) | The native Windows UI: feed, create post, comments, likes, profile, full-screen viewer. |
| `Pawsome.Core.Tests` | `net8.0` | xUnit tests for the Firestore value converter, models and helpers. |

Architecture: **MVVM** (CommunityToolkit.Mvvm) with a thin composition root
(`Services/AppServices.cs`). Firestore is accessed over its REST API using the
signed-in user's Firebase ID token, so your **Firestore Security Rules apply
identically** to those of the mobile app.

## Features

- 🔐 **Google sign-in** via the native desktop OAuth loopback + PKCE flow → same Firebase UID as mobile.
- 🏠 **Feed** of cat posts with near-real-time updates (10s polling + manual refresh) and in-place merge (no flicker).
- ➕ **Create posts** — pick an image, it's resized/encoded to JPEG and uploaded to the GitHub asset repo.
- ❤️ **Likes** with optimistic UI, 💬 **comments** with inline edit/delete.
- 👤 **Profile** — edit username, change avatar, manage the upload token, sign out.
- 🖼️ Full-screen image viewer with zoom/pan.
- 🎨 Fluent design, Mica backdrop, brand purple→blue gradients, branded MSIX tiles & icon.

## Download a ready-to-run build (no PC build needed)

Every push to `main` builds the app and attaches it in the **Actions tab**:

1. Open the repo's **Actions** tab → click the latest green **CI** run.
2. Scroll to **Artifacts** → download **`Pawsome-Windows-x64`**.
3. Unzip and run **`Pawsome.exe`** on Windows 10/11 (the runtime is bundled — no install needed).

> Build artifacts are kept for 90 days each. (A version-tagged GitHub Release
> with a permanent download link can be added on request.)

## Prerequisites

- Windows 10 (1809 / build 17763) or Windows 11
- **Visual Studio 2022** with:
  - *.NET Desktop Development* workload
  - *Windows App SDK C# Templates* (Individual component) / WinUI
- .NET 8 SDK

## Configure (one-time)

1. **Google OAuth desktop client** (required for sign-in)
   - Google Cloud Console → *APIs & Services → Credentials → Create credentials →
     OAuth client ID → Application type: **Desktop app***.
   - Copy the client id and either paste it into `PawsomeConfig.GoogleDesktopClientId`
     or set the environment variable `PAWSOME_GOOGLE_CLIENT_ID`.
   - Make sure **Google** is enabled in Firebase Console → *Authentication → Sign-in method*.

2. **Image upload token** (required to post photos / change avatar)
   - Create a GitHub token (fine-grained: *Contents → Read and write* on
     `baldbuffalo/Pawsome-assets`, or a classic token with `repo`).
   - Provide it either:
     - in-app: **Profile → Image upload token → paste → Save** (encrypted on the PC via DPAPI), or
     - via the `PAWSOME_GITHUB_TOKEN` environment variable.

> The Firebase keys in `PawsomeConfig.cs` are public client identifiers (the same
> ones already in `GoogleService-Info.plist`) and are safe to ship. The GitHub
> token is the only secret and is never committed.

## Build & run

```powershell
# From Pawsome-Windows/ on Windows:
dotnet restore
dotnet build Pawsome.sln -c Debug
```

Or open `Pawsome.sln` in Visual Studio, set **Pawsome.App** as the startup
project, pick `x64`, and press **F5**.

Run the engine tests anywhere (they need no Windows):

```bash
dotnet test Pawsome.Core.Tests/Pawsome.Core.Tests.csproj
```

## Publish

**A standalone `.exe` (unpackaged, self-contained — just double-click, no install):**

```powershell
dotnet publish Pawsome.App/Pawsome.App.csproj -c Release -r win-x64 `
  -p:WindowsPackageType=None -p:WindowsAppSDKSelfContained=true --self-contained
# Output: Pawsome.App/bin/Release/net8.0-windows10.0.19041.0/win-x64/publish/Pawsome.App.exe
```

**An MSIX package (Microsoft Store / sideload):**

- Visual Studio → right-click **Pawsome.App → Package and Publish → Create App Packages…**
- For the Store, choose your signing identity and update `Identity Publisher` in
  `Package.appxmanifest` to match your certificate / Partner Center publisher.

## Deploy the shared Firestore rules

```bash
cd ../firebase
firebase deploy --only firestore:rules --project pawsome--signin-ios
```

## Notes & roadmap

- **Real-time:** the feed/comments use lightweight polling (the Firestore REST
  API has no snapshot listeners). It's smooth and battery-friendly; a future
  upgrade could use the Firestore gRPC `Listen` stream.
- **Apple sign-in** isn't wired on Windows yet (the mobile app supports it). The
  auth layer is structured to add it via Apple's web OAuth flow.
- Images are stored in the GitHub asset repo to match the mobile app. If you move
  to Firebase Storage later, only `GitHubUploader` needs to change.
