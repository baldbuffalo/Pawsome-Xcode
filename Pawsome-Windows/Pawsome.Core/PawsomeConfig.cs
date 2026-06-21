namespace Pawsome.Core;

/// <summary>
/// Central configuration for the Pawsome Windows client.
///
/// The Firebase values below are PUBLIC client identifiers (the same ones that
/// already ship inside GoogleService-Info.plist in this repository). They are
/// safe to embed — Firebase access is gated by Firestore Security Rules, not by
/// hiding these keys.
///
/// The GitHub upload token is the ONLY secret. It is never hard-coded here; it
/// is read at runtime from the PAWSOME_GITHUB_TOKEN environment variable or from
/// Windows Credential Manager (see <see cref="Storage.GitHubUploader"/>).
/// </summary>
public static class PawsomeConfig
{
    // ── Firebase project (shared with the iOS / macOS app) ──────────────────
    public const string FirebaseProjectId = "pawsome--signin-ios";
    public const string FirebaseApiKey    = "AIzaSyAOZYH2szj77wjOfMq9G1pLRkVUtdlCSSc";
    public const string FirebaseAuthDomain = "pawsome--signin-ios.firebaseapp.com";

    // ── Google OAuth (Desktop / Installed-app client) ───────────────────────
    // Create one in Google Cloud Console → Credentials → "OAuth client ID" →
    // Application type "Desktop app", then paste the client id here (or set the
    // PAWSOME_GOOGLE_CLIENT_ID env var). A Desktop client uses PKCE and needs no
    // client secret. The iOS client id from the plist will NOT work for desktop.
    // No fallback on purpose: the iOS client id does NOT work for desktop
    // loopback sign-in — Google returns "Error 400: invalid_request". A Google
    // OAuth client of type "Desktop app" is required. Provide it via the login
    // screen's Advanced field (stored securely) or this environment variable.
    public static string? GoogleDesktopClientId =>
        Environment.GetEnvironmentVariable("PAWSOME_GOOGLE_CLIENT_ID");

    // ── GitHub image CDN (shared with the iOS / macOS app) ──────────────────
    public const string GitHubAssetsRepo = "baldbuffalo/Pawsome-assets";

    // ── Firestore / Identity Toolkit REST endpoints ─────────────────────────
    public static string FirestoreBaseUrl =>
        $"https://firestore.googleapis.com/v1/projects/{FirebaseProjectId}/databases/(default)/documents";

    public static string IdentityToolkitBaseUrl =>
        "https://identitytoolkit.googleapis.com/v1/accounts";

    public static string SecureTokenUrl =>
        $"https://securetoken.googleapis.com/v1/token?key={FirebaseApiKey}";
}
