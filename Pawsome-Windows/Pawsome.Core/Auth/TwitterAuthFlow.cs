using System.Net;
using System.Security.Cryptography;
using System.Text;

namespace Pawsome.Core.Auth;

/// <summary>
/// X / Twitter OAuth 1.0a sign-in (3-legged) over a loopback callback, opened in
/// the system browser. Returns the access token + secret that Firebase's
/// twitter.com provider expects.
/// </summary>
public sealed class TwitterAuthFlow
{
    private const string RequestTokenUrl = "https://api.twitter.com/oauth/request_token";
    private const string AuthorizeUrl = "https://api.twitter.com/oauth/authorize";
    private const string AccessTokenUrl = "https://api.twitter.com/oauth/access_token";

    private readonly HttpClient _http;
    private readonly Action<string> _openBrowser;
    private readonly Func<string?> _consumerKey;
    private readonly Func<string?> _consumerSecret;

    public TwitterAuthFlow(HttpClient http, Action<string> openBrowser, Func<string?> consumerKey, Func<string?> consumerSecret)
    {
        _http = http;
        _openBrowser = openBrowser;
        _consumerKey = consumerKey;
        _consumerSecret = consumerSecret;
    }

    public sealed record TwitterTokens(string Token, string TokenSecret);

    public async Task<TwitterTokens> SignInAsync(CancellationToken ct = default)
    {
        var key = _consumerKey();
        var secret = _consumerSecret();
        if (string.IsNullOrWhiteSpace(key) || string.IsNullOrWhiteSpace(secret))
            throw new AuthException("No X/Twitter API key/secret configured in this build.");

        using var listener = new HttpListener();
        var callback = "http://127.0.0.1:8723/"; // must exactly match the X app's approved callback
        listener.Prefixes.Add(callback);
        listener.Start();

        // 1) Request token
        var reqParams = new Dictionary<string, string> { ["oauth_callback"] = callback };
        var reqBody = await PostAsync(RequestTokenUrl, key!, secret!, null, reqParams, ct).ConfigureAwait(false);
        var reqValues = ParseForm(reqBody);
        var requestToken = reqValues.GetValueOrDefault("oauth_token")
            ?? throw new AuthException("Twitter request_token failed: " + reqBody);
        var requestSecret = reqValues.GetValueOrDefault("oauth_token_secret") ?? "";

        // 2) Authorize in browser
        _openBrowser($"{AuthorizeUrl}?oauth_token={Uri.EscapeDataString(requestToken)}");
        var context = await listener.GetContextAsync().WaitAsync(ct).ConfigureAwait(false);
        var query = context.Request.QueryString;
        await WriteBrowserResponseAsync(context.Response).ConfigureAwait(false);

        var verifier = query["oauth_verifier"]
            ?? throw new AuthException("X/Twitter sign-in was cancelled.");

        // 3) Access token
        var accParams = new Dictionary<string, string> { ["oauth_verifier"] = verifier };
        var accBody = await PostAsync(AccessTokenUrl, key!, secret!, new TwitterTokens(requestToken, requestSecret), accParams, ct).ConfigureAwait(false);
        var accValues = ParseForm(accBody);
        var token = accValues.GetValueOrDefault("oauth_token");
        var tokenSecret = accValues.GetValueOrDefault("oauth_token_secret");
        if (token is null || tokenSecret is null)
            throw new AuthException("Twitter access_token failed: " + accBody);

        return new TwitterTokens(token, tokenSecret);
    }

    private async Task<string> PostAsync(string url, string consumerKey, string consumerSecret,
        TwitterTokens? token, Dictionary<string, string> extra, CancellationToken ct)
    {
        var oauth = new Dictionary<string, string>
        {
            ["oauth_consumer_key"] = consumerKey,
            ["oauth_nonce"] = Guid.NewGuid().ToString("N"),
            ["oauth_signature_method"] = "HMAC-SHA1",
            ["oauth_timestamp"] = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(),
            ["oauth_version"] = "1.0",
        };
        if (token is not null) oauth["oauth_token"] = token.Token;
        foreach (var (k, v) in extra) oauth[k] = v;

        var signature = Sign("POST", url, oauth, consumerSecret, token?.TokenSecret);
        oauth["oauth_signature"] = signature;

        var header = "OAuth " + string.Join(", ", oauth
            .Where(p => p.Key.StartsWith("oauth_"))
            .OrderBy(p => p.Key)
            .Select(p => $"{Enc(p.Key)}=\"{Enc(p.Value)}\""));

        using var request = new HttpRequestMessage(HttpMethod.Post, url);
        request.Headers.TryAddWithoutValidation("Authorization", header);
        using var response = await _http.SendAsync(request, ct).ConfigureAwait(false);
        return await response.Content.ReadAsStringAsync(ct).ConfigureAwait(false);
    }

    private static string Sign(string method, string url, Dictionary<string, string> allParams, string consumerSecret, string? tokenSecret)
    {
        var paramString = string.Join("&", allParams
            .Select(p => new KeyValuePair<string, string>(Enc(p.Key), Enc(p.Value)))
            .OrderBy(p => p.Key, StringComparer.Ordinal)
            .Select(p => $"{p.Key}={p.Value}"));
        var baseString = $"{method}&{Enc(url)}&{Enc(paramString)}";
        var signingKey = $"{Enc(consumerSecret)}&{Enc(tokenSecret ?? "")}";
        using var hmac = new HMACSHA1(Encoding.ASCII.GetBytes(signingKey));
        return Convert.ToBase64String(hmac.ComputeHash(Encoding.ASCII.GetBytes(baseString)));
    }

    private static string Enc(string s) => Uri.EscapeDataString(s);

    private static Dictionary<string, string> ParseForm(string body) =>
        body.Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(p => p.Split('=', 2))
            .Where(p => p.Length == 2)
            .ToDictionary(p => p[0], p => Uri.UnescapeDataString(p[1]));

    private static async Task WriteBrowserResponseAsync(HttpListenerResponse response)
    {
        var html = Encoding.UTF8.GetBytes(
            "<html><body style='font-family:sans-serif;text-align:center;margin-top:64px'>" +
            "<h2>🐾 Signed in!</h2><p>You can return to Pawsome.</p></body></html>");
        response.ContentType = "text/html";
        response.ContentLength64 = html.Length;
        await response.OutputStream.WriteAsync(html).ConfigureAwait(false);
        response.OutputStream.Close();
    }

    private static int GetFreePort()
    {
        var l = new System.Net.Sockets.TcpListener(IPAddress.Loopback, 0);
        l.Start();
        var port = ((IPEndPoint)l.LocalEndpoint).Port;
        l.Stop();
        return port;
    }
}
