using Pawsome.Core.Firestore;

namespace Pawsome.Core.Models;

/// <summary>A comment on a post — mirrors `PostComment` in the Swift app.</summary>
public sealed class PostComment
{
    public required string Id { get; init; }
    public required string PostId { get; init; }
    public string Text { get; init; } = "";
    public string OwnerUid { get; init; } = "";
    public string OwnerUsername { get; init; } = "User";
    public string OwnerProfilePic { get; init; } = "";
    public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;

    public string TimeAgo => Timestamp.TimeAgoDisplay();

    public bool IsOwnedBy(string? uid) =>
        !string.IsNullOrEmpty(uid) && OwnerUid == uid;

    public static PostComment? FromFirestore(string id, string postId, IReadOnlyDictionary<string, object?> data)
    {
        if (data.GetString("text") is not { } text) return null;
        if (data.GetString("ownerUID") is not { } ownerUid) return null;

        return new PostComment
        {
            Id = id,
            PostId = postId,
            Text = text,
            OwnerUid = ownerUid,
            OwnerUsername = data.GetString("ownerUsername") ?? "User",
            OwnerProfilePic = data.GetString("ownerProfilePic") ?? "",
            Timestamp = data.GetTimestamp("timestamp") ?? DateTimeOffset.UtcNow,
        };
    }
}
