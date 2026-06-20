using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Nodes;
using Pawsome.Core.Auth;
using Pawsome.Core.Models;

namespace Pawsome.Core.Firestore;

/// <summary>
/// A client-side Firestore client built on the REST API and authenticated with
/// the user's Firebase ID token, so the project's Security Rules apply exactly
/// as they do for the iOS/macOS app. It reads/writes the same collections:
/// <c>posts</c>, <c>posts/{id}/comments</c>, <c>users</c> and <c>counter</c>.
/// </summary>
public sealed class FirestoreService
{
    private readonly HttpClient _http;
    private readonly FirebaseAuthService _auth;

    public FirestoreService(HttpClient http, FirebaseAuthService auth)
    {
        _http = http;
        _auth = auth;
    }

    private static string Base => PawsomeConfig.FirestoreBaseUrl;

    private static string FullName(string relativePath) =>
        $"projects/{PawsomeConfig.FirebaseProjectId}/databases/(default)/documents/{relativePath}";

    // ── POSTS ───────────────────────────────────────────────────────────────
    public async Task<List<Post>> GetPostsAsync(int limit = 50, CancellationToken ct = default)
    {
        var query = new JsonObject
        {
            ["structuredQuery"] = new JsonObject
            {
                ["from"] = new JsonArray { new JsonObject { ["collectionId"] = "posts" } },
                ["orderBy"] = new JsonArray
                {
                    new JsonObject
                    {
                        ["field"] = new JsonObject { ["fieldPath"] = "timestamp" },
                        ["direction"] = "DESCENDING",
                    }
                },
                ["limit"] = limit,
            }
        };

        var rows = await RunQueryAsync($"{Base}:runQuery", query, ct).ConfigureAwait(false);
        var posts = new List<Post>();
        foreach (var (id, fields) in rows)
            if (Post.FromFirestore(id, fields) is { } post) posts.Add(post);
        return posts;
    }

    public async Task<string> CreatePostAsync(IReadOnlyDictionary<string, object?> fields, CancellationToken ct = default)
    {
        var name = await CreateDocumentAsync("posts", fields, ct).ConfigureAwait(false);
        return name.Split('/').Last();
    }

    public async Task DeletePostAsync(string postId, CancellationToken ct = default)
        => await DeleteDocumentAsync($"posts/{postId}", ct).ConfigureAwait(false);

    public Task ToggleLikeAsync(string postId, string uid, bool like, CancellationToken ct = default)
    {
        var transform = new JsonObject
        {
            ["fieldPath"] = "likes",
            [like ? "appendMissingElements" : "removeAllFromArray"] = new JsonObject
            {
                ["values"] = new JsonArray { FirestoreValue.FromObject(uid) }
            }
        };
        return CommitTransformAsync($"posts/{postId}", transform, ct);
    }

    // ── COMMENTS ──────────────────────────────────────────────────────────────
    public async Task<List<PostComment>> GetCommentsAsync(string postId, CancellationToken ct = default)
    {
        var query = new JsonObject
        {
            ["structuredQuery"] = new JsonObject
            {
                ["from"] = new JsonArray { new JsonObject { ["collectionId"] = "comments" } },
                ["orderBy"] = new JsonArray
                {
                    new JsonObject
                    {
                        ["field"] = new JsonObject { ["fieldPath"] = "timestamp" },
                        ["direction"] = "ASCENDING",
                    }
                },
            }
        };

        var rows = await RunQueryAsync($"{Base}/posts/{postId}:runQuery", query, ct).ConfigureAwait(false);
        var comments = new List<PostComment>();
        foreach (var (id, fields) in rows)
            if (PostComment.FromFirestore(id, postId, fields) is { } c) comments.Add(c);
        return comments;
    }

    public async Task<string> AddCommentAsync(string postId, IReadOnlyDictionary<string, object?> fields, CancellationToken ct = default)
    {
        var name = await CreateDocumentAsync($"posts/{postId}/comments", fields, ct).ConfigureAwait(false);
        await CommitTransformAsync($"posts/{postId}",
            new JsonObject { ["fieldPath"] = "commentCount", ["increment"] = FirestoreValue.FromObject(1L) },
            ct).ConfigureAwait(false);
        return name.Split('/').Last();
    }

