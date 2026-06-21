using System.Net;
using System.Net.Http.Json;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json.Nodes;

namespace Pawsome.Core.Auth;

/// <summary>
/// Implements Google's OAuth 2.0 "loopback IP" flow for native desktop apps
/// (RFC 8252) with PKCE — the recommended, secret-free way to sign in with
/// Google from a Windows .exe. It opens the system browser, captures the
/// redirect on a local <see cref="HttpListener"/>, and exchanges the code for a
/// Google id_token that Firebase Auth then accepts.
/// </summary>
public sealed class GoogleAuthFlow
{
    private const string AuthEndpoint = "https://accounts.google.com/o/oauth2/v2/auth";
    private const string TokenEndpoint = "https://oauth2.googleapis.com/token";

    private readonly HttpClient _http;
    private readonly Action<string> _openBrowser;
    private readonly Func<string?> _clientIdProvider;

    public GoogleAuthFlow(HttpClient http, Action<string> openBrowser, Func<string?> clientIdProvider)
    {
        _http = http;
        _openBrowser = openBrowser;
        _clientIdProvider = clientIdProvider;
    }

    /// <summary>Runs the full flow and returns the Google id_token.</summary>
    public async Task<string> SignInAsync(CancellationToken ct = default)
    {
        var clientId = _clientIdProvider();
        if (string.IsNullOrWhiteSpace(clientId))
            throw new AuthException(
                "No Google \"Desktop app\" OAuth client ID is configured. On the sign-in screen, open \"Advanced\" and paste one (create it in Google Cloud Console → Credentials).");

        var (verifier, challenge) = CreatePkcePair();
        var state = RandomUrlSafe(24);

        var port = GetFreeLoopbackPort();
        var redirectUri = $"http://127.0.0.1:{port}/";

        using var listener = new HttpListener();
        listener.Prefixes.Add(redirectUri);
        listener.Start();

        var authUrl =
            $"{AuthEndpoint}?client_id={Uri.EscapeDataString(clientId!)}" +
            $"&redirect_uri={Uri.EscapeDataString(redirectUri)}" +
            "&response_type=code" +
            "&scope=" + Uri.EscapeDataString("openid email profile") +
            $"&code_challenge={challenge}&code_challenge_method=S256" +
            $"&state={state}&access_type=offline&prompt=select_account";

        _openBrowser(authUrl);

        // Wait for Google to redirect back to our loopback listener.
        var context = await listener.GetContextAsync().WaitAsync(ct).ConfigureAwait(false);
        var query = context.Request.QueryString;

        await WriteBrowserResponseAsync(context.Response).ConfigureAwait(false);

        if (query["error"] is { } error)
            throw new AuthException($"Google sign-in was cancelled or failed: {error}");
        if (query["state"] != state)
            throw new AuthException("OAuth state mismatch — possible interception.");
        if (query["code"] is not { } code)
            throw new AuthException("No authorization code returned by Google.");

        return await ExchangeCodeForIdTokenAsync(code, verifier, redirectUri, clientId!, ct).ConfigureAwait(false);
    }

    private async Task<string> ExchangeCodeForIdTokenAsync(string code, string verifier, string redirectUri, string clientId, CancellationToken ct)
    {
        using var form = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["client_id"] = clientId,
            ["code"] = code,
            ["code_verifier"] = verifier,
            ["grant_type"] = "authorization_code",
            ["redirect_uri"] = redirectUri,
        });

        using var response = await _http.PostAsync(TokenEndpoint, form, ct).ConfigureAwait(false);
        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
            throw new AuthException($"Token exchange failed: {text}");

        var idToken = JsonNode.Parse(text)?["id_token"]?.GetValue<string>();
        return idToken ?? throw new AuthException("Google did not return an id_token.");
    }

    private static async Task WriteBrowserResponseAsync(HttpListenerResponse response)
    {
        const string html =
            "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Pawsome</title></head>" +
            "<body style='font-family:Segoe UI,sans-serif;background:linear-gradient(135deg,#7c3aed,#2563eb);" +
            "color:white;display:flex;height:100vh;align-items:center;justify-content:center;margin:0'>" +
            "<div style='text-align:center'><h1>🐾 You're signed in!</h1>" +
            "<p>You can close this tab and return to Pawsome.</p></div></body></html>";

        var buffer = Encoding.UTF8.GetBytes(html);
        response.ContentType = "text/html";
        response.ContentLength64 = buffer.Length;
        await response.OutputStream.WriteAsync(buffer).ConfigureAwait(false);
        response.OutputStream.Close();
    }

    // ── PKCE helpers ────────────────────────────────────────────────────────
    private static (string verifier, string challenge) CreatePkcePair()
    {
        var verifier = RandomUrlSafe(64);
        var hash = SHA256.HashData(Encoding.ASCII.GetBytes(verifier));
        var challenge = Base64Url(hash);
        return (verifier, challenge);
    }

    private static string RandomUrlSafe(int byteCount)
    {
        var bytes = RandomNumberGenerator.GetBytes(byteCount);
        return Base64Url(bytes);
    }

    private static string Base64Url(byte[] bytes) =>
        Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');

    private static int GetFreeLoopbackPort()
    {
        var listener = new TcpListener(IPAddress.Loopback, 0);
        listener.Start();
        var port = ((IPEndPoint)listener.LocalEndpoint).Port;
        listener.Stop();
        return port;
    }
}
