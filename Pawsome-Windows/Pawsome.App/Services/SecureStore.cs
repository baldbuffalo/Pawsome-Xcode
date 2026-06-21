using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace Pawsome.App.Services;

/// <summary>
/// Stores small secrets (the Firebase refresh token, optional GitHub token) in a
/// per-user DPAPI-encrypted file under %LOCALAPPDATA%. DPAPI ties the data to the
/// current Windows user, so it works for both packaged and unpackaged builds
/// without requiring a package identity.
/// </summary>
public sealed class SecureStore
{
    public const string RefreshTokenKey = "firebase_refresh_token";
    public const string GitHubTokenKey = "github_token";
    public const string GoogleClientIdKey = "google_client_id";

    private readonly string _path;
    private readonly object _gate = new();

    public SecureStore()
    {
        var dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "Pawsome");
        Directory.CreateDirectory(dir);
        _path = Path.Combine(dir, "secrets.dat");
    }

    public string? Get(string key)
    {
        lock (_gate)
            return Load().TryGetValue(key, out var value) ? value : null;
    }

    public void Set(string key, string value)
    {
        lock (_gate)
        {
            var data = Load();
            data[key] = value;
            Save(data);
        }
    }

    public void Remove(string key)
    {
        lock (_gate)
        {
            var data = Load();
            if (data.Remove(key)) Save(data);
        }
    }

    private Dictionary<string, string> Load()
    {
        try
        {
            if (!File.Exists(_path)) return new();
            var protectedBytes = File.ReadAllBytes(_path);
            var json = ProtectedData.Unprotect(protectedBytes, null, DataProtectionScope.CurrentUser);
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json) ?? new();
        }
        catch
        {
            return new(); // corrupt / unreadable — start fresh
        }
    }

    private void Save(Dictionary<string, string> data)
    {
        var json = JsonSerializer.SerializeToUtf8Bytes(data);
        var protectedBytes = ProtectedData.Protect(json, null, DataProtectionScope.CurrentUser);
        File.WriteAllBytes(_path, protectedBytes);
    }
}
