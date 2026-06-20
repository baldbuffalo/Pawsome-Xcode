using Pawsome.Core.Firestore;

namespace Pawsome.Core.Models;

/// <summary>A cat post — mirrors the `Post` struct in the Swift app.</summary>
public sealed class Post
{
    public required string Id { get; init; }
    public string CatName { get; init; } = "";
    public string Description { get; init; } = "";
    public string Age { get; init; } = "";
    public string ImageUrl { get; init; } = "";
    public string OwnerUid { get; init; } = "";
    public string OwnerUsername { get; init; } = "User";
    public string OwnerProfilePic { get; init; } = "";
    public DateTimeOffset Timestamp { get; init; } = DateTimeOffset.UtcNow;
    public IReadOnlyList<string> Likes { get; init; } = Array.Empty<string>();
    public int CommentCount { get; init; }

    public int LikeCount => Likes.Count;
    public string TimeAgo => Timestamp.TimeAgoDisplay();

    public bool IsLikedBy(string? uid) =>
        !string.IsNullOrEmpty(uid) && Likes.Contains(uid);

    /// <summary>The filename portion of the image URL (used to delete from GitHub).</summary>
    public string? ImageFileName
    {
        get
        {
            if (string.IsNullOrEmpty(ImageUrl)) return null;
            var last = ImageUrl.Split('/').LastOrDefault();
            return string.IsNullOrEmpty(last) ? null : last.Split('?')[0];
        }
    }

    /// <summary>Builds a Post from a parsed Firestore document, or null if invalid.</summary>
    public static Post? FromFirestore(string id, IReadOnlyDictionary<string, object?> data)
    {
        if (data.GetString("catName") is not { } catName) return null;
        if (data.GetString("imageURL") is not { } imageUrl) return null;
        if (data.GetString("ownerUID") is not { } ownerUid) return null;

        return new Post
        {
            Id = id,
            CatName = catName,
            ImageUrl = imageUrl,
            OwnerUid = ownerUid,
            Description = data.GetString("description") ?? "",
            Age = data.GetString("age") ?? "",
            OwnerUsername = data.GetString("ownerUsername") ?? "User",
            OwnerProfilePic = data.GetString("ownerProfilePic") ?? "",
            Timestamp = data.GetTimestamp("timestamp") ?? DateTimeOffset.UtcNow,
            Likes = data.GetStringList("likes"),
            CommentCount = (int)data.GetLong("commentCount"),
        };
    }
}
