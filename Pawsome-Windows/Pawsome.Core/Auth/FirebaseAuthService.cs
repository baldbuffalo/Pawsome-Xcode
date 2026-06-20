using System.Net.Http.Json;
using System.Text.Json.Nodes;

namespace Pawsome.Core.Auth;

/// <summary>
/// Talks to Firebase's Identity Toolkit + Secure Token REST APIs to sign the
/// user in (via a Google OAuth id_token) and to keep the Firebase ID token
/// fresh. The resulting <see cref="FirebaseSession"/> carries the same UID the
/// iOS/macOS app uses, so a user's posts and profile are identical everywhere.
/// </summary>
public sealed class FirebaseAuthService
{
    private readonly HttpClient _http;

    public FirebaseSession? Current { get; private set; }
    public bool IsSignedIn => Current is not null;

    public event Action<FirebaseSession?>? SessionChanged;

    public FirebaseAuthService(HttpClient http) => _http = http;

    /// <summary>Exchanges a Google OAuth id_token for a Firebase session.</summary>
    public async Task<FirebaseSession> SignInWithGoogleAsync(string googleIdToken, CancellationToken ct = default)
    {
        var url = $"{PawsomeConfig.IdentityToolkitBaseUrl}:signInWithIdp?key={PawsomeConfig.FirebaseApiKey}";
        var payload = new JsonObject
        {
            ["postBody"] = $"id_token={googleIdToken}&providerId=google.com",
            ["requestUri"] = "http://localhost",
            ["returnSecureToken"] = true,
            ["returnIdpCredential"] = true,
        };

        var json = await PostJsonAsync(url, payload, ct).ConfigureAwait(false);

        var session = new FirebaseSession
        {
            Uid = json["localId"]!.GetValue<string>(),
            IdToken = json["idToken"]!.GetValue<string>(),
            RefreshToken = json["refreshToken"]!.GetValue<string>(),
            ExpiresAt = ExpiryFromSeconds(json["expiresIn"]?.GetValue<string>()),
            DisplayName = json["displayName"]?.GetValue<string>(),
            Email = json["email"]?.GetValue<string>(),
            PhotoUrl = json["photoUrl"]?.GetValue<string>(),
        };

        SetSession(session);
        return session;
    }

    /// <summary>Restores a session from a saved refresh token (silent sign-in).</summary>
    public async Task<FirebaseSession?> RestoreAsync(string refreshToken, CancellationToken ct = default)
    {
        try
        {
            var refreshed = await RefreshTokenAsync(refreshToken, ct).ConfigureAwait(false);
            SetSession(refreshed);
            return refreshed;
        }
        catch
        {
            return null; // token revoked / expired — caller falls back to interactive sign-in
        }
    }

    /// <summary>Returns a guaranteed-valid Firebase ID token, refreshing if needed.</summary>
    public async Task<string> GetValidIdTokenAsync(CancellationToken ct = default)
    {
        var current = Current ?? throw new InvalidOperationException("Not signed in.");
        if (!current.NeedsRefresh) return current.IdToken;

        var refreshed = await RefreshTokenAsync(current.RefreshToken, ct).ConfigureAwait(false);
        current.IdToken = refreshed.IdToken;
        current.RefreshToken = refreshed.RefreshToken;
        current.ExpiresAt = refreshed.ExpiresAt;
        SessionChanged?.Invoke(current);
        return current.IdToken;
    }

    public void SignOut()
    {
        Current = null;
        SessionChanged?.Invoke(null);
    }

    private async Task<FirebaseSession> RefreshTokenAsync(string refreshToken, CancellationToken ct)
    {
        using var form = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "refresh_token",
            ["refresh_token"] = refreshToken,
        });

        using var response = await _http.PostAsync(PawsomeConfig.SecureTokenUrl, form, ct).ConfigureAwait(false);
        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode) throw new AuthException(ExtractError(text));

        var json = JsonNode.Parse(text)!;
        return new FirebaseSession
        {
            Uid = json["user_id"]!.GetValue<string>(),
            IdToken = json["id_token"]!.GetValue<string>(),
            RefreshToken = json["refresh_token"]!.GetValue<string>(),
            ExpiresAt = ExpiryFromSeconds(json["expires_in"]?.GetValue<string>()),
            DisplayName = Current?.DisplayName,
            Email = Current?.Email,
            PhotoUrl = Current?.PhotoUrl,
        };
    }

    private async Task<JsonNode> PostJsonAsync(string url, JsonNode payload, CancellationToken ct)
    {
        using var response = await _http.PostAsync(url, JsonContent.Create(payload), ct).ConfigureAwait(false);
        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode) throw new AuthException(ExtractError(text));
        return JsonNode.Parse(text) ?? throw new AuthException("Empty response from Firebase Auth.");
    }

    private void SetSession(FirebaseSession session)
    {
        Current = session;
        SessionChanged?.Invoke(session);
    }

    private static DateTimeOffset ExpiryFromSeconds(string? seconds)
        => DateTimeOffset.UtcNow.AddSeconds(int.TryParse(seconds, out var s) ? s : 3600);

    private static string ExtractError(string json)
    {
        try { return JsonNode.Parse(json)?["error"]?["message"]?.GetValue<string>() ?? "Sign-in failed."; }
        catch { return "Sign-in failed."; }
    }
}

public sealed class AuthException(string message) : Exception(message);
