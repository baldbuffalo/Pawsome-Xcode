using Pawsome.Core.Auth;
using Pawsome.Core.Models;

namespace Pawsome.App.Services;

/// <summary>
/// Coordinates sign-in/out and keeps the current <see cref="AppUser"/> in sync
/// with Firestore. Raises <see cref="UserChanged"/> so the UI can react.
/// </summary>
public sealed class SessionManager
{
    private readonly AppServices _services;

    public AppUser? CurrentUser { get; private set; }
    public string? CurrentUid => _services.Auth.Current?.Uid;
    public bool IsSignedIn => _services.Auth.IsSignedIn && CurrentUser is not null;

    public event Action? UserChanged;

    public SessionManager(AppServices services) => _services = services;

    /// <summary>Attempts a silent sign-in using a saved refresh token.</summary>
    public async Task<bool> TryRestoreAsync()
    {
        var refreshToken = _services.Secrets.Get(SecureStore.RefreshTokenKey);
        if (string.IsNullOrEmpty(refreshToken)) return false;

        var session = await _services.Auth.RestoreAsync(refreshToken);
        if (session is null)
        {
            _services.Secrets.Remove(SecureStore.RefreshTokenKey);
            return false;
        }

        await LoadUserAsync(session);
        return true;
    }

    /// <summary>Runs the interactive Google sign-in flow.</summary>
    public async Task SignInWithGoogleAsync(CancellationToken ct = default)
    {
        var googleIdToken = await _services.GoogleAuth.SignInAsync(ct);
        var session = await _services.Auth.SignInWithGoogleAsync(googleIdToken, ct);
        _services.Secrets.Set(SecureStore.RefreshTokenKey, session.RefreshToken);
        await LoadUserAsync(session, ct);
    }

    /// <summary>Runs the interactive X/Twitter sign-in flow.</summary>
    public async Task SignInWithTwitterAsync(CancellationToken ct = default)
    {
        var tokens = await _services.TwitterAuth.SignInAsync(ct);
        var session = await _services.Auth.SignInWithTwitterAsync(tokens.Token, tokens.TokenSecret, ct);
        _services.Secrets.Set(SecureStore.RefreshTokenKey, session.RefreshToken);
        await LoadUserAsync(session, ct);
    }

    public void SignOut()
    {
        _services.Auth.SignOut();
        _services.Secrets.Remove(SecureStore.RefreshTokenKey);
        CurrentUser = null;
        UserChanged?.Invoke();
    }

    public void ApplyUsername(string username)
    {
        if (CurrentUser is null) return;
        CurrentUser.Username = username;
        UserChanged?.Invoke();
    }

    public void ApplyProfilePic(string url)
    {
        if (CurrentUser is null) return;
        CurrentUser.ProfilePic = url;
        UserChanged?.Invoke();
    }

    private async Task LoadUserAsync(FirebaseSession session, CancellationToken ct = default)
    {
        CurrentUser = await _services.Firestore.FetchOrCreateUserAsync(
            session.Uid, session.DisplayName, session.PhotoUrl, ct);
        UserChanged?.Invoke();
    }
}
