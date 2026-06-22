using System.Reflection;
using Pawsome.Core;
using Pawsome.Core.Auth;
using Pawsome.Core.Firestore;
using Pawsome.Core.Storage;

namespace Pawsome.App.Services;

/// <summary>
/// Composition root: builds and owns the single shared instances of every
/// service the app uses. Created once in <see cref="App"/>.
/// </summary>
public sealed class AppServices
{
    public HttpClient Http { get; }
    public SecureStore Secrets { get; }
    public FirebaseAuthService Auth { get; }
    public GoogleAuthFlow GoogleAuth { get; }
    public FirestoreService Firestore { get; }
    public GitHubUploader GitHub { get; }
    public ImageService Images { get; }
    public SessionManager Session { get; }

    public AppServices()
    {
        Http = new HttpClient { Timeout = TimeSpan.FromSeconds(60) };
        Secrets = new SecureStore();

        Auth = new FirebaseAuthService(Http);
        GoogleAuth = new GoogleAuthFlow(Http, OpenInBrowser, ResolveGoogleClientId, ResolveGoogleClientSecret);
        Firestore = new FirestoreService(Http, Auth);
        GitHub = new GitHubUploader(Http, ResolveGitHubToken);
        Images = new ImageService();
        Session = new SessionManager(this);

        // Whenever Firebase silently refreshes the token, persist the new one.
        Auth.SessionChanged += session =>
        {
            if (session is not null) Secrets.Set(SecureStore.RefreshTokenKey, session.RefreshToken);
        };
    }

    private string? ResolveGitHubToken()
        => Secrets.Get(SecureStore.GitHubTokenKey)
           ?? Environment.GetEnvironmentVariable("PAWSOME_GITHUB_TOKEN");

    private static string? Meta(string key)
        => typeof(AppServices).Assembly
            .GetCustomAttributes<AssemblyMetadataAttribute>()
            .FirstOrDefault(a => a.Key == key)?.Value;

    private static string? ResolveGoogleClientId()
        => string.IsNullOrWhiteSpace(Meta("GoogleClientId")) ? PawsomeConfig.GoogleDesktopClientId : Meta("GoogleClientId");

    private static string? ResolveGoogleClientSecret() => Meta("GoogleClientSecret");

    private static void OpenInBrowser(string url)
        => _ = Windows.System.Launcher.LaunchUriAsync(new Uri(url));
}
