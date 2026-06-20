namespace Pawsome.Core.Auth;

/// <summary>An authenticated Firebase session (tokens + identity).</summary>
public sealed class FirebaseSession
{
    public required string Uid { get; init; }
    public required string IdToken { get; set; }
    public required string RefreshToken { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }

    public string? DisplayName { get; init; }
    public string? Email { get; init; }
    public string? PhotoUrl { get; init; }

    /// <summary>True when the access token is expired or within 5 minutes of expiry.</summary>
    public bool NeedsRefresh => DateTimeOffset.UtcNow >= ExpiresAt - TimeSpan.FromMinutes(5);
}
