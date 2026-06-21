# Pawsome — repo notes for Claude

Pawsome is a lost-and-found cats app shipping on three native front-ends that
share one Firebase project (`pawsome--signin-ios`) and one GitHub image store
(`baldbuffalo/Pawsome-assets`):

- **iOS / macOS** — SwiftUI, in `Pawsome/`
- **Windows** — WinUI 3 / .NET 8, in `Pawsome-Windows/` (engine in `Pawsome.Core`, UI in `Pawsome.App`)
- **Backend rules** — Firestore, in `firebase/`

## CI / GitHub Actions

- Workflow: `.github/workflows/ci.yml` (Core tests on Linux, WinUI build + single-file `Pawsome.exe` artifact on Windows).
- **Always check and use the latest major versions of GitHub Actions.** Before
  committing a workflow change, verify the newest release of each action (e.g.
  `git ls-remote --tags --refs https://github.com/actions/<name>`) and pin to the
  latest major tag. Current at last update: `actions/checkout@v7`,
  `actions/setup-dotnet@v5`, `actions/upload-artifact@v7`.

## Conventions

- Windows assets are generated from the shared app icon via `Pawsome-Windows/tools/generate_assets.py`.
- The only secret is the GitHub upload token; never hard-code it. Firebase client keys are public.
