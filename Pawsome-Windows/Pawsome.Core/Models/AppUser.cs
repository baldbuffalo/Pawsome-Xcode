using Pawsome.Core.Firestore;

namespace Pawsome.Core.Models;

/// <summary>A signed-in Pawsome user (the `users/{uid}` document).</summary>
public sealed class AppUser
{
    public required string Uid { get; init; }
    public string Username { get; set; } = "User";
    public string? ProfilePic { get; set; }
    public int UserNumber { get; init; }

    public static AppUser FromFirestore(string uid, IReadOnlyDictionary<string, object?> data) => new()
    {
        Uid = uid,
        Username = data.GetString("username") ?? "User",
        ProfilePic = data.GetString("profilePic"),
        UserNumber = (int)data.GetLong("userNumber"),
    };
}