    public async Task DeleteCommentAsync(string postId, string commentId, CancellationToken ct = default)
    {
        await DeleteDocumentAsync($"posts/{postId}/comments/{commentId}", ct).ConfigureAwait(false);
        await CommitTransformAsync($"posts/{postId}",
            new JsonObject { ["fieldPath"] = "commentCount", ["increment"] = FirestoreValue.FromObject(-1L) },
            ct).ConfigureAwait(false);
    }

    public Task UpdateCommentTextAsync(string postId, string commentId, string text, CancellationToken ct = default)
        => PatchDocumentAsync($"posts/{postId}/comments/{commentId}",
            new Dictionary<string, object?> { ["text"] = text }, ct);

    // ── USERS ─────────────────────────────────────────────────────────────────
    public async Task<AppUser?> GetUserAsync(string uid, CancellationToken ct = default)
    {
        var doc = await GetDocumentAsync($"users/{uid}", transaction: null, ct).ConfigureAwait(false);
        return doc is null ? null : AppUser.FromFirestore(uid, doc);
    }

    public Task UpdateUserAsync(string uid, IReadOnlyDictionary<string, object?> fields, CancellationToken ct = default)
        => PatchDocumentAsync($"users/{uid}", fields, ct);

    /// <summary>
    /// Fetches the user doc, or atomically creates it with the next sequential
    /// user number — a faithful port of the Swift transaction.
    /// </summary>
    public async Task<AppUser> FetchOrCreateUserAsync(string uid, string? defaultUsername, string? defaultImage, CancellationToken ct = default)
    {
        var existing = await GetUserAsync(uid, ct).ConfigureAwait(false);
        if (existing is not null) return existing;

        var transaction = await BeginTransactionAsync(ct).ConfigureAwait(false);
        var counter = await GetDocumentAsync("counter/users", transaction, ct).ConfigureAwait(false);
        var last = counter is null ? 0 : (int)counter.GetLong("lastUserNumber");
        var next = last + 1;

        var username = defaultUsername ?? $"User{next}";
        var writes = new JsonArray
        {
            UpdateWrite("counter/users", new Dictionary<string, object?> { ["lastUserNumber"] = (long)next },
                mask: new[] { "lastUserNumber" }),
            UpdateWrite($"users/{uid}", new Dictionary<string, object?>
            {
                ["userNumber"] = (long)next,
                ["username"] = username,
                ["profilePic"] = defaultImage ?? "",
                ["createdAt"] = DateTimeOffset.UtcNow,
            }),
        };

        await CommitAsync(writes, transaction, ct).ConfigureAwait(false);

        return new AppUser { Uid = uid, Username = username, ProfilePic = defaultImage, UserNumber = next };
    }

    // ── REST primitives ─────────────────────────────────────────────────────
    private async Task<List<(string id, Dictionary<string, object?> fields)>> RunQueryAsync(
        string url, JsonNode query, CancellationToken ct)
    {
        var node = await SendJsonAsync(HttpMethod.Post, url, query, ct).ConfigureAwait(false);
        var results = new List<(string, Dictionary<string, object?>)>();

        if (node is JsonArray array)
        {
            foreach (var row in array)
            {
                if (row?["document"] is not JsonObject doc) continue;
                var name = doc["name"]?.GetValue<string>() ?? "";
                var id = name.Split('/').Last();
                results.Add((id, FirestoreValue.ParseFields(doc)));
            }
        }
        return results;
    }

    private async Task<Dictionary<string, object?>?> GetDocumentAsync(string relativePath, string? transaction, CancellationToken ct)
    {
        var url = $"{Base}/{relativePath}";
        if (transaction is not null) url += $"?transaction={Uri.EscapeDataString(transaction)}";

        using var request = new HttpRequestMessage(HttpMethod.Get, url);
        await AuthorizeAsync(request, ct).ConfigureAwait(false);
        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);

