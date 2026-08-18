namespace Pawsome.Core;

/// <summary>
/// Central configuration for the Pawsome Windows client.
/// New Firebase / Google Cloud credentials will be added later.
/// </summary>
public static class PawsomeConfig
{
    // Firebase project credentials intentionally cleared during backend reset.
    public const string FirebaseProjectId = "";
    public const string FirebaseApiKey = "";
    public const string FirebaseAuthDomain = "";

    // Google OAuth client ID is supplied through the environment at runtime.
    public static string? GoogleDesktopClientId =>
        Environment.GetEnvironmentVariable("PAWSOME_GOOGLE_CLIENT_ID");

    public const string GitHubAssetsRepo = "baldbuffalo/Pawsome-assets";

    public static string FirestoreBaseUrl =>
        $"https://firestore.googleapis.com/v1/projects/{FirebaseProjectId}/databases/(default)/documents";

    public static string IdentityToolkitBaseUrl =>
        "https://identitytoolkit.googleapis.com/v1/accounts";

    public static string SecureTokenUrl =>
        $"https://securetoken.googleapis.com/v1/token?key={FirebaseApiKey}";
}
