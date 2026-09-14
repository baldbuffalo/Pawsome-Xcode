using Pawsome.Core.Firestore;

namespace Pawsome.Core.Models;

/// <summary>A comment using the Android user identity fields.</summary>
public sealed class PostComment
{
    public required string Id { get; init; }
    public required string PostId { get; init; }
    public string Text { get; init; } = "";
    public int UserID { get; init; }
    public string Username { get; init; } = "User";
    public string ProfilePic { get; init; } = "";
    public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;

    public string OwnerUid => UserID.ToString();
    public string OwnerUsername => Username;
    public string OwnerProfilePic => ProfilePic;
    public string TimeAgo => Timestamp.TimeAgoDisplay();

    public bool IsOwnedByUserID(int? userID) => userID is not null && UserID == userID.Value;

    public static PostComment? FromFirestore(string id, string postId, IReadOnlyDictionary<string, object?> data)
    {
        if (data.GetString("text") is not { } text) return null;
        return new PostComment
        {
            Id = id,
            PostId = postId,
            Text = text,
            UserID = (int)data.GetLong("UserID"),
            Username = data.GetString("Username") ?? "User",
            ProfilePic = data.GetString("ProfilePic") ?? "",
            Timestamp = data.GetTimestamp("timestamp") ?? DateTimeOffset.UtcNow,
        };
    }
}