        if (response.StatusCode == HttpStatusCode.NotFound) return null;
        await EnsureSuccessAsync(response, ct).ConfigureAwait(false);

        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return FirestoreValue.ParseFields(JsonNode.Parse(text) as JsonObject);
    }

    private async Task<string> CreateDocumentAsync(string collectionPath, IReadOnlyDictionary<string, object?> fields, CancellationToken ct)
    {
        var body = new JsonObject { ["fields"] = FirestoreValue.ToFields(fields) };
        var node = await SendJsonAsync(HttpMethod.Post, $"{Base}/{collectionPath}", body, ct).ConfigureAwait(false);
        return node?["name"]?.GetValue<string>() ?? throw new FirestoreException("Document create returned no name.");
    }

    private async Task PatchDocumentAsync(string relativePath, IReadOnlyDictionary<string, object?> fields, CancellationToken ct)
    {
        var mask = string.Join("&", fields.Keys.Select(k => $"updateMask.fieldPaths={Uri.EscapeDataString(k)}"));
        var url = $"{Base}/{relativePath}?{mask}";
        var body = new JsonObject { ["fields"] = FirestoreValue.ToFields(fields) };
        await SendJsonAsync(HttpMethod.Patch, url, body, ct).ConfigureAwait(false);
    }

    private async Task DeleteDocumentAsync(string relativePath, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Delete, $"{Base}/{relativePath}");
        await AuthorizeAsync(request, ct).ConfigureAwait(false);
        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        await EnsureSuccessAsync(response, ct).ConfigureAwait(false);
    }

    private async Task<string> BeginTransactionAsync(CancellationToken ct)
    {
        var node = await SendJsonAsync(HttpMethod.Post, $"{Base}:beginTransaction", new JsonObject(), ct).ConfigureAwait(false);
        return node?["transaction"]?.GetValue<string>() ?? throw new FirestoreException("Failed to begin transaction.");
    }

    private Task CommitTransformAsync(string relativePath, JsonObject fieldTransform, CancellationToken ct)
    {
        var writes = new JsonArray
        {
            new JsonObject
            {
                ["transform"] = new JsonObject
                {
                    ["document"] = FullName(relativePath),
                    ["fieldTransforms"] = new JsonArray { fieldTransform },
                }
            }
        };
        return CommitAsync(writes, transaction: null, ct);
    }

    private async Task CommitAsync(JsonArray writes, string? transaction, CancellationToken ct)
    {
        var body = new JsonObject { ["writes"] = writes };
        if (transaction is not null) body["transaction"] = transaction;
        await SendJsonAsync(HttpMethod.Post, $"{Base}:commit", body, ct).ConfigureAwait(false);
    }

    private JsonObject UpdateWrite(string relativePath, IReadOnlyDictionary<string, object?> fields, string[]? mask = null)
    {
        var write = new JsonObject
        {
            ["update"] = new JsonObject
            {
                ["name"] = FullName(relativePath),
                ["fields"] = FirestoreValue.ToFields(fields),
            }
        };
        if (mask is not null)
            write["updateMask"] = new JsonObject { ["fieldPaths"] = new JsonArray(mask.Select(m => (JsonNode)m!).ToArray()) };
        return write;
    }

    private async Task<JsonNode?> SendJsonAsync(HttpMethod method, string url, JsonNode body, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(method, url) { Content = JsonContent.Create(body) };
        await AuthorizeAsync(request, ct).ConfigureAwait(false);
        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        await EnsureSuccessAsync(response, ct).ConfigureAwait(false);

        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        return string.IsNullOrWhiteSpace(text) ? null : JsonNode.Parse(text);
    }

    private async Task AuthorizeAsync(HttpRequestMessage request, CancellationToken ct)
    {
        var token = await _auth.GetValidIdTokenAsync(ct).ConfigureAwait(false);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    private static async Task EnsureSuccessAsync(HttpResponseMessage response, CancellationToken ct)
    {
        if (response.IsSuccessStatusCode) return;
        var text = await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
        string message;
        try { message = JsonNode.Parse(text)?["error"]?["message"]?.GetValue<string>() ?? text; }
        catch { message = text; }
        throw new FirestoreException($"Firestore {(int)response.StatusCode}: {message}");
    }
}

public sealed class FirestoreException(string message) : Exception(message);
