# Pawsome — repo notes for Claude

Pawsome is a lost-and-found cats app shipping on three native front-ends that
share one Firebase project (`pawsome--signin-ios`) and one GitHub image store
(`baldbuffalo/Pawsome-assets`):

- **iOS / macOS** — SwiftUI, in `Pawsome/`
- **Windows** — WinUI 3 / .NET 8, in `Pawsome-Windows/` (engine in `Pawsome.Core`, UI in `Pawsome.App`)
- **Android** — Kotlin / Jetpack Compose, in `Pawsome-Android/` (REST engine + loopback Google sign-in, mirrors Windows)
- **Backend rules** — Firestore, in `firebase/`

## CI / GitHub Actions

- Workflow: `.github/workflows/ci.yml` (Core tests on Linux, WinUI build + single-file `Pawsome.exe` artifact on Windows).
- **Always check and use the latest version of every GitHub Action, pinned to the
  exact full version (major.minor.patch), not just the major tag.** Before
  committing a workflow change, verify the newest release of each action (e.g.
  `git ls-remote --tags --refs https://github.com/actions/<name>`) and pin to that
  exact tag. Current at last update: `actions/checkout@v7.0.0`,
  `actions/setup-dotnet@v5.3.0`, `actions/upload-artifact@v7.0.1`,
  `actions/setup-java@v5.3.0`, `gradle/actions/setup-gradle@v6.2.0`.

## Conventions

- Windows assets are generated from the shared app icon via `Pawsome-Windows/tools/generate_assets.py`.
- The only secret is the GitHub upload token; never hard-code it. Firebase client keys are public.
