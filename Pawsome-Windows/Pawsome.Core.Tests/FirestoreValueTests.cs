using System.Text.Json.Nodes;
using Pawsome.Core;
using Pawsome.Core.Firestore;
using Pawsome.Core.Models;
using Xunit;

namespace Pawsome.Core.Tests;

public class FirestoreValueTests
{
    [Fact]
    public void String_RoundTrips()
    {
        var node = FirestoreValue.FromObject("Mittens");
        Assert.Equal("Mittens", node["stringValue"]!.GetValue<string>());
        Assert.Equal("Mittens", FirestoreValue.ToObject(node));
    }

    [Fact]
    public void Integer_SerializesAsString_AndParsesBack()
    {
        var node = FirestoreValue.FromObject(5L);
        Assert.Equal("5", node["integerValue"]!.GetValue<string>());
        Assert.Equal(5L, FirestoreValue.ToObject(node));
    }

    [Fact]
    public void Bool_RoundTrips()
    {
        var node = FirestoreValue.FromObject(true);
        Assert.True(node["booleanValue"]!.GetValue<bool>());
        Assert.Equal(true, FirestoreValue.ToObject(node));
    }

    [Fact]
    public void Null_RoundTripsAsNullValue()
    {
        var node = FirestoreValue.FromObject(null);
        Assert.True(((JsonObject)node).ContainsKey("nullValue"));
        Assert.Null(FirestoreValue.ToObject(node));
    }

    [Fact]
    public void Timestamp_RoundTrips_AsUtc()
    {
        var when = new DateTimeOffset(2024, 1, 2, 3, 4, 5, TimeSpan.Zero);
        var node = FirestoreValue.FromObject(when);
        var parsed = Assert.IsType<DateTimeOffset>(FirestoreValue.ToObject(node));
        Assert.Equal(when, parsed);
    }

    [Fact]
    public void StringArray_RoundTrips()
    {
        var node = FirestoreValue.FromObject(new List<object?> { "a", "b" });
        var values = node["arrayValue"]!["values"]!.AsArray();
        Assert.Equal(2, values.Count);

        var parsed = Assert.IsType<List<object?>>(FirestoreValue.ToObject(node));
        Assert.Equal(new object?[] { "a", "b" }, parsed);
    }

    [Fact]
    public void ParseFields_ReadsRealisticPostDocument()
    {
        var doc = JsonNode.Parse("""
        {
          "name": "projects/p/databases/(default)/documents/posts/abc123",
          "fields": {
            "catName":         { "stringValue": "Whiskers" },
            "description":     { "stringValue": "Lost near the park" },
            "age":             { "stringValue": "3" },
            "imageURL":        { "stringValue": "https://example.com/cat.jpg" },
            "ownerUID":        { "stringValue": "uid-1" },
            "ownerUsername":   { "stringValue": "Sam" },
            "ownerProfilePic": { "stringValue": "https://example.com/me.jpg" },
            "timestamp":       { "timestampValue": "2024-01-01T00:00:00Z" },
            "likes":           { "arrayValue": { "values": [ { "stringValue": "uid-9" } ] } },
            "commentCount":    { "integerValue": "2" }
          }
        }
        """);

        var fields = FirestoreValue.ParseFields(doc as JsonObject);
        var post = Post.FromFirestore("abc123", fields);

        Assert.NotNull(post);
        Assert.Equal("Whiskers", post!.CatName);
        Assert.Equal("uid-1", post.OwnerUid);
        Assert.Equal(2, post.CommentCount);
        Assert.Single(post.Likes);
        Assert.True(post.IsLikedBy("uid-9"));
        Assert.False(post.IsLikedBy("uid-1"));
        Assert.Equal("cat.jpg", post.ImageFileName);
    }

    [Fact]
    public void ToFields_ProducesValidShapeForCreate()
    {
        var fields = FirestoreValue.ToFields(new Dictionary<string, object?>
        {
            ["catName"] = "Tom",
            ["likes"] = new List<object?>(),
            ["commentCount"] = 0L,
        });

        Assert.Equal("Tom", fields["catName"]!["stringValue"]!.GetValue<string>());
        Assert.Empty(fields["likes"]!["arrayValue"]!["values"]!.AsArray());
        Assert.Equal("0", fields["commentCount"]!["integerValue"]!.GetValue<string>());
    }

    [Fact]
    public void Post_FromFirestore_ReturnsNull_WhenRequiredFieldsMissing()
    {
        var fields = new Dictionary<string, object?> { ["description"] = "no required fields" };
        Assert.Null(Post.FromFirestore("x", fields));
    }
}

public class TimeAgoTests
{
    [Fact]
    public void JustNow_ForRecentTimes()
        => Assert.Equal("just now", DateTimeOffset.UtcNow.TimeAgoDisplay());

    [Fact]
    public void Hours_Ago()
        => Assert.Equal("2h ago", DateTimeOffset.UtcNow.AddHours(-2).TimeAgoDisplay());

    [Fact]
    public void Days_Ago()
        => Assert.Equal("3d ago", DateTimeOffset.UtcNow.AddDays(-3).TimeAgoDisplay());
}
