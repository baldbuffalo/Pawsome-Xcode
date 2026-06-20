using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;

namespace Pawsome.Core.Storage;

/// <summary>
/// Uploads/deletes images in the <c>baldbuffalo/Pawsome-assets</c> repo via the
/// GitHub Contents API and returns the raw CDN download URL. This mirrors the
/// Swift <c>GitHubUploader</c> so both clients share the same image store.
///
/// The personal-access token is the only secret in the app. It is supplied by a
/// provider delegate (the WinUI app reads it from Windows Credential Manager or
/// the PAWSOME_GITHUB_TOKEN environment variable) — never hard-coded.
/// </summary>
public sealed class GitHubUploader
{
    private readonly HttpClient _http;
    private readonly Func<string?> _tokenProvider;
    private readonly string _repo;

    public GitHubUploader(HttpClient http, Func<string?> tokenProvider, string? repo = null)
    {
        _http = http;
        _tokenProvider = tokenProvider;
        _repo = repo ?? PawsomeConfig.GitHubAssetsRepo;
    }

    public bool HasToken => !string.IsNullOrWhiteSpace(_tokenProvider());

    /// <summary>Uploads raw bytes to <paramref name="path"/> and returns the download URL.</summary>
    public async Task<string> UploadAsync(byte[] data, string path, string message = "Upload", CancellationToken ct = default)
    {
        var url = $"https://api.github.com/repos/{_repo}/contents/{path}";

        var body = new JsonObject
        {
            ["message"] = message,
            ["content"] = Convert.ToBase64String(data),
        };

        // If the file already exists we must pass its sha to overwrite it.
        var existingSha = await GetFileShaAsync(path, ct).ConfigureAwait(false);
        if (existingSha is not null) body["sha"] = existingSha;

        using var request = NewRequest(HttpMethod.Put, url);
        request.Content = JsonContent.Create(body);

        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        var json = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);

        if (!response.IsSuccessStatusCode)
            throw new GitHubException(ExtractMessage(json) ?? $"HTTP {(int)response.StatusCode}");

        var downloadUrl = JsonNode.Parse(json)?["content"]?["download_url"]?.GetValue<string>();
        return downloadUrl ?? throw new GitHubException("Unexpected response from GitHub API.");
    }

    /// <summary>Uploads pre-encoded JPEG bytes for a post or profile image.</summary>
    public Task<string> UploadImageAsync(byte[] jpeg, string fileName, string folder = "postImages", CancellationToken ct = default)
        => UploadAsync(jpeg, $"{folder}/{fileName}", $"Upload {fileName}", ct);

    public async Task DeleteFileAsync(string path, CancellationToken ct = default)
    {
        var sha = await GetFileShaAsync(path, ct).ConfigureAwait(false);
        if (sha is null) return; // already gone

        var url = $"https://api.github.com/repos/{_repo}/contents/{path}";
        using var request = NewRequest(HttpMethod.Delete, url);
        request.Content = JsonContent.Create(new JsonObject { ["message"] = $"Delete {path}", ["sha"] = sha });

        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode)
            throw new GitHubException("Failed to delete file from GitHub.");
    }

    public async Task<string?> GetFileShaAsync(string path, CancellationToken ct = default)
    {
        var url = $"https://api.github.com/repos/{_repo}/contents/{path}";
        using var request = NewRequest(HttpMethod.Get, url);
        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        if (!response.IsSuccessStatusCode) return null;

        await using var stream = await response.Content.ReadAsStreamAsync(ct).ConfigureAwait(false);
        using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct).ConfigureAwait(false);
        return doc.RootElement.TryGetProperty("sha", out var sha) ? sha.GetString() : null;
    }

    private HttpRequestMessage NewRequest(HttpMethod method, string url)
    {
        var token = _tokenProvider()
            ?? throw new GitHubException("GitHub token missing. Set PAWSOME_GITHUB_TOKEN or store it in Credential Manager.");

        var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("token", token);
        request.Headers.Accept.ParseAdd("application/vnd.github.v3+json");
        request.Headers.UserAgent.ParseAdd("Pawsome-Windows");
        return request;
    }

    private static string? ExtractMessage(string json)
    {
        try { return JsonNode.Parse(json)?["message"]?.GetValue<string>(); }
        catch { return null; }
    }
}

public sealed class GitHubException(string message) : Exception(message);
